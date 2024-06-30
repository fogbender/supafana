import browser from "browser-detect";
import classNames from "classnames";
import { Provider as JotaiProvider, useAtom } from "jotai";
import React from "react";
import { lazily } from "react-lazily";
import { QueryClientProvider, useMutation, useQuery } from "@tanstack/react-query";
import { Title } from "reactjs-meta";
import wretch from "wretch";
import { apiServer, queryClient, queryKeys } from "./client";

import { getServerUrl } from "../config";

import type { Organization, Project } from "../types/supabase";

(JotaiProvider as any).displayName = "JotaiProvider";

export const Dashboard = () => {
  const connectActionUrl = (() => {
    const params = new URLSearchParams({
      returnUrl: (() => {
        const url = window.origin + "/dashboard";
        return url.toString();
      })(),
    });
    return `${getServerUrl()}/auth/supabase-connect?${params.toString()}`;
  })();

  const signOutActionUrl = `${getServerUrl()}/auth/sign-out`;

  const { data: organizations } = useQuery({
    queryKey: queryKeys.organizations(),
    queryFn: async () => {
      return await apiServer.url(`/organizations`).get().json<Organization[]>();
    }
  });

  // XXX looks like at the moment we can only deal with one organization at the time, per access token
  // (Because an access token is created in a specific organization)
  const organizationId = organizations?.[0]?.id;

  const { data: projects } = useQuery({
    queryKey: queryKeys.projects(organizationId),
    queryFn: async () => {
      return await apiServer.url(`/projects`).get().json<Project[]>();
    },
    enabled: !!organizationId,
  });

  console.log(organizationId, organizations);

  return (
    <div className="flex h-full w-full items-center justify-center">
      {organizations ? (
        <div>
          {organizations.map(o => (
            <div key={o.id}>
              <div>{o.name} (organization)</div>
              {projects?.map(p => (
                <div key={p.id}>
                  <div>{p.name} (project) - {p.id} - {p.status}</div>
                </div>
              ))}
            </div>
          ))}

          <form method="post" action={signOutActionUrl}>
            <button className="btn" type="submit">
              Sign out
            </button>
          </form>
        </div>
      ) : (
        <form method="post" action={connectActionUrl}>
          <button type="submit">
            <img src="/connect-supabase-dark.svg" alt="Connect Supabase button" />
          </button>
        </form>
      )}
    </div>
  );
};

export const DashboardWithProviders = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <JotaiProvider>
        <Dashboard />
      </JotaiProvider>
    </QueryClientProvider>
  );
};
