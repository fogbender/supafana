import classNames from "classnames";
import { Provider as JotaiProvider, useAtom } from "jotai";
import React from "react";
import { QueryClientProvider, useQuery, useMutation } from "@tanstack/react-query";
import wretch from "wretch";
import { FogbenderSimpleWidget, type Token as FogbenderToken } from "fogbender-react";

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

  const { data: email, isFetched: emailFetched } = useQuery({
    queryKey: queryKeys.email(),
    queryFn: async () => {
      return await apiServer.url("/email").get().json<string>();
    },
  });

  const { data: members, isLoading: membersLoading } = useQuery({
    queryKey: queryKeys.members(organization?.id),
    initialData: [],
    queryFn: async () => {
      return await apiServer
        .url(`/organizations/${organization?.id}/members`)
        .get()
        .json<Member[]>();
    },
    enabled: !!organization && emailFetched && !email,
  });

  const { data: fogbenderTokenData } = useQuery({
    queryKey: queryKeys.fogbenderToken(organization?.id, email),
    queryFn: async () => {
      return await apiServer
        .url("/fogbender-token")
        .get()
        .json<{ token: FogbenderToken; widgetId: string }>();
    },
    enabled: email !== undefined && organization?.id !== undefined,
  });

  const [fogbenderToken, setFogbenderToken] = React.useState<FogbenderToken>();

  React.useEffect(() => {
    if (
      fogbenderTokenData &&
      organization &&
      fogbenderTokenData.widgetId &&
      fogbenderTokenData.token
    ) {
      setFogbenderToken({
        userId: email,
        userName: email,
        userEmail: email,
        customerName: organization.name,
        customerId: organization.id,
        widgetId: fogbenderTokenData.widgetId,
        userJWT: fogbenderTokenData.token?.userJWT,
      });
    }
  }, [organization, fogbenderTokenData]);

  console.log(fogbenderToken);

  return (
    <div className="h-full flex flex-col">
      <Header organization={organization} />
      {email && fogbenderToken ? (
        <div className="flex-1">
          <FogbenderSimpleWidget token={fogbenderToken} />
        </div>
      ) : organization ? (
        <div className="mt-12 flex-1 flex ml-2 md:ml-16 text-black dark:text-white">
          <div className="max-w-xl">
            <p>
              The Supabase integration flow reveals the name and slug of your organization (
              {organization.name}), but we can’t tell who you are. Before rendering the support
              widget, we’ll need sort this out.
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
                    <MemberRow m={m} key={m.user_id} />
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      ) : connecting || organizationsLoading ? (
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

const MemberRow = ({ m }: { m: Member }) => {
  const [email, setEmail] = React.useState("");
  const [badEmail, setBadEmail] = React.useState(false);
  const [verificationCode, setVerificationCode] = React.useState("");

  const sendVerificationCodeMutation = useMutation({
    mutationFn: () => apiServer.url("/send-email-verification-code").post({ email }).text(),
    onError: error => {
      if (error.message === "Invalid email address") {
        setBadEmail(true);
      }
    },
  });

  const probeVerificationCodeMutation = useMutation({
    mutationFn: () =>
      apiServer.url("/probe-email-verification-code").post({ verificationCode }).text(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.email() });
    },
  });

  return (
    <tr>
      <td>
        <span className="text-gray-700 dark:text-gray-300">{m.user_name}</span>
      </td>
      <td>
        <span className="text-gray-700 dark:text-gray-300">
          {m.email ? (
            m.email
          ) : (
            <div className="flex flex-col gap-1.5">
              <input
                type="email"
                value={email}
                onChange={e => {
                  setBadEmail(false);
                  setEmail(e.target.value);
                }}
                className={classNames(
                  "bg-white dark:bg-gray-600",
                  "border rounded px-2 py-1",
                  badEmail ? "border-red-500" : "border-gray-500"
                )}
                placeholder="Enter your email"
              />
              {sendVerificationCodeMutation.isSuccess && (
                <div className="flex items-center gap-1.5">
                  <input
                    type="text"
                    value={verificationCode}
                    disabled={probeVerificationCodeMutation.isPending}
                    onChange={e => {
                      setVerificationCode(e.target.value);
                    }}
                    className={classNames(
                      "bg-white dark:bg-gray-600",
                      "border rounded px-2 py-1",
                      "border-gray-500"
                    )}
                    placeholder="Enter verification code"
                  />
                  <button
                    type="button"
                    disabled={verificationCode === ""}
                    className="btn btn-sm btn-accent"
                    onClick={() => probeVerificationCodeMutation.mutate()}
                  >
                    Go
                  </button>
                </div>
              )}
            </div>
          )}
        </span>
      </td>
      <td className="text-black dark:text-white">
        <button
          className="btn btn-accent btn-xs w-28"
          disabled={!m.email && email === ""}
          onClick={() => {
            setVerificationCode("");
            sendVerificationCodeMutation.mutate();
          }}
        >
          {sendVerificationCodeMutation.isPending ? (
            <span className="text-black loading loading-ring loading-xs h-3"></span>
          ) : (
            <span className="leading-none">
              {sendVerificationCodeMutation.isSuccess ? (
                <span>Send new code</span>
              ) : (
                <span>That’s me!</span>
              )}
            </span>
          )}
        </button>
      </td>
    </tr>
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
