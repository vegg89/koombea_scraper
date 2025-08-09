defmodule KoombeaScraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KoombeaScraperWeb.Telemetry,
      KoombeaScraper.Repo,
      {DNSCluster, query: Application.get_env(:koombea_scraper, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: KoombeaScraper.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: KoombeaScraper.Finch},
      {Oban, Application.fetch_env!(:koombea_scraper, Oban)},
      # Start a worker by calling: KoombeaScraper.Worker.start_link(arg)
      # {KoombeaScraper.Worker, arg},
      # Start to serve requests, typically the last entry
      KoombeaScraperWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KoombeaScraper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KoombeaScraperWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
