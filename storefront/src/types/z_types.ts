// This file is generated by Supafana.Z.generate_file()

export type Billing = {
  delinquent: boolean;
  unpaid_instances: number;
  paid_instances: number;
  free_instances: number;
  used_instances: number;
  price_per_instance: number;
  subscriptions: Subscription[];
};

export type Grafana = {
  id: string;
  supabase_id: string;
  org_id: string;
  plan: string;
  state: string;
  inserted_at: number;
};

export type Subscription = {
  id: string;
  email: string;
  name: string;
  created_ts_sec: number;
  portal_session_url: string;
  period_end_ts_sec: number;
  cancel_at_ts_sec: number;
  canceled_at_ts_sec: number;
  status: string;
  quantity: number;
};
