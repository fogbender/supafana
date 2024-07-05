import classNames from "classnames";
import { Provider as JotaiProvider, useAtom } from "jotai";
import React from "react";
import { lazily } from "react-lazily";
import { QueryClientProvider, useMutation, useQuery } from "@tanstack/react-query";
import { Title } from "reactjs-meta";
import wretch from "wretch";
import { apiServer, queryClient, queryKeys } from "./client";
import SupafanaLogo from "./landing/assets/logo.svg?url";
import SupabaseLogo from "./landing/assets/supabase-logo-icon.svg?url";
import ThemeController from "./ReactThemeController";
import Project from "./Project";

import { getServerUrl } from "../config";

import type { Organization, Project as ProjectT } from "../types/supabase";

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

  const { data: organizations, isLoading: organizationsLoading } = useQuery({
    queryKey: queryKeys.organizations(),
    queryFn: async () => {
      return await apiServer.url(`/organizations`).get().json<Organization[]>();
    },
    retry: false,
  });

  // XXX looks like at the moment we can only deal with one organization at the time, per access token
  // (Because an access token is created in a specific organization)
  const organizationId = organizations?.[0]?.id;

  const { data: projects, isLoading: projectsLoading } = useQuery({
    queryKey: queryKeys.projects(organizationId),
    queryFn: async () => {
      return await apiServer.url(`/projects`).get().json<ProjectT[]>();
    },
    enabled: !!organizationId,
  });

  console.log(organizationId, organizations);

  const [connecting, setConnecting] = React.useState(false);

  const organization = organizations?.[0];

  return (
    <div className="h-full flex flex-col">
      <div className="bg-transparent sticky top-0 z-20">
        <div
          className="nav-container-blur bg-white absolute z-[-1] h-full w-full shadow-[0_2px_4px_rgba(0,0,0,.02),0_1px_0_rgba(0,0,0,.06)] dark:shadow-[0_-1px_0_rgba(255,255,255,.1)_inset] dark:bg-black dark:contrast-more:shadow-[0_0_0_1px_#000] contrast-more:shadow-[0_0_0_1px_#fff]"
        >
        </div>
        <nav
          className="mx-auto flex h-16 max-w-[90rem] items-center justify-end gap-3 pl-[max(env(safe-area-inset-left),1.5rem)] pr-[max(env(safe-area-inset-right),1.5rem)] text-black dark:text-white"
        >
          <div className="flex items-center mr-auto gap-x-5">
            <a title="Home" href="/">
              <img src={SupafanaLogo} alt="Supafana logo" width={35} height={35} />
            </a>
          </div>
          {organization && (
            <a
              className="text-sm font-medium flex items-center gap-1.5 link link-primary dark:link-secondary"
              href={`https://supabase.com/dashboard/org/${organization.id}`}
              title={`Open ${organization.name} in Supabase`}
            >
              <img src={SupabaseLogo} alt="Supabase logo" width={12} height={12} />
              {organization.name}
            </a>
          )}
          {organization && (
            <form
              onClick={(e) => {
                if (e.target instanceof HTMLElement) {
                  const form = e.target.closest("form");

                  if (form) {
                    form.submit();
                  }
                }
              }}
              method="post"
              action={signOutActionUrl}
            >
              <button className="btn btn-xs" type="submit">
                Sign out
              </button>
            </form>
          )}
          <ThemeController />
        </nav>
      </div>
      <div className="flex-1 flex items-center justify-center text-black dark:text-white">
        {organization ? (
          <div className="w-3/4">
            {projectsLoading ? (
              <div className="flex w-52 flex-col gap-4">
                <div className="skeleton h-4 w-full"></div>
                <div className="skeleton h-4 w-full"></div>
                <div className="skeleton h-4 w-full"></div>
              </div>
            ) : (
              <div className="flex flex-col gap-4">
                {projects?.map(p => (
                  <Project key={p.id} project={p} />
                ))}
              </div>
            )}
          </div>
        ) : (
          (connecting || organizationsLoading) ? (
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
