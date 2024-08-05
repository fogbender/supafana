// This file is generated by Supafana.Z.generate_file()

export type Billing = {
  delinquent: boolean;
  unpaid_instances: number;
  paid_instances: number;
  free_instances: number;
  used_instances: number;
  price_per_instance: number;
  payment_profiles: PaymentProfile[];
};

export type Grafana = {
  id: string;
  supabase_id: string;
  org_id: string;
  plan: string;
  state: string;
  inserted_at: number;
  updated_at: number;
  first_start_at: null | number;
  password: string;
  trial_length_min: number;
  trial_remaining_msec: null | number;
  stripe_subscription_id: null | string;
};

export type PaymentProfile = {
  id: string;
  email: string;
  name: string;
  created_ts_sec: number;
  is_default: boolean;
  subscriptions: Subscription[];
};

export type Subscription = {
  id: string;
  created_ts_sec: number;
  period_end_ts_sec: number;
  cancel_at_ts_sec: number;
  canceled_at_ts_sec: number;
  status: string;
  quantity: number;
  product_name: string;
};
