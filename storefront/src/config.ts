const config = {
  prod: {
    apiUrl: "https://api.supafana.com",
  },
  staging: {
    apiUrl: "https://api.supafana-test.com",
  },
  dev: {
    apiUrl: "http://localhost:9080",
  },
};

export type Env = keyof typeof config;

export function getConfig(env: Env = "dev") {
  const envCfg = config[env];
  return {
    ...envCfg,
    /* overwrite: "some value" */
  };
}

export function getServerUrl(env?: Env) {
  return getConfig(env).apiUrl;
}

/*
HyperDX.setGlobalAttributes({
  version: getVersion().niceVersion,
});
*/

