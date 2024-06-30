import { QueryClient } from "@tanstack/react-query";
import wretch from "wretch";
import QueryStringAddon from "wretch/addons/queryString";

import { getServerUrl } from "../config";

export const queryClient = new QueryClient();

export const queryKeys = {
  organizations: () => ["organizations"],
  projects: (organizationId: string) => ["projects", organizationId],
} as any;

export const apiServer = wretch(getServerUrl(), {
  credentials: "include",
}).addon(QueryStringAddon);
