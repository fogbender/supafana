import { defineCollection, z } from "astro:content";
import dayjs from "dayjs";
const blog = defineCollection({
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      description: z.string(),
      authors: z.array(z.enum(["andrei", "jlarky"])),
      publishDate: z.string().transform(val => dayjs(val).format("MMMM D, YYYY")),
      socialImage: image(),
      thumbnailImage: image().optional(),
      coverImage: image().optional(),
      coverImageAspectRatio: z
        .string()
        .regex(/^\d+:\d+$/)
        .optional()
        .transform(val => {
          if (!val) return undefined;
          const [width, height] = val.split(":").map(Number);
          return width / height;
        }),
      coverImageAlt: z.string().optional(),
      heroImage: image().optional(),
      heroImageAlt: z.string().optional(),
      hidden: z.boolean().optional(),
      keywords: z.array(z.string()).optional(),
    }),
});

export const collections = { blog };
