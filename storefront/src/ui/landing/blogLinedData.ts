import type { AstroGlobal } from "astro";
import type { CollectionEntry } from "astro:content";

import { getMention } from "../../mentions";

export function getSchema({
  astro,
  content,
  wordCount,
}: {
  astro: AstroGlobal;
  content: CollectionEntry<"blog">["data"];
  wordCount: number;
}) {
  const { url, site } = astro;
  const { authors, coverImage, description, keywords, publishDate, title } = content;

  const author = authors
    .map(getMention)
    .map(({ name, social, jobTitle }) => ({
      "@type": "Person",
      name,
      jobTitle,
      sameAs: social,
    }))
    .find(() => true);

  if (!author) throw new Error("No author found");

  const thumbnail = `${site?.origin}${coverImage}`;

  const schema = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    "mainEntityOfPage": url,
    "headline": title,
    "name": title,
    "description": description,
    "datePublished": publishDate,
    "author": author,
    "publisher": {
      "@type": "Organization",
      "@id": "https://fogbender.com",
      "name": "Fogbender",
      "logo": "https://fogbender.com/logo192.png",
    },
    "image": {
      "@type": "ImageObject",
      "@id": thumbnail,
      "url": thumbnail,
    },
    "url": url,
    "isPartOf": {
      "@type": "Blog",
      "@id": "https://fogbender.com",
      "name": "Fogbender",
    },
    "wordCount": wordCount,
    "keywords": keywords,
  };
  return schema;
}
