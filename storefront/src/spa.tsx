// tslint:disable:ordered-imports
import { initEnv } from "./env";
initEnv();
// import { initHyperDx as initHyperDx } from "../hyperdx";
// initHyperDx();
import "./styles/main.css";
import ReactSPA from "./App";

// tslint:disable-next-line:ordered-imports
import { setSwRegistration } from "./notifications";

document.head.querySelector("title[data-ssr]")?.remove();

export const App = () => {
  return <ReactSPA />;
};

if ("serviceWorker" in navigator) {
  const scopePath = "/~notifications/";
  navigator.serviceWorker
    .register(scopePath + "service-worker.js", { updateViaCache: "none", scope: scopePath })
    .then(swRegistration => {
      const onActivated = function onActivated() {
        setSwRegistration(swRegistration);
      };
      if (swRegistration.active) {
        onActivated();
      } else if (swRegistration.installing) {
        swRegistration.installing.addEventListener("statechange", function (ev) {
          "activated" === (ev.target as ServiceWorker)?.state && onActivated();
        });
      } else {
        console.warn(swRegistration);
      }
    })
    .catch(err => {
      console.error("Registration failed!", err);
    });
}
