defmodule Supafana.Azure.TemplateSpec do
  @template_group "supafana-common-rg"
  @template_name "grafana-template"
  @template_version "2024.9.1"

  def grafana() do
    subscription_id = Supafana.env(:azure_subscription_id)

    "/subscriptions/#{subscription_id}/resourceGroups/#{@template_group}/providers/Microsoft.Resources/templateSpecs/#{@template_name}/versions/#{@template_version}"
  end
end
