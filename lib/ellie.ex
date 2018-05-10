defmodule Ellie do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    if Application.get_env(:ellie, :env) == :prod do
      merge_config :ellie, EllieWeb.Endpoint,
        secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE"),
        url: [host: url_host()]

      merge_config :ellie, Ellie.Repo,
        url: System.get_env("DATABASE_URL")
    end

    children = [
      supervisor(Elm, []),
      supervisor(Ellie.Repo, []),
      supervisor(EllieWeb.Endpoint, []),
      supervisor(Absinthe.Subscription, [EllieWeb.Endpoint]),
      worker(Ellie.Adapters.Embed.Local, []),
      worker(Ellie.Adapters.Workspace.Local, []),
      worker(Ellie.Scheduler, []),
      worker(Task, [&Ellie.Domain.Search.reload/0], restart: :temporary)
    ]


    opts = [strategy: :one_for_one, name: Ellie.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    EllieWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp url_host() do
    "NOW_URL"
    |> System.get_env()
    |> with_default("0.0.0.0")
    |> String.replace("https://", "")
    |> String.replace("http://", "")
  end

  defp with_default(nil, a), do: a
  defp with_default(a, _), do: a

  defp merge_config(app, key, keywords) do
    env = Application.get_env(app, key)
    updated_env = Keyword.merge(env, keywords)
    Application.put_env(app, key, updated_env)
  end
end
