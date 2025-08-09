defmodule KoombeaScraper.Workers.ScraperWorker do
  @moduledoc """
  An Oban worker responsible for scraping a stored page's content and updating
  it in the database with the results.

  If the page cannot be found, the worker simply returns `:ok` and does nothing.

  If scraping fails, the error tuple is returned so Oban can handle retries
  according to its configured retry policy.

  ## Arguments

  The job `args` must be a map with:

    * `"page_id"` - The integer ID of the page to scrape.

  ## Examples

      # Enqueue the worker
      %{"page_id" => 123}
      |> KoombeaScraper.Workers.ScraperWorker.new()
      |> Oban.insert()

  This will run `perform/1` asynchronously to scrape the page and store its links.
  """
  use Oban.Worker, queue: :scraper

  alias KoombeaScraper.Scraper
  alias KoombeaScraper.WebContent
  alias KoombeaScraper.WebContent.Page
  alias Phoenix.PubSub

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"page_id" => page_id} = _args}) do
    page = WebContent.get_page(page_id, preload: :links)

    with %Page{} <- page,
         {:ok, scrape_results} <- Scraper.scrape(page.url),
         {:ok, page} <- WebContent.update_page(page, Map.put(scrape_results, :status, :done)) do
      PubSub.broadcast(
        KoombeaScraper.PubSub,
        "user_pages:#{page.user_id}",
        {:page_processed_success, page}
      )

      :ok
    else
      nil ->
        :ok

      {:error, reason} ->
        {:ok, page} = WebContent.update_page(page, %{status: :failed})

        PubSub.broadcast(
          KoombeaScraper.PubSub,
          "user_pages:#{page.user_id}",
          {:page_processed_fail, page, reason}
        )

        {:error, reason}
    end
  end
end
