/** @type {import('tailwindcss').Config} */
module.exports = {
  presets: [require("./src/supafana.tailwind.preset.js")],
  content: [
    //
    "./public/**/*.html",
    "./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}",
  ],
  theme: {
    extend: {
      typography: ({ theme }) => ({
        fog: {
          css: {
            "--tw-prose-links": "#3291ff",
            "--tw-prose-body": theme("colors.gray.600"),
            "--tw-prose-bullets:": theme("colors.black")
          },
        },
      }),
    },
  },
  plugins: [require("@tailwindcss/custom-forms"), require("@tailwindcss/typography")],
};
