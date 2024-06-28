import type { APIContext } from "astro";
import child from "node:child_process";

export function getVersion() {
  let version: string | undefined = import.meta.env.PUBLIC_SHA;
  if (!version) {
    version = child.execSync("git rev-parse HEAD").toString().trim();
  }
  version = version.slice(0, 7);
  return version || undefined;
}

export function GET(_: APIContext) {
  const version = getVersion();
  return new Response(
    JSON.stringify({
      body: JSON.stringify({ version }),
    })
  );
}
