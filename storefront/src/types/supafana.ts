export type Me = {
  email: string;
  user_id: string;
};

export type StripeCustomer = {
  id: string;
  email: string;
  name: string;
  created_ts_sec: number;
  portal_session_url: string;
  period_end_ts_sec: number;
  cancel_at_ts_sec: number | null;
  canceled_at_ts_sec: number | null;
  status: string;
  quantity: number;
};

export type Billing = {
  subscriptions: StripeCustomer[];
  price_per_instance: number;
  free_instances: number;
  paid_instances: number;
  unpaid_instances: number;
  used_instances: number;
  delinquent: boolean;
};
