import defaultTheme from "tailwindcss/defaultTheme";
import colors from "tailwindcss/colors";

/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: "selector",
  plugins: [require("autoprefixer"), require("daisyui")],
  theme: {
    extend: {
      fontFamily: {
        // font used in landing
        prompt: ['"Prompt"', ...defaultTheme.fontFamily.sans],
        // font is use in admin
        admin: ['"Prompt"', ...defaultTheme.fontFamily.sans],
        // font user in both
        body: ['"Open Sans"', ...defaultTheme.fontFamily.sans],
        mono: ["monospace", ...defaultTheme.fontFamily.mono],
      },
      fontSize: {
        "2xs": "0.625rem",
        "3xs": ["0.5rem", "1.25"],
      },
      spacing: {
        14: "3.5rem",
        80: "20rem",
      },
      backgroundOpacity: {
        90: "0.9",
      },
      colors: {
        "fbr-purple": "#7E0CF5",
        "fbr-purple-hint": "#9598CE",
        "fbr-red": "#FA3541",
        "brand-header": "#0F1027",
        "brand-pink-500": "#FE346E",
        "brand-orange-500": "#FF7315",
        "brand-purple-300": "#DF85E1",
        "brand-purple-500": "#7E0CF5",
        "brand-purple-800": "#270749",
        "brand-red-500": "#FA3541",
        "brand-red-300": "#FC727A",
        "brand-red-100": "#FEC7CA",
        "brand-dark-bg": "rgb(17, 10, 7)",
        gray: colors.zinc,
      },
      flex: {
        2: "2 2 0%",
      },
      borderWidth: {
        3: "3px",
        5: "5px",
      },
      minWidth: {
        5: "1.25rem",
        "1rem": "1rem",
        "1/2": "50%",
        16: "4rem",
        24: "6rem",
        48: "12rem",
      },
      maxWidth: {
        "1/2": "50%",
        80: "20rem",
      },
      minHeight: {
        5: "1.25rem",
        14: "3.5rem",
        "1rem": "1rem",
      },
      maxHeight: {
        "2/3": "66.66vh",
      },
      animation: {
        "spin-fast": "spin 0.4s linear infinite",
      },
    },
    borderWidth: {
      DEFAULT: "1px",
      0: "0",
      2: "2px",
      3: "3px",
      4: "4px",
      5: "5px",
      6: "6px",
      8: "8px",
    },
  },
  variants: {
    borderStyle: ["responsive", "hover", "focus", "dark"],
    borderColor: ["hover", "dark"],
    backgroundColor: ["responsive", "group-hover", "hover", "focus", "dark"],
    textColor: ["responsive", "hover", "focus", "group-hover", "dark"],
    transitionDelay: ["hover"],
    placeholderColor: ["dark"],
    extend: {
      display: ["group-hover"],
      borderRadius: ["last"],
      visibility: ["group-hover"],
    },
    visibility: ["hover"],
    translate: ["group-hover"],
    overflow: ["hover"],
    zIndex: ["hover"],
  },
};
