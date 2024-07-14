import React from "react";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";

dayjs.extend(relativeTime);

import { useMutation, useQuery } from "@tanstack/react-query";

import { apiServer, queryKeys, queryClient } from "./client";

import qs, { type ParseOptions } from "query-string";

import type { Organization } from "../types/supabase";
import type { StripeCustomer, Billing as BillingT } from "../types/supafana";

function getQueryParam(query: string, key: string, options?: ParseOptions) {
  const value = qs.parse(query, options)[key];
  return typeof value === "string" ? value : undefined;
}

const Billing = ({ organization }: { organization: Organization }) => {
  const createCheckoutSessionMutation = useMutation({
    mutationFn: () => {
      return apiServer
        .url(`/billing/create-checkout-session`)
        .post({
          instances: 1,
        })
        .json<{ url: string }>();
    },
    onSuccess: res => {
      const { url } = res;

      window.location.href = url;
    },
  });

  const stripeSessionId = getQueryParam(location.search, "session_id");

  const [pollSubscriptions, setPollSubscriptions] = React.useState(false);

  console.log({ pollSubscriptions });

  const setStripeSessionIdMutation = useMutation({
    mutationFn: async (session_id: string) => {
      return apiServer
        .url(`/billing/set-stripe-session-id`)
        .post({
          session_id,
        })
        .json<StripeCustomer>();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.billing(organization.id) });
      setPollSubscriptions(true);
    },
  });

  React.useEffect(() => {
    if (stripeSessionId) {
      setStripeSessionIdMutation.mutate(stripeSessionId);
    }
  }, [stripeSessionId]);

  const { data: billing, isLoading: billingLoading } = useQuery({
    queryKey: queryKeys.billing(organization.id),
    queryFn: async () => {
      return await apiServer.url("/billing/subscriptions").get().json<BillingT>();
    },
    refetchInterval: () => {
      if (pollSubscriptions) {
        return 2000;
      } else {
        return false;
      }
    },
  });

  React.useEffect(() => {
    if (pollSubscriptions && billing?.subscriptions.length) {
      setPollSubscriptions(false);
    }
  }, [billing]);

  const isFree = billing?.subscriptions?.length === 0;

  return (
    <div className="p-4">
      {billingLoading || pollSubscriptions ? (
        <span className="loading loading-ring loading-lg text-accent" />
      ) : isFree ? (
        <div className="flex flex-col gap-2">
          <div>
            You are on the <span className="font-bold">Hobby</span> plan
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
        billing?.subscriptions.map(s => (
          <Subscription s={s} price={billing.price_per_instance} key={s.id} />
        ))
      )}
    </div>
  );
};

const Subscription = ({ s, price }: { s: StripeCustomer; price: number }) => {
  return (
    <table className="text-gray-200 dark:text-gray-700 bg-dots table">
      <tbody>
        <tr>
          <RowHeader>Email</RowHeader>
          <RowBody>{s.email}</RowBody>
        </tr>
        <tr>
          <RowHeader>Name</RowHeader>
          <RowBody>{s.name}</RowBody>
        </tr>
        <tr>
          <RowHeader>Number of Grafana instances</RowHeader>
          <RowBody>{`${s.quantity}`}</RowBody>
        </tr>
        <tr>
          <RowHeader>Cost per month</RowHeader>
          <RowBody>
            <span>${`${(price / 100) * s.quantity}`}</span>
          </RowBody>
        </tr>
        <tr>
          <RowHeader>Subscription status</RowHeader>
          <RowBody>{s.status}</RowBody>
        </tr>
        <tr>
          <RowHeader>Customer since</RowHeader>
          <RowBody>
            <>
              {dayjs(s.created_ts_sec * 1000).fromNow()} (
              {dayjs(s.created_ts_sec * 1000).format("YYYY-MM-DD hh:mm:ss")})
            </>
          </RowBody>
        </tr>
        {!s.cancel_at_ts_sec && (
          <tr>
            <RowHeader>Renews</RowHeader>
            <RowBody>
              <>
                {dayjs(s.period_end_ts_sec * 1000).fromNow()} (
                {dayjs(s.period_end_ts_sec * 1000).format("YYYY-MM-DD hh:mm:ss")})
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
          <td>
            <a
              target="_blank"
              className="break-all text-sm font-medium link link-primary dark:link-secondary no-underline"
              href={s.portal_session_url}
            >
              Manage subscription
            </a>
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
