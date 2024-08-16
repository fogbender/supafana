import React from "react";
import { useLocation } from "react-router-dom";
import { HiExternalLink as ExternalLink } from "react-icons/hi";
import { useQuery } from "@tanstack/react-query";

import { nbsp } from "./Utils";

import {
  createNewFogbender,
  FogbenderConfig,
  FogbenderIsConfigured,
  FogbenderProvider,
  FogbenderHeadlessWidget,
  FogbenderUnreadBadge,
  type Token as FogbenderToken,
} from "fogbender-react";

import SupabaseLogo from "./landing/assets/supabase-logo-icon.svg?url";
import SupafanaLogo from "./landing/assets/logo.svg?url";
import ThemeController from "./ReactThemeController";

import { useMe, apiServer, queryKeys, queryClient } from "./client";

import { getServerUrl } from "../config";
import type { Organization } from "../types/supabase";

const Header = ({ organization }: { organization: undefined | Organization }) => {
  const fogbender = React.useRef(createNewFogbender());

  const signOutActionUrl = `${getServerUrl()}/auth/sign-out`;

  const { pathname } = useLocation();

  const { data: me } = useMe();

  const { data: fogbenderTokenData } = useQuery({
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

  React.useEffect(() => {
    if (
      fogbenderTokenData &&
      organization &&
      fogbenderTokenData.widgetId &&
      fogbenderTokenData.signatures &&
      me?.user_id &&
      me?.email
    ) {
      setFogbenderToken({
        userId: me.user_id,
        userName: me.email,
        userEmail: me.email,
        customerName: organization.name,
        customerId: organization.id,
        widgetId: fogbenderTokenData.widgetId,
        userJWT: fogbenderTokenData.signatures.userJWT,
      });
    }
  }, [organization, fogbenderTokenData]);

  return (
    <div className="bg-transparent sticky top-0 z-20">
      <div className="nav-container-blur bg-white absolute z-[-1] h-full w-full shadow-[0_2px_4px_rgba(0,0,0,.02),0_1px_0_rgba(0,0,0,.06)] dark:shadow-[0_-1px_0_rgba(255,255,255,.1)_inset] dark:bg-black dark:contrast-more:shadow-[0_0_0_1px_#000] contrast-more:shadow-[0_0_0_1px_#fff]"></div>
      <nav className="mx-auto flex h-16 items-center justify-end gap-5 pl-[max(env(safe-area-inset-left),1.5rem)] pr-[max(env(safe-area-inset-right),1.5rem)] text-black dark:text-white">
        <div className="flex items-center mr-auto gap-x-5">
          <a title="Home" href="/">
            <img src={SupafanaLogo} alt="Supafana logo" width={22} height={22} />
          </a>
        </div>
        {organization && pathname === "/support" && (
          <a
            className="text-sm font-medium flex items-center gap-1.5 link link-primary dark:link-secondary no-underline"
            href="/dashboard"
            title="Dashboard"
          >
            Dashboard
          </a>
        )}
        {organization && pathname === "/dashboard" && (
          <span className="flex items-center gap-0.5">
            <a
              className="text-sm font-medium flex items-center gap-1.5 link link-primary dark:link-secondary no-underline"
              href="/support"
              title="Support"
            >
              Support
            </a>
            <FogbenderProvider fogbender={fogbender.current}>
              <FogbenderConfig clientUrl="https://client.fogbender.com" token={fogbenderToken} />
              <FogbenderIsConfigured>
                <FogbenderHeadlessWidget />
                <FogbenderUnreadBadge />
              </FogbenderIsConfigured>
            </FogbenderProvider>
          </span>
        )}
        {organization && (
          <a
            className="text-sm font-medium flex items-center gap-1.5 link link-primary dark:link-secondary no-underline"
            href={`https://supabase.com/dashboard/org/${organization.id}`}
            title={`Open ${organization.name} in Supabase`}
          >
            <img src={SupabaseLogo} alt="Supabase logo" width={12} height={12} />
            {organization.name}
            <ExternalLink size={18} />
          </a>
        )}
        {organization && (
          <form
            onClick={e => {
              if (e.target instanceof HTMLElement) {
                queryClient.removeQueries();

                const form = e.target.closest("form");

                if (form) {
                  form.submit();
                }
              }
            }}
            method="post"
            action={signOutActionUrl}
          >
            <button
              className="btn btn-xs"
              type="submit"
              dangerouslySetInnerHTML={{ __html: nbsp("Sigh out") }}
            />
          </form>
        )}
        <ThemeController />
      </nav>
    </div>
  );
};

export default Header;
