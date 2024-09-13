defmodule Supafana.Z do
  @moduledoc """
  Convert a Z.Struct into a JSON object and typescript. Use
  """

  def generate_file() do
    file = "../storefront/src/types/z_types.ts" |> Path.expand()

    content =
      :code.all_loaded()
      |> Enum.map(fn {module, _} -> module end)
      |> Enum.filter(fn module ->
        module |> to_string |> String.starts_with?("Elixir.Supafana.Z.")
      end)
      |> Enum.sort()
      |> Enum.map(fn module -> module.to_typescript() end)

    file_content = """
    // This file is generated by Supafana.Z.generate_file()

    #{content |> Enum.join("\n")}
    """

    File.write!(file, file_content)

    "Generated #{content |> Enum.count()} typescript types in #{file}"
  end

  def name_to_typescript(name) do
    name
    |> to_string
    |> String.split(".")
    |> Enum.at(-1)
  end

  def field_to_typescript(name, {Z.String, [required: true]}) do
    "#{name}: string;"
  end

  def field_to_typescript(name, {Z.Boolean, [required: true]}) do
    "#{name}: boolean;"
  end

  def field_to_typescript(name, {Z.Integer, [required: true]}) do
    "#{name}: number;"
  end

  def field_to_typescript(name, {Z.Integer, []}) do
    "#{name}: null | number;"
  end

  def field_to_typescript(name, {Z.String, []}) do
    "#{name}: null | string;"
  end

  def field_to_typescript(name, {Z.String, [required: true, enum: [value]]}) do
    "#{name}: \"#{value}\";"
  end

  def field_to_typescript(name, {module, [required: true, cast: true]}) do
    "#{name}: #{name_to_typescript(module)};"
  end

  def field_to_typescript(name, {module, [required: true, cast: true, array: true]}) do
    "#{name}: #{name_to_typescript(module)}[];"
  end

  def field_to_typescript(field, value) do
    raise "Supafana.Z.field_to_typescript(#{inspect(field)}, #{inspect(value)}) is not implemented"
  end

  defmacro __using__(_) do
    quote do
      use Z.Struct

      alias Supafana.Z, as: Z

      @derive Jason.Encoder

      def to_json!(struct) do
        case validate(struct) do
          {:ok, value} -> value |> Jason.encode!()
          {:error, error} -> raise "Failed to validate #{inspect(error)}"
        end
      end

      def from_map!(map) do
        # let's not worry about speed for now 😅
        map |> Jason.encode!() |> from_json!()
      end

      def from_json(json) do
        case Jason.decode(json,
               keys: &Supafana.Utils.maybe_atom/1
             ) do
          {:ok, value} -> validate(value, [:cast])
          {:error, error} -> {:error, error}
        end
      end

      def from_json!(enum \\ []) do
        case from_json(enum) do
          {:ok, value} -> value
          {:error, error} -> raise "Failed to validate #{inspect(error)}"
        end
      end

      def to_typescript() do
        name = __MODULE__ |> to_string |> String.split(".") |> Enum.at(-1)
        # @z_fields
        fields = __z__(:fields) |> Enum.map(fn {k, v} -> Supafana.Z.field_to_typescript(k, v) end)
        out = ["export type #{name} = {\n  ", fields |> Enum.join("\n  "), "\n};\n"]
        IO.puts(out)
        out
      end
    end
  end
end

# TYPES

defmodule Supafana.Z.Grafana do
  use Supafana.Z

  schema do
    field(:id, :string, [:required])
    field(:supabase_id, :string, [:required])
    field(:org_id, :string, [:required])
    field(:plan, :string, [:required])
    field(:state, :string, [:required])
    field(:inserted_at, :integer, [:required])
    field(:updated_at, :integer, [:required])
    field(:first_start_at, :integer, [])
    field(:password, :string, [:required])
    field(:trial_length_min, :integer, [:required])
    field(:trial_remaining_msec, :integer, [])
    field(:stripe_subscription_id, :string, [])
    field(:max_client_connections, :integer, [:required])
  end
end

defmodule Supafana.Z.Subscription do
  use Supafana.Z

  schema do
    field(:id, :string, [:required])
    field(:created_ts_sec, :integer, [:required])
    field(:period_end_ts_sec, :integer, [:required])
    field(:cancel_at_ts_sec, :integer, [:required])
    field(:canceled_at_ts_sec, :integer, [:required])
    field(:status, :string, [:required])
    field(:quantity, :integer, [:required])
    field(:product_name, :string, [:required])
    field(:discount, :string, [:required])
  end
end

defmodule Supafana.Z.PaymentProfile do
  use Supafana.Z

  schema do
    field(:id, :string, [:required])
    field(:email, :string, [:required])
    field(:name, :string, [:required])
    field(:created_ts_sec, :integer, [:required])
    field(:is_default, :boolean, [:required])
    field(:subscriptions, Supafana.Z.Subscription, [:required, :cast, :array])
  end
end

defmodule Supafana.Z.Billing do
  use Supafana.Z

  schema do
    field(:delinquent, :boolean, [:required])
    field(:unpaid_instances, :integer, [:required])
    field(:paid_instances, :integer, [:required])
    field(:free_instances, :integer, [:required])
    field(:used_instances, :integer, [:required])
    field(:price_per_instance, :integer, [:required])
    field(:payment_profiles, Supafana.Z.PaymentProfile, [:required, :cast, :array])
  end
end

defmodule Supafana.Z.UserNotification do
  use Supafana.Z

  schema do
    field(:tx_emails, :boolean, [:required])
    field(:org_id, :string, [:required])
    field(:user_id, :string, [:required])
    field(:email, :string, [:required])
  end
end

defmodule Supafana.Z.EmailAlertContact do
  use Supafana.Z

  schema do
    field(:email, :string, [:required])
    field(:severity, :string, [:required])
  end
end

defmodule Supafana.Z.Alert do
  use Supafana.Z

  schema do
    field(:title, :string, [:required])
    field(:enabled, :boolean, [:required])
  end
end
