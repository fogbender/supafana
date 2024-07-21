const config = {
  prod: {
    apiUrl: "https://supafana.com/api",
  },
  staging: {
    apiUrl: "https://supafana-test.com/api",
  },
  dev: {
    apiUrl: "http://localhost:3901/api",
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
