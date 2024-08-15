import classNames from "classnames";
import { Provider as JotaiProvider, useAtom } from "jotai";
import React from "react";
import { QueryClientProvider, useQuery, useMutation } from "@tanstack/react-query";
import wretch from "wretch";
import {
  createNewFogbender,
  FogbenderConfig,
  FogbenderIsConfigured,
  FogbenderProvider,
  FogbenderWidget,
  type Token as FogbenderToken,
} from "fogbender-react";

import Header from "./Header";
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
import { localStorageKey, getLocalStorage, type Mode as ThemeMode } from "./ReactThemeController";
import MemberRow from "./MemberRow";

import { getServerUrl } from "../config";

import type { Organization, Member } from "../types/supabase";

(JotaiProvider as any).displayName = "JotaiProvider";

export const Support = () => {
  const fogbender = React.useRef(createNewFogbender());

  const [mode, setMode] = React.useState<ThemeMode>("dark");

  React.useEffect(() => {
    setMode(getLocalStorage(localStorageKey));

    const onstorage = (event: StorageEvent) => {
      if (event.key === localStorageKey) {
        setMode(getLocalStorage(localStorageKey));
      }
    };

    window.addEventListener("storage", onstorage);

    return () => {
      window.removeEventListener("storage", onstorage);
    };
  }, []);

  const {
    data: organizations,
    isLoading: organizationsLoading,
    error: organizationsError,
  } = useOrganizations();

  const [connecting, setConnecting] = React.useState(false);

  const organization = organizations?.[0];

  const { data: me, isFetched: meFetched } = useMe();

  const { data: members, isLoading: membersLoading } = useMembers({
    enabled: !!organization && meFetched && !me,
    organizationId: organization?.id as string,
    showEmails: true,
  });

  const {
    data: fogbenderSignaturesData,
    isLoading: fogbenderSignaturesLoading,
    isPending: fogbenderSignaturesPending,
    isFetching: fogbenderSignaturesFetching,
  } = useQuery({
    queryKey: queryKeys.fogbenderToken(organization?.id, me?.user_id),
    queryFn: async () => {
      return await apiServer
        .url("/fogbender-signatures")
        .get()
        .json<{ signatures: { userJWT: string }; widgetId: string }>();
    },
    enabled: !!me && !!organization?.id,
  });

  const [fogbenderToken, setFogbenderToken] = React.useState<FogbenderToken>();

  const fogbenderSignaturesInProgress =
    (me ?? false) &&
    (organization ?? false) &&
    (fogbenderSignaturesLoading || fogbenderSignaturesPending || fogbenderSignaturesFetching);

  React.useEffect(() => {
    if (
      fogbenderSignaturesData &&
      organization &&
      fogbenderSignaturesData.widgetId &&
      fogbenderSignaturesData.signatures &&
      me?.user_id &&
      me?.email
    ) {
      setFogbenderToken({
        userId: me.user_id,
        userName: me.email,
        userEmail: me.email,
        customerName: organization.name,
        customerId: organization.id,
        widgetId: fogbenderSignaturesData.widgetId,
        userJWT: fogbenderSignaturesData.signatures.userJWT,
      });
    }
  }, [organization, fogbenderSignaturesData]);

  return (
    <div className="flex flex-col min-h-screen">
      <Header organization={organization} />
      {me && fogbenderToken ? (
        <div className="flex-1">
          <FogbenderProvider fogbender={fogbender.current}>
            <FogbenderConfig
              clientUrl="https://client.fogbender.com"
              token={fogbenderToken}
              mode={mode}
            />
            <FogbenderIsConfigured>
              <FogbenderWidget />
            </FogbenderIsConfigured>
          </FogbenderProvider>
        </div>
      ) : !fogbenderSignaturesInProgress && organization && !organizationsError ? (
        <div className="mt-12 flex-1 flex ml-2 md:ml-16 text-black dark:text-white">
          <div className="max-w-xl">
            <p>
              The Supabase integration flow reveals the name of your Supabase organization (
              {organization.name}), but we can’t tell who you are. Before rendering the support
              widget, we’ll need to sort this out.
            </p>
            <br />
            <p>Please select your user below to continue:</p>

            {membersLoading ? (
              <div className="flex w-52 flex-col gap-4">
                <div className="skeleton h-4 w-full"></div>
                <div className="skeleton h-4 w-full"></div>
                <div className="skeleton h-4 w-full"></div>
              </div>
            ) : (
              <table className="mt-8 text-gray-200 dark:text-gray-700 bg-dots table">
                <tbody>
                  {members.map(m => (
                    <MemberRow m={m} me={me} key={m.user_id} verifyText="🙋 That’s me!" />
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      ) : fogbenderSignaturesInProgress || connecting || organizationsLoading ? (
        <div className="flex-1 flex items-center justify-center text-black dark:text-white">
          <span className="loading loading-ring loading-lg text-accent" />
        </div>
      ) : (
        <div className="flex-1 flex items-center justify-center text-black dark:text-white">
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
        </div>
      )}
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
