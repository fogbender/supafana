import { QueryClient, useQuery } from "@tanstack/react-query";
import wretch from "wretch";
import QueryStringAddon from "wretch/addons/queryString";
import type { Organization } from "../types/supabase";

import { getServerUrl } from "../config";

export const queryClient = new QueryClient();

export const queryKeys = {
  organizations: () => ["organizations"],
  projects: (organizationId: string) => ["projects", organizationId],
  members: (organizationId: string) => ["members", organizationId],
  email: () => ["email"],
  fogbenderToken: (organizationId: string, email: string) => [
    "fogbnederToken",
    organizationId,
    email,
  ],
} as any;

export const apiServer = wretch(getServerUrl(), {
  credentials: "include",
}).addon(QueryStringAddon);

export const connectActionUrl = (() => {
  const params = new URLSearchParams({
    returnUrl: (() => {
      const url = window.origin + "/dashboard";
      return url.toString();
    })(),
  });
  return `${getServerUrl()}/auth/supabase-connect?${params.toString()}`;
})();

export const useOrganizations = () => {
  return useQuery({
    queryKey: queryKeys.organizations(),
    queryFn: async () => {
      return await apiServer.url(`/organizations`).get().json<Organization[]>();
    },
    retry: false,
  });
};
