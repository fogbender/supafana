import classNames from "classnames";
import { Provider as JotaiProvider, useAtom } from "jotai";
import React from "react";
import { lazily } from "react-lazily";
import { QueryClientProvider, useMutation, useQuery } from "@tanstack/react-query";
import { Title } from "reactjs-meta";
import wretch from "wretch";

import MemberRow from "./MemberRow";
import Header from "./Header";
import Billing from "./Billing";
import {
  useMe,
  useMembers,
  useOrganizations,
  connectActionUrl,
  apiServer,
  queryClient,
  queryKeys,
} from "./client";
import Project from "./Project";

import type { Organization, Project as ProjectT } from "../types/supabase";

(JotaiProvider as any).displayName = "JotaiProvider";

export const Dashboard = () => {
  const { data: organizations, isLoading: organizationsLoading } = useOrganizations();

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

  const { data: members, isLoading: membersLoading } = useMembers({
    enabled: !!organization,
    organizationId: organization?.id as string,
    showEmails: true,
  });

  const { data: me } = useMe();

  return (
    <div className="h-full flex flex-col">
      <Header organization={organization} />
      <div className="mt-4 flex-1 flex flex-col items-center justify-center text-black dark:text-white">
        {organization ? (
          <div className="w-full flex flex-col gap-4">
            <div className="self-start">
              <div className="ml-4 font-medium">
                Who should get email notifications from Supafana?
              </div>
              {!me && (
                <div className="ml-4 text-sm text-gray-500 font-medium">
                  Please verify your email below to configure
                </div>
              )}
              {membersLoading && (
                <div className="flex w-52 flex-col gap-4">
                  <div className="skeleton h-4 w-full"></div>
                  <div className="skeleton h-4 w-full"></div>
                  <div className="skeleton h-4 w-full"></div>
                </div>
              )}
              {members && (
                <div className="p-4">
                  <table className="text-gray-200 dark:text-gray-700 bg-dots table">
                    <tbody>
                      {members.map(m => (
                        <MemberRow m={m} me={me} key={m.user_id} verifyText="Verify">
                          <input
                            type="checkbox"
                            onChange={() => {}}
                            value={me?.email || m.email ? "checked" : "not checked"}
                            checked={me?.email || m.email ? true : false}
                            className="checkbox checkbox-info checkbox-sm"
                          />
                        </MemberRow>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
            <div className="ml-4">
              <div className="font-medium">Billing</div>
              <Billing organization={organization} />
            </div>
            {projectsLoading ? (
              <div className="flex w-52 flex-col gap-4">
                <div className="skeleton h-4 w-full"></div>
                <div className="skeleton h-4 w-full"></div>
                <div className="skeleton h-4 w-full"></div>
              </div>
            ) : (
              <div>
                <div className="ml-4 font-medium">Databases and monitoring instances</div>
                {/*<div className="flex flex-col border-y border-gray-200 dark:border-gray-700 divide-y divide-gray-200 dark:divide-gray-700">*/}
                <div className="flex flex-col">
                  {projects?.map(p => <Project key={p.id} project={p} />)}
                </div>
              </div>
            )}
          </div>
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

export const DashboardWithProviders = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <JotaiProvider>
        <Dashboard />
      </JotaiProvider>
    </QueryClientProvider>
  );
};
