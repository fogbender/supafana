import browser from "browser-detect";
import classNames from "classnames";
import { Provider as JotaiProvider, useAtom } from "jotai";
import React from "react";
import { lazily } from "react-lazily";
import { QueryClientProvider, useMutation, useQuery } from "@tanstack/react-query";
import { Title } from "reactjs-meta";
import wretch from "wretch";
import { apiServer, queryClient, queryKeys } from "./client";
import SupafanaLogo from "./landing/assets/logo.svg?url";
import ThemeController from "./ReactThemeController";

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

  const [connecting, setConnecting] = React.useState(false);

  return (
    <div className="h-full flex flex-col">
      <div className="bg-transparent sticky top-0 z-20">
        <div
          className="nav-container-blur bg-white absolute z-[-1] h-full w-full shadow-[0_2px_4px_rgba(0,0,0,.02),0_1px_0_rgba(0,0,0,.06)] dark:shadow-[0_-1px_0_rgba(255,255,255,.1)_inset] dark:bg-black dark:contrast-more:shadow-[0_0_0_1px_#000] contrast-more:shadow-[0_0_0_1px_#fff]"
        >
        </div>
        <nav
          className="mx-auto flex h-16 max-w-[90rem] items-center justify-end gap-2 pl-[max(env(safe-area-inset-left),1.5rem)] pr-[max(env(safe-area-inset-right),1.5rem)]"
        >
          <div className="flex items-center mr-auto gap-x-5">
            <img src={SupafanaLogo} alt="supafana-logo" width={35} height={35} />
          </div>
          {organizations && (
            <form className="" method="post" action={signOutActionUrl}>
              <button className="btn btn-xs" type="submit">
                Sign out
              </button>
            </form>
          )}
          <ThemeController />
        </nav>
      </div>
      <div className="flex-1 flex items-center justify-center text-black dark:text-white">
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
          </div>
        ) : (
          connecting ? (
            <span className="loading loading-ring loading-lg text-accent" />
          ) : (
            <form
              onClick={(e) => {
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
          )
        )}
      </div>
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
