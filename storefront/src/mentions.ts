import andrei from "./assets/authors/andrei.png";
import jlarky from "./assets/authors/jlarky.png";
import supafana from "./assets/authors/supafana.png";

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

type KnownAuthor = keyof typeof mentions;

type Author = (typeof mentions)[KnownAuthor];

const isKnownAuthor = (key: string): key is KnownAuthor => {
  return key in mentions;
};

export const getMention = (name: string) => {
  if (isKnownAuthor(name)) {
    return mentions[name];
  } else {
    return {
      name: "Supafana",
      avatar: supafana,
      twitter: "https://x.com/supafana",
      jobTitle: "Supafana",
      social: ["https://www.linkedin.com/company/fogbender", "https://x.com/supafana"],
    } as Author;
  }
};
