import React from "react";

export const Landing = () => {
  // this component serves two goals:
  // - on dev it will show a message that our landing is in Astro
  // - on prod what could technically happen is that React Router can call `navigate("/")` and it will get user stuck on a blank page since Astro pages can't be accessed from ReactRouter and requires a full page reload. In that case we log an error so we can fix it later
  React.useEffect(() => {
    if (!import.meta.env.DEV) {
      console.error("Redirecting to Astro landing page from React");
      // do this just in case to make sure we don't have an infinite loop
      const search = new URLSearchParams(window.location.search);
      const fromApp = search.has("from_app");
      if (!fromApp) {
        // Astro landing page can't be accessed from react, so we need to reload the page
        window.location.href = "/?from_app";
      }
    }
  }, []);
  if (import.meta.env.DEV) {
    return (
      <div>
        <div className="p-20 text-center text-6xl">Landing</div>
        <div className="container mx-auto text-center">
          You are here because you are in development mode. If you want to see the Astro landing
          page, please start `yarn start` instead of `yarn dev`.
        </div>
        <div className="container mx-auto text-center text-xl">
          Or return to the <a href="/dashboard">App</a>
        </div>
      </div>
    );
  }
  return null;
};
