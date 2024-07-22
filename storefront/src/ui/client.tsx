import { QueryClient, useQuery } from "@tanstack/react-query";
import wretch from "wretch";
import QueryStringAddon from "wretch/addons/queryString";
import type { Organization, Member } from "../types/supabase";
import type { Me } from "../types/supafana";

import { getServerUrl } from "../config";

export const queryClient = new QueryClient();

export const queryKeys = {
  organizations: () => ["organizations"],
  projects: (organizationId: string) => ["projects", organizationId],
  grafanas: (organizationId: string) => ["grafanas", organizationId],
  grafana: (organizationId: string, projectRef: string) => ["grafana", organizationId, projectRef],
  members: (organizationId: string) => ["members", organizationId],
  me: () => ["email"],
  fogbenderToken: (organizationId: string, userId: string) => [
    "fogbnederToken",
    organizationId,
    userId,
  ],
  billing: (organizationId: string) => ["billing", organizationId],
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

export const useMembers = ({
  organizationId,
  enabled,
  showEmails,
}: {
  organizationId: string;
  enabled: boolean;
  showEmails: boolean;
}) => {
  return useQuery({
    queryKey: queryKeys.members(organizationId),
    initialData: [],
    queryFn: async () => {
      return await apiServer
        .url(`/organizations/${organizationId}/members?showEmails=${showEmails}`)
        .get()
        .json<Member[]>();
    },
    enabled,
  });
};

export const useMe = () => {
  return useQuery({
    queryKey: queryKeys.me(),
    queryFn: async () => {
      return await apiServer.url("/me").get().json<Me | null>();
    },
    initialData: null,
  });
};
