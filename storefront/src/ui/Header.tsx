import { useLocation } from "react-router-dom";
import { HiExternalLink as ExternalLink } from "react-icons/hi";

import SupabaseLogo from "./landing/assets/supabase-logo-icon.svg?url";
import SupafanaLogo from "./landing/assets/logo.svg?url";
import ThemeController from "./ReactThemeController";

import { getServerUrl } from "../config";
import type { Organization } from "../types/supabase";

const Header = ({ organization }: { organization: undefined | Organization }) => {
  const signOutActionUrl = `${getServerUrl()}/auth/sign-out`;

  const { pathname } = useLocation();

  return (
    <div className="bg-transparent sticky top-0 z-20">
      <div className="nav-container-blur bg-white absolute z-[-1] h-full w-full shadow-[0_2px_4px_rgba(0,0,0,.02),0_1px_0_rgba(0,0,0,.06)] dark:shadow-[0_-1px_0_rgba(255,255,255,.1)_inset] dark:bg-black dark:contrast-more:shadow-[0_0_0_1px_#000] contrast-more:shadow-[0_0_0_1px_#fff]"></div>
      <nav className="mx-auto flex h-16 max-w-[90rem] items-center justify-end gap-5 pl-[max(env(safe-area-inset-left),1.5rem)] pr-[max(env(safe-area-inset-right),1.5rem)] text-black dark:text-white">
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
          <a
            className="text-sm font-medium flex items-center gap-1.5 link link-primary dark:link-secondary no-underline"
            href="/support"
            title="Support"
          >
            Support
          </a>
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
  );
};

export default Header;
