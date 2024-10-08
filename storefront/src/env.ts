/// <reference types="vite/client" />
/// <reference types="astro/client" />
/// <reference path="../.astro/types.d.ts" />

export function initEnv() {
  if (!import.meta.env.SSR) {
    window.global = window.global || window;
    window.process = window.process || {};
  }
  process.env = process.env || {};
  process.env = Object.assign(process.env, import.meta.env);
}
