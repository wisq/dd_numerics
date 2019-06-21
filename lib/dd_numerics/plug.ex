defmodule DDNumerics.Plug do
  use Plug.Router
  alias DDNumerics.Metrics

  plug(:match)
  plug(:dispatch)

  get "/metric/:name" do
    case Metrics.get(name) do
      {:ok, metric} ->
        metric
        |> Metrics.fetch()
        |> send_json(conn)

      :error ->
        not_found(conn)
    end
  end

  match _ do
    not_found(conn)
  end

  defp not_found(conn) do
    send_resp(conn, 404, "not found")
  end

  defp send_json(data, conn) do
    send_resp(conn, 200, Poison.encode!(data))
  end
end
