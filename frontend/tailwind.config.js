/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{html,ts}'],
  theme: {
    extend: {
      // Design tokens sourced from Figma (file xKfXcdxRX8fLK8Grc46Vbw).
      // See specs/001-homepage-header/research.md Decision 4 and tasks.md T007/T008.
      colors: {
        'header-bg': '#F5F5F5', // node 2:63 "Backgorund 1" variable
        'header-text': '#666666', // node 2:64 / 2:107 / 2:115 / 2:123 text color
        'header-accent': '#008ECC', // icon accent referenced across 2:108 / 2:109 / 2:116
        'header-divider': '#D9D9D9', // node 2:124 / 2:125 line stroke
      },
      fontFamily: {
        header: ['HK Grotesk', 'sans-serif'], // node 2:64 font family
      },
      spacing: {
        'header-gutter': '7.5rem', // 120px side padding, derived from node 2:64 x=120 / container right padding 1440-1320
        'header-icon': '18px', // icon and divider height, shared by nodes 2:73 / 2:101 / 2:65 / 2:124 / 2:125
        'header-bar': '42px', // header bar height, node 2:63
      },
      lineHeight: {
        'header-welcome': '14px', // node 2:64 leading
        'header-entry': '18px', // node 2:107 / 2:115 / 2:123 leading
      },
    },
  },
  plugins: [],
};
