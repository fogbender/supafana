import andrei from "./assets/authors/andrei.png";
import jlarky from "./assets/authors/jlarky.png";

export const mentions = {
  jlarky: {
    name: "Yaroslav Lapin",
    avatar: jlarky,
    twitter: "https://x.com/JLarky",
    jobTitle: "VP of Engineering at Fogbender",
    social: ["https://www.linkedin.com/in/jlarky", "https://x.com/JLarky"],
  },
  andrei: {
    name: "Andrei Soroker",
    avatar: andrei,
    twitter: "https://x.com/soroker",
    jobTitle: "CEO at Fogbender",
    social: ["https://www.linkedin.com/in/soroker", "https://x.com/soroker"],
  },
};

export type AuthorName = keyof typeof mentions;

export const getMention = (name: AuthorName) => {
  const author = mentions[name];
  if (!author) {
    throw new Error(`Could not find author "${name}"!`);
  }
  return author;
};
