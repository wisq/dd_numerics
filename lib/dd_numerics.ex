defmodule DDNumerics do
  require Logger
  use Application

  def start(_type, _args) do
    children = supervise?() |> children_specs()
    opts = [strategy: :one_for_one, name: DDNumerics.Supervisor]

    Logger.info("dd_numerics starting up ...")
    Supervisor.start_link(children, opts)
  end

  defp supervise? do
    !iex_running?() && Application.get_env(:dd_numerics, :supervise, true)
  end

  defp children_specs(true) do
    [
      Plug.Cowboy.child_spec(scheme: :http, plug: DDNumerics.Router, options: [port: 4001])
    ]
  end

  defp children_specs(false) do
    []
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end
end
