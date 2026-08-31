#!/usr/bin/env bash
# Fetches a Jira issue's `description` field and prints it as plain text
# (paragraph breaks preserved, no Markdown formatting, tables/lists not
# specially rendered — just flattened block by block).
#
# Requirement-quality gate (unconditional once the JIRA gate itself is
# enabled for the event): a ticket whose description still carries a
# [SPECKIT:PENDING-REVIEW] marker, or that has never carried a
# [SPECKIT:CLARIFIED] marker at all, is hard-blocked — regardless of mode.
# Both markers are written by
# speckit.de-speckit-extension.requirement-self-check /
# write-jira-ticket.sh. See that command for how a ticket earns
# [SPECKIT:CLARIFIED] and how [SPECKIT:PENDING-REVIEW] gets cleared (a human
# PM reviews the appended clarification, deletes the original description,
# and deletes that marker line).
#
# Usage:
#   read-jira-ticket.sh <TICKET-KEY> [--skip-clarified-check]
#   read-jira-ticket.sh <event_name> [<TICKET-KEY>]  # hook mode
#
# --skip-clarified-check is an internal-only escape hatch used exclusively
# by requirement-self-check's own step 1: a ticket that has never been
# through self-check will never carry [SPECKIT:CLARIFIED], so without this
# flag self-check could never read a ticket it is meant to clarify. It
# skips only the "must already carry [SPECKIT:CLARIFIED]" branch; the
# "must not still carry [SPECKIT:PENDING-REVIEW]" branch still applies, so
# self-check still can't be re-run on a ticket that's already mid-review.
#
# Manual mode: $1 is a ticket key (e.g. SHDRP-437322). Validates, fetches,
# prints. Any failure is a non-zero exit with a message on stderr.
#
# Hook mode: $1 is a before_*/after_* event name; $2 is an optional ticket
# key the caller already found by searching the gated command's
# natural-language input. Reads jira_gate.<event_name>.enabled (falling
# back to jira_gate.default) from
# .specify/extensions/de-speckit-extension/de-speckit-extension-config.yml,
# mirroring the official git extension's auto_commit.<event>.enabled
# pattern (plain grep/sed line scanning, no yq/jq dependency for YAML):
#   enabled=false            -> gate inactive for this event: exit 0, no
#                                output, no processing at all (even if a
#                                ticket key was passed).
#   enabled=true, no ticket  -> exit 1 (block): a ticket reference is
#                                required here and none was found.
#   enabled=true, has ticket -> validate + fetch as in manual mode; any
#                                failure is still a non-zero exit.
#
# Requires ATLASSIAN_EMAIL and ATLASSIAN_API_TOKEN in the environment.
# ATLASSIAN_BASE_URL may override the default DE Jira Cloud instance.
set -euo pipefail

TICKET_PATTERN='^SHDRP-[0-9]+$'
EVENT_PATTERN='^(before|after)_[a-z]+$'
BASE_URL="${ATLASSIAN_BASE_URL:-https://disneyexperiences.atlassian.net}"

err() {
  echo "[read-jira-ticket] $1" >&2
}

SKIP_CLARIFIED_CHECK=false
positional=()
for arg in "$@"; do
  if [[ "$arg" == "--skip-clarified-check" ]]; then
    SKIP_CLARIFIED_CHECK=true
  else
    positional+=("$arg")
  fi
done

ARG1="${positional[0]:-}"
ARG2="${positional[1]:-}"
TICKET_KEY=""

if [[ -z "$ARG1" ]]; then
  err "Usage: read-jira-ticket.sh <TICKET-KEY> | read-jira-ticket.sh <event_name> [<TICKET-KEY>]"
  exit 1
fi

if [[ "$ARG1" =~ $TICKET_PATTERN ]]; then
  # Manual mode.
  TICKET_KEY="$ARG1"
elif [[ "$ARG1" =~ $EVENT_PATTERN ]]; then
  # Hook mode.
  EVENT_NAME="$ARG1"
  TICKET_KEY="$ARG2"

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  _find_project_root() {
    local dir="$1"
    while [[ "$dir" != "/" ]]; do
      if [[ -d "$dir/.specify" || -d "$dir/.git" ]]; then
        echo "$dir"
        return 0
      fi
      dir="$(dirname "$dir")"
    done
    return 1
  }
  REPO_ROOT="$(_find_project_root "$SCRIPT_DIR")" || REPO_ROOT="$(pwd)"
  CONFIG_FILE="$REPO_ROOT/.specify/extensions/de-speckit-extension/de-speckit-extension-config.yml"

  # If the config file (or the jira_gate section, or this event's entry)
  # is missing, default to enforcing the gate — unlike e.g. the git
  # extension's auto-commit, this extension exists to make JIRA references
  # mandatory, so "no config yet" must not silently disable it.
  enabled=true
  default_enabled=true

  if [[ -f "$CONFIG_FILE" ]]; then
    in_section=false
    in_event=false
    event_found=false

    while IFS= read -r line; do
      if echo "$line" | grep -q '^jira_gate:'; then
        in_section=true
        in_event=false
        continue
      fi
      if $in_section && echo "$line" | grep -Eq '^[a-z]'; then
        break
      fi
      if $in_section; then
        if echo "$line" | grep -Eq '^[[:space:]]+default:[[:space:]]'; then
          val=$(echo "$line" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
          [[ "$val" == "false" ]] && default_enabled=false
          [[ "$val" == "true" ]] && default_enabled=true
        fi
        if echo "$line" | grep -Eq "^[[:space:]]+${EVENT_NAME}:"; then
          in_event=true
          event_found=true
          continue
        fi
        if $in_event; then
          if echo "$line" | grep -Eq '^[[:space:]]{2}[a-z]' && ! echo "$line" | grep -Eq '^[[:space:]]{4}'; then
            in_event=false
            continue
          fi
          if echo "$line" | grep -Eq '[[:space:]]+enabled:'; then
            val=$(echo "$line" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
            [[ "$val" == "false" ]] && enabled=false
            [[ "$val" == "true" ]] && enabled=true
          fi
        fi
      fi
    done < "$CONFIG_FILE"

    if ! $event_found; then
      enabled=$default_enabled
    fi
  fi

  if [[ "$enabled" != "true" ]]; then
    # Gate inactive for this event: complete no-op, regardless of whether
    # a ticket key was passed.
    exit 0
  fi

  if [[ -z "$TICKET_KEY" ]]; then
    err "JIRA gate is enabled for '$EVENT_NAME' but no SHDRP-<digits> ticket reference was found in the relevant input."
    exit 1
  fi
else
  err "Invalid first argument '$ARG1' — expected a ticket key (SHDRP-<digits>) or an event name (before_x / after_x)."
  exit 1
fi

if [[ ! "$TICKET_KEY" =~ $TICKET_PATTERN ]]; then
  err "Invalid ticket key '$TICKET_KEY' — expected format SHDRP-<digits> (e.g. SHDRP-437322)."
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

API_URL="${BASE_URL%/}/rest/api/3/issue/${TICKET_KEY}?fields=description"

http_response="$(curl -sS -w '\n%{http_code}' \
  -u "${ATLASSIAN_EMAIL}:${ATLASSIAN_API_TOKEN}" \
  -H "Accept: application/json" \
  "$API_URL")" || {
  err "Network error while contacting Jira at $BASE_URL."
  exit 1
}

http_status="${http_response##*$'\n'}"
http_body="${http_response%$'\n'*}"

case "$http_status" in
  200) ;;
  401 | 403)
    err "Authentication failed (HTTP $http_status). Check ATLASSIAN_EMAIL / ATLASSIAN_API_TOKEN."
    exit 1
    ;;
  404)
    err "Ticket '$TICKET_KEY' was not found in $BASE_URL."
    exit 1
    ;;
  *)
    err "Jira API returned HTTP $http_status for '$TICKET_KEY'."
    exit 1
    ;;
esac

# Atlassian Document Format (ADF) -> plain text. Preserves paragraph/block
# breaks (blank line between blocks); does not render Markdown syntax and
# does not special-case tables/lists (their cells/items are just flattened
# into the block stream, one per line).
read -r -d '' ADF_TO_TEXT_FILTER <<'JQ_EOF' || true
def render_inline(node):
  if node.type == "text" then (node.text // "")
  elif node.type == "hardBreak" then "\n"
  elif node.type == "mention" then (node.attrs.text // node.attrs.id // "")
  elif node.type == "emoji" then (node.attrs.shortName // node.attrs.text // "")
  elif node.type == "status" then (node.attrs.text // "")
  elif node.type == "date" then (node.attrs.timestamp // "")
  elif node.type == "inlineCard" then (node.attrs.url // "")
  else "" end;

def render_inline_list(content):
  [ (content // [])[] | render_inline(.) ] | join("");

def render_block(node):
  if node.type == "paragraph" or node.type == "heading" or node.type == "codeBlock"
     or node.type == "tableCell" or node.type == "tableHeader" or node.type == "taskItem" then
    render_inline_list(node.content)
  else
    # Containers (doc, bulletList/orderedList/listItem, blockquote, table,
    # tableRow, taskList, panel, expand, mediaSingle, ...): flatten children,
    # one block per line, blank line between them.
    [ (node.content // [])[] | render_block(.) ] | map(select(length > 0)) | join("\n\n")
  end;

render_block(.)
JQ_EOF

description_json="$(printf '%s' "$http_body" | jq -c '.fields.description' 2>/dev/null)" || {
  err "Failed to parse Jira API response as JSON."
  exit 1
}

if [[ -z "$description_json" || "$description_json" == "null" ]]; then
  err "Ticket '$TICKET_KEY' has no description content."
  exit 1
fi

plain_text="$(printf '%s' "$description_json" | jq -r "$ADF_TO_TEXT_FILTER")"

if [[ -z "${plain_text// /}" ]]; then
  err "Ticket '$TICKET_KEY' has an empty description."
  exit 1
fi

# Requirement-quality gate: this ticket must have been through
# requirement-self-check ([SPECKIT:CLARIFIED]) and that clarification must
# have been PM-reviewed (i.e. no leftover [SPECKIT:PENDING-REVIEW]) before
# its description is allowed to feed *any* spec-kit lifecycle event. This
# check runs identically in manual mode and hook mode — it is not gated by
# jira_gate.<event>.enabled beyond the enablement check already performed
# above; once enabled, this is unconditional and not configurable.
if grep -qF '[SPECKIT:PENDING-REVIEW]' <<<"$plain_text"; then
  err "Ticket '$TICKET_KEY' 的需求澄清结果还未经 PM review 确认（仍留有 [SPECKIT:PENDING-REVIEW] 标记）。请先完成 review、删除原始描述与该标记后再继续。"
  exit 1
elif ! $SKIP_CLARIFIED_CHECK && ! grep -qF '[SPECKIT:CLARIFIED]' <<<"$plain_text"; then
  err "Ticket '$TICKET_KEY' 尚未完成需求质量自检。请先运行 /speckit.de-speckit-extension.requirement-self-check ${TICKET_KEY}。"
  exit 1
fi

printf '%s\n' "$plain_text"
