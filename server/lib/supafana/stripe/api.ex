defmodule Supafana.Stripe.Api do
  require Logger

  @stripe_base_url "https://api.stripe.com"

  def check_access() do
    r =
      client()
      |> Tesla.get("/v1/customers")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def create_checkout_session(quantity, metadata \\ %{}) do
    params = %{
      "line_items[0][price]" => Supafana.env(:stripe_price_id),
      "line_items[0][quantity]" => quantity,
      "mode" => "subscription",
      "success_url" =>
        "#{Supafana.env(:supafana_storefront_url)}/dashboard?session_id={CHECKOUT_SESSION_ID}",
      "cancel_url" => "#{Supafana.env(:supafana_storefront_url)}/dashboard"
    }

    params =
      case metadata do
        nil ->
          params

        map when is_map(map) ->
          params
          |> Map.merge(
            map
            |> Enum.reduce(%{}, fn {k, v}, acc ->
              acc |> Map.merge(%{"metadata[#{k}]" => v})
            end)
          )
      end

    r =
      post(
        "/v1/checkout/sessions",
        params
      )

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        body
    end
  end

  def get_checkout_session(session_id) do
    r =
      client()
      |> Tesla.get("/v1/checkout/sessions/#{session_id}")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def get_customer(customer_id) do
    r =
      client()
      |> Tesla.get("/v1/customers/#{customer_id}")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def get_customer_payment_methods(customer_id) do
    r =
      client()
      |> Tesla.get("/v1/customers/#{customer_id}/payment_methods")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def get_subscriptions(customer_id) do
    r =
      client()
      |> Tesla.get("/v1/subscriptions",
        query: [
          customer: customer_id,
          expand: ["data.plan.product"]
        ]
      )

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def get_subscription(subscription_id) do
    r =
      client()
      |> Tesla.get("/v1/subscriptions/#{subscription_id}")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def create_portal_session(customer_id) do
    r =
      post(
        "/v1/billing_portal/sessions",
        %{
          "customer" => customer_id,
          "return_url" => "#{Supafana.env(:supafana_storefront_url)}/dashboard"
        }
      )

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        body
    end
  end

  def set_subscription_plan_quantity(subscription_item_id, quantity) do
    r =
      post(
        "/v1/subscription_items/#{subscription_item_id}",
        %{
          "quantity" => quantity,
          "proration_behavior" => "always_invoice"
        }
      )

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def get_price() do
    r =
      client()
      |> Tesla.get("/v1/prices/#{Supafana.env(:stripe_price_id)}")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def delete_customer(customer_id) do
    r = client() |> Tesla.delete("/v1/customers/#{customer_id}")

    case r do
      {:ok, %Tesla.Env{status: 200}} ->
        :ok
    end
  end

  def delete_subscription(subscription_id, prorate \\ true) do
    r =
      client()
      |> Tesla.delete("/v1/subscriptions/#{subscription_id}",
        query: [
          invoice_now: true,
          prorate: prorate
        ]
      )

    case r do
      {:ok, %Tesla.Env{status: 200}} ->
        :ok
    end
  end

  defp post(path, map), do: client() |> Tesla.post(path, URI.encode_query(map))

  defp client() do
    base_url = {Tesla.Middleware.BaseUrl, @stripe_base_url}
    json = Tesla.Middleware.JSON
    form = Tesla.Middleware.FormUrlencoded
    query = Tesla.Middleware.Query
    auth = {Tesla.Middleware.BasicAuth, %{username: Supafana.env(:stripe_secret_key)}}

    headers =
      {Tesla.Middleware.Headers,
       [
         {
           "accept",
           "application/json"
         }
       ]}

    retry =
      {Tesla.Middleware.Retry,
       [
         delay: 1000,
         max_retries: 5,
         max_delay: 4_000,
         should_retry: fn
           {:ok, %{status: status}} when status in [500] -> true
           {:ok, _} -> false
           {:error, :timeout} -> true
           {:error, _} -> false
         end
       ]}

    middleware = [base_url, json, form, query, headers, auth, retry]

    Tesla.client(middleware)
  end
end
