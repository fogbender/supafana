const config = {
  prod: {
    apiUrl: "/api",
  },
  staging: {
    apiUrl: "/api",
  },
  dev: {
    apiUrl: "/api",
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
