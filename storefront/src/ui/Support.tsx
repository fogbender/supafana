import classNames from "classnames";
import { Provider as JotaiProvider, useAtom } from "jotai";
import React from "react";
import { lazily } from "react-lazily";
import { QueryClientProvider, useQuery } from "@tanstack/react-query";
import { Title } from "reactjs-meta";
import wretch from "wretch";

import Header from "./Header";
import { useOrganizations, connectActionUrl, apiServer, queryClient, queryKeys } from "./client";
import Project from "./Project";

import { getServerUrl } from "../config";

import type { Organization, Member } from "../types/supabase";

(JotaiProvider as any).displayName = "JotaiProvider";

export const Support = () => {
  const { data: organizations, isLoading: organizationsLoading } = useOrganizations();

  const [connecting, setConnecting] = React.useState(false);

  const organization = organizations?.[0];

  const { data: members } = useQuery({
    queryKey: queryKeys.members(organization?.id),
    queryFn: async () => {
      return await apiServer
        .url(`/organizations/${organization?.id}/members`)
        .get()
        .json<Member[]>();
    },
    enabled: !!organization,
  });

  console.log(members);

  // get all users in organization
  // have user select themselves
  // confirm email
  // continue

  return (
    <div className="h-full flex flex-col">
      <Header organization={organization} />
      <div className="flex-1 flex justify-center text-black dark:text-white">
        {organization ? (
          <div className="w-3/4"></div>
        ) : connecting || organizationsLoading ? (
          <span className="loading loading-ring loading-lg text-accent" />
        ) : (
          <form
            onClick={e => {
              if (e.target instanceof HTMLElement) {
                const form = e.target.closest("form");

                if (form) {
                  setConnecting(true);
                  form.submit();
                }
              }
            }}
            method="post"
            action={connectActionUrl}
          >
            <button type="button">
              <img src="/connect-supabase-dark.svg" alt="Connect Supabase button" />
            </button>
          </form>
        )}
      </div>
    </div>
  );
};

export const SupportWithProviders = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <JotaiProvider>
        <Support />
      </JotaiProvider>
    </QueryClientProvider>
  );
};
