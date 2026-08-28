module.exports = {
  content: ["./index.html", "./src/**/*.js"],
  theme: {
    extend: {
      colors: {
        ink: "#1a1c1e",
        slate: "#6c7278",
        clay: { DEFAULT: "#b8422e", dark: "#9e3826" },
        limestone: "#f7f5f2",
      },
      fontFamily: {
        serif: ['"Source Serif 4"', "Georgia", "serif"],
        mono: ['"IBM Plex Mono"', "ui-monospace", "monospace"],
      },
      borderRadius: { sm: "4px", pill: "9999px" },
      spacing: { 1: "4px", 2: "8px", 3: "16px", 4: "24px", 6: "48px" },
    },
  },
};
