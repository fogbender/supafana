import React from "react";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";

dayjs.extend(relativeTime);

import { useQuery, useMutation } from "@tanstack/react-query";

import {
  apiServer,
  queryKeys,
  queryClient,
  useCheckoutSession,
  useSetStripeSessionId,
} from "./client";

import qs, { type ParseOptions } from "query-string";

import type { Organization } from "../types/supabase";

import type {
  PaymentProfile,
  Subscription as StripeCustomer,
  Billing as BillingT,
} from "../types/z_types";

function getQueryParam(query: string, key: string, options?: ParseOptions) {
  const value = qs.parse(query, options)[key];
  return typeof value === "string" ? value : undefined;
}

const Billing = ({ organization }: { organization: Organization }) => {
  const createCheckoutSessionMutation = useCheckoutSession();

  const stripeSessionId = getQueryParam(location.search, "session_id");

  const [pollBilling, setPollBilling] = React.useState(false);

  const { data: billing, isLoading: billingLoading } = useQuery({
    queryKey: queryKeys.billing(organization.id),
    queryFn: async () => {
      return await apiServer.url("/billing/billing").get().json<BillingT>();
    },
    refetchInterval: () => {
      if (pollBilling) {
        return 5000;
      } else {
        return false;
      }
    },
  });

  console.log(billing);

  const setStripeSessionIdMutation = useSetStripeSessionId(() => {
    queryClient.invalidateQueries({ queryKey: queryKeys.billing(organization.id) });

    const url = new URL(window.location.href);
    url.searchParams.delete("session_id");
    window.history.replaceState({}, document.title, url.toString());

    setPollBilling(true);
  });

  React.useEffect(() => {
    if (stripeSessionId) {
      setStripeSessionIdMutation.mutate(stripeSessionId);
    }
  }, [stripeSessionId]);

  const numSubscriptions =
    billing?.payment_profiles.map(pp => pp.subscriptions.length).reduce((acc, x) => acc + x, 0) ??
    0;

  const prevNumSubscriptions = React.useRef<number | null>(null);

  console.log({ numSubscriptions, prev: prevNumSubscriptions.current });

  // this is crazy - we should use db subscriptions instead
  React.useEffect(() => {
    if (billing) {
      if (pollBilling && prevNumSubscriptions.current === null) {
        prevNumSubscriptions.current = numSubscriptions;
      } else if (pollBilling && numSubscriptions > (prevNumSubscriptions.current ?? 0)) {
        setPollBilling(false);
        prevNumSubscriptions.current = null;
      }
    }
  }, [billing]);

  const isFree = numSubscriptions === 0;

  return (
    <div className="p-4">
      {billingLoading || pollBilling ? (
        <span className="loading loading-ring loading-lg text-accent" />
      ) : isFree ? (
        <div className="flex flex-col gap-2">
          <div>
            You are on the <span className="font-bold">Trial</span> plan
          </div>
          <button
            className="w-48 btn btn-accent btn-sm"
            type="button"
            onClick={() => createCheckoutSessionMutation.mutate()}
          >
            Upgrade to Pro
          </button>
          <a className="text-sm link link-primary dark:link-secondary no-underline" href="/pricing">
            See pricing options
          </a>
        </div>
      ) : (
        /*
          Why a list here? Basically, it's easier to support multiple subscriptions than to
          enfore a single one. Also, say the person who managed the old subscription left -
          adding another subscription and letting the old one lapse is the simplest way to
          ensure continuity.
        */
        <div className="flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <div className="flex flex-col gap-2">
              {billing?.payment_profiles.map(pp => (
                <div key={pp.id} className="p-4 border rounded-lg">
                  <PaymentProfile pp={pp} b={billing} />
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const PaymentProfile = ({ pp, b }: { pp: PaymentProfile; b: BillingT }) => {
  return (
    <table className="text-gray-200 dark:text-gray-700 bg-dots table">
      <tbody>
        <tr>
          <RowHeader>Email</RowHeader>
          <RowBody>{pp.email}</RowBody>
        </tr>
        <tr>
          <RowHeader>Name</RowHeader>
          <RowBody>{pp.name}</RowBody>
        </tr>
        <tr>
          <td colSpan={2}>
            <div className="flex flex-col gap-2">
              <div className="font-semibold text-black dark:text-white">Subscriptions</div>
              <div>
                {pp.subscriptions.map(s => (
                  <div key={s.id} className="p-4 border rounded-lg bg-white dark:bg-black">
                    <Subscription s={s} b={b} />
                  </div>
                ))}
              </div>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  );
};

export const Subscription = ({ s, b }: { s: StripeCustomer; b: BillingT }) => {
  const createPortalSessionMutation = useMutation({
    mutationFn: (): Promise<{ url: string }> => {
      return apiServer
        .url("/billing/create-portal-session")
        .post({ stripe_subscription_id: s.id })
        .json<{ url: string }>();
    },
    onSuccess: res => {
      const { url } = res;

      window.location.href = url;
    },
  });

  return (
    <table className="text-gray-200 dark:text-gray-700 bg-dots table">
      <tbody>
        <tr>
          <RowHeader>Product</RowHeader>
          <RowBody>{`${s.product_name}`}</RowBody>
        </tr>
        <tr>
          <RowHeader>Quantity</RowHeader>
          <RowBody>{`${s.quantity}`}</RowBody>
        </tr>
        <tr>
          <RowHeader>Cost per month</RowHeader>
          <RowBody>
            <span>${`${(b.price_per_instance / 100) * s.quantity}`}</span>
          </RowBody>
        </tr>
        <tr>
          <RowHeader>Subscription status</RowHeader>
          <RowBody>
            <span className="inline-block first-letter:capitalize">{s.status}</span>
          </RowBody>
        </tr>
        <tr>
          <RowHeader>Customer since</RowHeader>
          <RowBody>
            <>
              <span className="inline-block first-letter:capitalize">
                {dayjs(s.created_ts_sec * 1000).fromNow()}
              </span>{" "}
              ({dayjs(s.created_ts_sec * 1000).format("YYYY-MM-DD hh:mm:ss")})
            </>
          </RowBody>
        </tr>
        {!s.cancel_at_ts_sec && (
          <tr>
            <RowHeader>Renews</RowHeader>
            <RowBody>
              <>
                <span className="inline-block first-letter:capitalize">
                  {dayjs(s.period_end_ts_sec * 1000).fromNow()}
                </span>{" "}
                ({dayjs(s.period_end_ts_sec * 1000).format("YYYY-MM-DD hh:mm:ss")})
              </>
            </RowBody>
          </tr>
        )}
        {s.canceled_at_ts_sec && (
          <tr>
            <RowHeader>Subscription cancelled</RowHeader>
            <RowBody>
              <>
                {dayjs(s.canceled_at_ts_sec * 1000).fromNow()} (
                {dayjs(s.canceled_at_ts_sec * 1000).format("YYYY-MM-DD hh:mm:ss")})
              </>
            </RowBody>
          </tr>
        )}
        {s.cancel_at_ts_sec && (
          <tr>
            <RowHeader>Subscription expires</RowHeader>
            <RowBody>
              <>
                {dayjs(s.cancel_at_ts_sec * 1000).fromNow()} (
                {dayjs(s.cancel_at_ts_sec * 1000).format("YYYY-MM-DD hh:mm:ss")})
              </>
            </RowBody>
          </tr>
        )}
        <tr>
          <td colSpan={2}>
            <button
              className="btn btn-link link-primary dark:link-secondary !no-underline h-4 min-h-min px-0"
              onClick={() => createPortalSessionMutation.mutate()}
            >
              Manage subscription
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  );
};

const RowHeader = ({ children }: { children: JSX.Element | string }) => {
  return (
    <td>
      <span className="text-gray-500 dark:text-gray-300">{children}</span>
    </td>
  );
};

const RowBody = ({ children }: { children: JSX.Element | string }) => {
  return (
    <td>
      <span className="text-black dark:text-white font-medium">{children}</span>
    </td>
  );
};

export default Billing;
