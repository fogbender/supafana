import classNames from "classnames";
import { Provider as JotaiProvider, useAtom } from "jotai";
import React from "react";
import { lazily } from "react-lazily";
import { QueryClientProvider, useMutation, useQuery } from "@tanstack/react-query";
import { Title } from "reactjs-meta";
import wretch from "wretch";

import SectionHeader from "./SectionHeader";
import Notifications from "./Notifications";
import Header from "./Header";
import Billing from "./Billing";
import {
  useMe,
  useOrganizations,
  connectActionUrl,
  apiServer,
  queryClient,
  queryKeys,
} from "./client";
import Project from "./Project";

import type { Organization, Project as ProjectT } from "../types/supabase";

import type { Grafana as GrafanaT } from "../types/z_types";

(JotaiProvider as any).displayName = "JotaiProvider";

export const Dashboard = () => {
  const {
    data: organizations,
    isLoading: organizationsLoading,
    error: organizationsError,
  } = useOrganizations();

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

  const { data: grafanas, isLoading: grafanasLoading } = useQuery({
    queryKey: queryKeys.grafanas(organizationId),
    queryFn: async () => {
      return await apiServer.url(`/grafanas`).get().json<GrafanaT[]>();
    },
    enabled: !!organizationId && !!projects,
  });

  const [connecting, setConnecting] = React.useState(false);

  const organization = organizations?.[0];

  const { data: me } = useMe();

  return (
    <div className="min-h-screen flex flex-col pb-12">
      <Header organization={organization} />
      <div className="mt-4 flex-1 flex flex-col items-center justify-center text-black dark:text-white">
        {organization && !organizationsError ? (
          <div className="pl-4 w-full flex flex-col gap-10">
            {projectsLoading || grafanasLoading ? (
              <div className="flex w-52 flex-col gap-4">
                <div className="skeleton h-4 w-full"></div>
                <div className="skeleton h-4 w-full"></div>
                <div className="skeleton h-4 w-full"></div>
              </div>
            ) : (
              <div>
                <SectionHeader text="Databases and Grafana instances" />
                {/*<div className="flex flex-col border-y border-gray-200 dark:border-gray-700 divide-y divide-gray-200 dark:divide-gray-700">*/}
                <div className="flex flex-col">
                  {projects
                    ?.sort((p0, p1) => (p0.id > p1.id ? -1 : 1))
                    .map(p => (
                      <Project
                        key={p.id}
                        project={p}
                        grafana={grafanas?.find(g => g.supabase_id === p.id)}
                      />
                    ))}
                </div>
              </div>
            )}
            <Notifications organization={organization} me={me} />
            <div>
              <SectionHeader text="Billing" />
              <Billing organization={organization} />
            </div>
          </div>
        ) : connecting || organizationsLoading ? (
          <span className="loading loading-ring loading-lg text-accent" />
        ) : (
          <form
            className=""
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

export const DashboardWithProviders = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <JotaiProvider>
        <Dashboard />
      </JotaiProvider>
    </QueryClientProvider>
  );
};
