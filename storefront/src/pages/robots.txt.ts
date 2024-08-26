import type { APIContext } from "astro";

const devRobots = `
# https://www.robotstxt.org/robotstxt.html
User-agent: *
Disallow: /
`;

const prodRobots = `
# https://www.robotstxt.org/robotstxt.html
User-agent: *
Disallow: /?lang=*
Disallow: /blog/draft
Disallow: /api
Disallow: /dashboard
Host: supafana.com

Sitemap: https://supafana.com/sitemap-index.xml
`;

export async function GET(_ : APIContext) {
  const supafanaEnv = import.meta.env.SUPAFANA_ENV;
  if (supafanaEnv == 'prod') {
    return new Response(prodRobots)
  } else {
    return new Response(devRobots)
  }
}
