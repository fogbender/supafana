import React from "react";

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

      console.log({ url });

      window.location.href = url;
    },
  });

  const stripeSessionId = getQueryParam(location.search, "session_id");

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
  });

  const isFree = billing?.subscriptions?.length === 0;

  return (
    <div>
      {billingLoading ? (
        <span className="loading loading-ring loading-lg text-accent" />
      ) : isFree ? (
        <div className="flex flex-col gap-2">
          <div>
            You are on the <span className="font-bold">Hobby</span> plan
          </div>
          <button
            className="w-32 btn btn-accent btn-sm"
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
        <></>
      )}
    </div>
  );
};

export default Billing;
