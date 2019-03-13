defmodule DDNumerics.Datadog.URI do
  defp api_key do
    Application.get_env(:dd_numerics, :datadog_api_key) ||
      System.get_env("DD_API_KEY") ||
      raise "Must set DD_API_KEY"
  end

  defp application_key do
    Application.get_env(:dd_numerics, :datadog_application_key) ||
      System.get_env("DD_APPLICATION_KEY") ||
      raise "Must set DD_APPLICATION_KEY"
  end

  defp default_params do
    %{
      api_key: api_key(),
      application_key: application_key()
    }
  end

  def now do
    DateTime.utc_now()
    |> DateTime.to_unix()
  end

  def datadog_uri(path, params \\ []) do
    uri_params = Map.merge(default_params(), Map.new(params))

    %URI{
      scheme: "https",
      host: "app.datadoghq.com",
      path: Path.join("/api", path),
      query: URI.encode_query(uri_params)
    }
  end
end
