#!/usr/bin/env bash
# Appends a clarified requirement description to a Jira issue's `description`
# field (ADF), on top of whatever is already there — never overwrites the
# original content, and never rebuilds the original ADF nodes from flattened
# plain text (that would destroy any existing formatting). Only the newly
# appended block is freshly constructed as ADF.
#
# The appended block is wrapped with two greppable sentinels that
# read-jira-ticket.sh enforces on every subsequent read:
#   [SPECKIT:CLARIFIED]      permanent — this ticket has been through
#                             requirement-self-check at least once.
#   [SPECKIT:PENDING-REVIEW] temporary — a human (PM) must review the
#                             appended content, delete the original
#                             description above it, and delete this line.
#
# Usage:
#   write-jira-ticket.sh <TICKET-KEY> <clarified-text-file> [--incomplete] [--dry-run]
#
#   <clarified-text-file>  Plain text, paragraphs separated by a blank line.
#                           Produced by the requirement-self-check command
#                           from its Q&A session.
#   --incomplete            The user stopped the Q&A early; insert a short
#                           disclaimer paragraph before the pending-review
#                           marker.
#   --dry-run               Print the ADF payload that would be PUT and
#                           exit 0 without calling the Jira write API (the
#                           read call to fetch the current description still
#                           happens, so valid credentials are still needed).
#
# Any validation failure (bad ticket key, missing file, missing env vars,
# missing tools) is an immediate non-zero exit with a message on stderr —
# no partial work, no retry, no guessing.
#
# Requires ATLASSIAN_EMAIL and ATLASSIAN_API_TOKEN in the environment.
# ATLASSIAN_BASE_URL may override the default DE Jira Cloud instance.
set -euo pipefail

TICKET_PATTERN='^SHDRP-[0-9]+$'
BASE_URL="${ATLASSIAN_BASE_URL:-https://disneyexperiences.atlassian.net}"

err() {
  echo "[write-jira-ticket] $1" >&2
}

TICKET_KEY="${1:-}"
TEXT_FILE="${2:-}"

if [[ -z "$TICKET_KEY" || -z "$TEXT_FILE" ]]; then
  err "Usage: write-jira-ticket.sh <TICKET-KEY> <clarified-text-file> [--incomplete] [--dry-run]"
  exit 1
fi

shift 2

INCOMPLETE=false
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --incomplete) INCOMPLETE=true ;;
    --dry-run) DRY_RUN=true ;;
    *)
      err "Unknown argument '$arg'."
      exit 1
      ;;
  esac
done

if [[ ! "$TICKET_KEY" =~ $TICKET_PATTERN ]]; then
  err "Invalid ticket key '$TICKET_KEY' — expected format SHDRP-<digits> (e.g. SHDRP-437322)."
  exit 1
fi

if [[ ! -f "$TEXT_FILE" || ! -r "$TEXT_FILE" ]]; then
  err "Clarified text file '$TEXT_FILE' does not exist or is not readable."
  exit 1
fi

if [[ -z "${ATLASSIAN_EMAIL:-}" || -z "${ATLASSIAN_API_TOKEN:-}" ]]; then
  err "Missing ATLASSIAN_EMAIL and/or ATLASSIAN_API_TOKEN environment variables."
  exit 1
fi

for tool in curl jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    err "Required tool '$tool' is not installed."
    exit 1
  fi
done

API_URL="${BASE_URL%/}/rest/api/3/issue/${TICKET_KEY}"

# --- Fetch the current description as full ADF (not flattened) ---
get_response="$(curl -sS -w '\n%{http_code}' \
  -u "${ATLASSIAN_EMAIL}:${ATLASSIAN_API_TOKEN}" \
  -H "Accept: application/json" \
  "${API_URL}?fields=description")" || {
  err "Network error while contacting Jira at $BASE_URL."
  exit 1
}

get_status="${get_response##*$'\n'}"
get_body="${get_response%$'\n'*}"

case "$get_status" in
  200) ;;
  401 | 403)
    err "Authentication failed (HTTP $get_status). Check ATLASSIAN_EMAIL / ATLASSIAN_API_TOKEN."
    exit 1
    ;;
  404)
    err "Ticket '$TICKET_KEY' was not found in $BASE_URL."
    exit 1
    ;;
  *)
    err "Jira API returned HTTP $get_status for '$TICKET_KEY' while fetching current description."
    exit 1
    ;;
esac

current_adf="$(printf '%s' "$get_body" | jq -c '.fields.description // {type:"doc",version:1,content:[]}')" || {
  err "Failed to parse Jira API response as JSON."
  exit 1
}

# --- Build the ADF nodes to append ---
today="$(date +%Y-%m-%d)"

# Plain-text paragraphs (blank-line separated; a single "\n" inside a
# paragraph becomes a hardBreak) -> ADF paragraph nodes.
read -r -d '' TEXT_TO_PARAGRAPHS_FILTER <<'JQ_EOF' || true
sub("\n+$"; "")
| split("\n\n")
| map(select(length > 0))
| map(
    split("\n") as $lines
    | {
        type: "paragraph",
        content: (
          [ range(0; ($lines | length)) as $i
            | ( if $i > 0 then [{type:"hardBreak"}] else [] end )
              + [ { type: "text", text: $lines[$i] } ]
          ] | add
        )
      }
  )
JQ_EOF

body_paragraphs="$(jq -R -s "$TEXT_TO_PARAGRAPHS_FILTER" "$TEXT_FILE")" || {
  err "Failed to convert '$TEXT_FILE' into ADF paragraphs."
  exit 1
}

if $INCOMPLETE; then
  disclaimer_json='[{"type":"paragraph","content":[{"type":"text","text":"⚠️ 注意：用户在完全回答所有细节前主动结束了澄清流程，以下内容可能仍有遗漏，请 PM 重点核实。"}]}]'
else
  disclaimer_json='[]'
fi

updated_adf="$(jq -c \
  --argjson body "$body_paragraphs" \
  --argjson disclaimer "$disclaimer_json" \
  --arg clarified_text "✅ [SPECKIT:CLARIFIED] 需求质量自检已完成（${today}）" \
  --arg pending_text "⚠️ [SPECKIT:PENDING-REVIEW] 待 PM Review：请核对以上内容准确无误后，删除本工单最上方的原始需求描述，并删除这一行标记（其余内容请保留）。" \
  '.content += (
      [{type:"rule"}]
      + [{type:"paragraph", content:[{type:"text", text:$clarified_text}]}]
      + $body
      + $disclaimer
      + [{type:"paragraph", content:[{type:"text", text:$pending_text}]}]
    )' <<<"$current_adf"
)" || {
  err "Failed to merge new content into existing ADF document."
  exit 1
}

payload="$(jq -nc --argjson description "$updated_adf" '{fields: {description: $description}}')"

if $DRY_RUN; then
  printf '%s\n' "$payload"
  exit 0
fi

# --- Write back ---
put_response="$(curl -sS -w '\n%{http_code}' -X PUT \
  -u "${ATLASSIAN_EMAIL}:${ATLASSIAN_API_TOKEN}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  --data "$payload" \
  "$API_URL")" || {
  err "Network error while contacting Jira at $BASE_URL."
  exit 1
}

put_status="${put_response##*$'\n'}"
put_body="${put_response%$'\n'*}"

case "$put_status" in
  204) ;;
  401 | 403)
    err "Authentication failed (HTTP $put_status). Check ATLASSIAN_EMAIL / ATLASSIAN_API_TOKEN."
    exit 1
    ;;
  404)
    err "Ticket '$TICKET_KEY' was not found in $BASE_URL."
    exit 1
    ;;
  *)
    err "Jira API returned HTTP $put_status for '$TICKET_KEY' while writing updated description. Response: $put_body"
    exit 1
    ;;
esac

err "Ticket '$TICKET_KEY' updated: appended clarified requirement (pending PM review)."
exit 0
