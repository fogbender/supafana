/// <reference types="astro/client" />
/// <reference path="../.astro/types.d.ts" />
declare module "smartypants" {
  export function smartypants(text: string, attr?: number): string;
}

declare module "node:child_process" {
  export function execSync(command: string): Buffer;
}

interface Window {
  _supafana_version: string | undefined;
}
