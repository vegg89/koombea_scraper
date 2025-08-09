defmodule KoombeaScraper.Repo do
  use Ecto.Repo,
    otp_app: :koombea_scraper,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 8
end
