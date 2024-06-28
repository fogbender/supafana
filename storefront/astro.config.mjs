// @ts-check
import mdx from "@astrojs/mdx";
import partytown from "@astrojs/partytown";
import react from "@astrojs/react";
import sitemap from "@astrojs/sitemap";
import { defineConfig } from "astro/config";
import checker from "vite-plugin-checker";

// https://astro.build/config
export default defineConfig({
  site: "https://supafana.com",
  integrations: [
    mdx(),
    react(),
    sitemap({
      filter: page =>
        ![
          //
          "https://supafana.com/SPA",
          "https://supafana.com/blog/draft",
        ].includes(page),
    }),
    partytown({ config: { forward: ["dataLayer.push"] } }),
  ],
  build: {
    format: "file",
  },
  vite: {
    plugins: [
      checker({
        typescript: true,
        overlay: {
          initialIsOpen: false,
          badgeStyle: "left: 55px; bottom: 8px;",
        },
      }),
    ],
    build: {
      sourcemap: true,
    },
    resolve: {
      alias: [
        {
          find: "./runtimeConfig",
          replacement: "./runtimeConfig.browser",
        },
      ],
    },
    ssr: {
      noExternal: ["smartypants"],
      external: ["svgo", "@11ty/eleventy-img"],
    },
  },
  server: { port: 3900 },
});
