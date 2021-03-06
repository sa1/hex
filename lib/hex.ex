defmodule Hex do
  use Application

  def start do
    {:ok, _} = Application.ensure_all_started(:hex)
  end

  def stop do
    case Application.stop(:hex) do
      :ok -> :ok
      {:error, {:not_started, :hex}} -> :ok
    end
  end

  def start(_, _) do
    import Supervisor.Spec

    Mix.SCM.append(Hex.SCM)
    Mix.RemoteConverger.register(Hex.RemoteConverger)

    start_httpc()

    children = [
      worker(Hex.State, []),
      worker(Hex.Registry, []),
      worker(Hex.Parallel, [:hex_fetcher, [max_parallel: 8]]),
    ]

    opts = [strategy: :one_for_one, name: Hex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def version,        do: unquote(Mix.Project.config[:version])
  def elixir_version, do: unquote(System.version)
  def otp_version,    do: unquote(Hex.Utils.otp_version)

  defp start_httpc() do
    :inets.start(:httpc, profile: :hex)
    opts = [
      max_sessions: 4,
      max_keep_alive_length: 4,
      keep_alive_timeout: 120_000,
      max_pipeline_length: 4,
      pipeline_timeout: 60_000
    ]
    :httpc.set_options(opts, :hex)
  end
end
