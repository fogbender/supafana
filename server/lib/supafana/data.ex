defmodule Supafana.Data do
  @moduledoc """
  Helper module to use in models.
   * imports Ecto.Schema and Ecto.Changeset helpers
   * add new/1 and update/1,2 method to module. new and update works with Keywords, Maps and Structs.

  ### Example
      defmodule Supafana.Data.SomeModel do
        use Supafana.Data
        schema "some_model" do
          field(:some_field, :string)
        end
        def changeset(some_model, params \\ %{}) do
          some_model
          |> cast(params, [:some_field])
          |> validate_required([:some_field])
        end
      end

  Then it is possible to create new model changeset:

     Supafana.Data.SomeModel.new(some_field: "value")
      |> Supafana.Repo.insert!()

  Or update:

      old = Supafana.Repo.all(Supafana.Data.SomeModel) |> Enum.at(0)
      Supafana.Data.SomeModel.update(old, some_field: "newvalue")
      |> Supafana.Repo.update!()
  """
  @doc false
  defmacro __using__(_opts) do
    quote do
      alias Supafana.Data
      use Ecto.Schema
      import Ecto.Changeset
      @timestamps_opts [type: :utc_datetime_usec]

      def new(params), do: update(params)
      def update(params), do: update(struct(__MODULE__), params)
      def update(data, params) when is_list(params), do: update(data, Map.new(params))
      def update(data, params) when is_map(params), do: changeset(data, params)

      def validate_required_one(changeset, fields) do
        case Enum.filter(fields, &present?(changeset, &1)) do
          [] ->
            add_error(
              changeset,
              hd(fields),
              "One of these fields must be present: #{inspect(fields)}"
            )

          [_] ->
            changeset

          fields ->
            add_error(
              changeset,
              hd(fields),
              "Only one of these fields must be present: #{inspect(fields)}"
            )
        end
      end

      defp present?(changeset, field) do
        value = get_field(changeset, field)
        value && value != ""
      end
    end
  end
end
