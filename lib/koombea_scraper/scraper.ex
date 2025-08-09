defmodule KoombeaScraper.Scraper do
  @moduledoc """
  Responsible for fetching and parsing HTML content from a web page.
  Extracts the title and all <a> tag links.
  """
  @type link() :: %{title: binary(), links: [binary()]}

  @doc """
  Fetches and parses the HTML content of the given URL, returning the page title
  and all `<a>` tag links found.

  The function accepts either a binary URL (`"https://example.com"`) or a parsed
  `URI.t()`.

  Relative URLs in the page are merged with the main page URL. Non-HTTP(S) links
  like `mailto:` are preserved as-is.

  ## Examples

      iex> scrape("https://elixir-lang.org")
      {:ok, %{title: "Elixir", links: [%{url: "https://elixir-lang.org/docs", name: "Docs"}, ...]}}

      iex> scrape(URI.parse("https://elixir-lang.org"))
      {:ok, %{title: "Elixir", links: [...]}}

      iex> scrape("invalid_url")
      {:error, reason}

  Returns `{:ok, result}` on success or `{:error, reason}` if fetching or parsing fails.

  """
  @spec scrape(binary() | URI.t()) :: {:ok, link()} | {:error, any()}
  def scrape(url) when is_binary(url), do: scrape(URI.parse(url))

  def scrape(main_uri) do
    with {:ok, html} <- fetch_html(main_uri),
         {:ok, doc} <- Floki.parse_document(html) do
      {:ok,
       %{
         title: get_title(doc),
         links: extract_links(main_uri, doc)
       }}
    end
  end

  defp fetch_html(uri) do
    request = Finch.build(:get, uri)

    case Finch.request(request, KoombeaScraper.Finch) do
      {:ok, %{body: body}} ->
        {:ok, body}

      error ->
        error
    end
  end

  defp get_title(doc) do
    doc
    |> Floki.find("title")
    |> Floki.text()
    |> clean_text()
  end

  defp extract_links(main_url, doc) do
    doc
    |> Floki.find("a[href]")
    |> Enum.map(fn anchor_tag ->
      normalized_href =
        anchor_tag
        |> Floki.attribute("href")
        |> hd()
        |> normalize_url(main_url)

      clean_name =
        anchor_tag
        |> Floki.children()
        |> Floki.raw_html()
        |> clean_text()

      %{url: normalized_href, name: clean_name}
    end)
  end

  defp normalize_url(href, main_url) do
    cond do
      String.starts_with?(href, ["http://", "https://", "mailto:"]) ->
        href

      true ->
        main_url
        |> URI.parse()
        |> URI.merge(href)
        |> to_string()
    end
  end

  defp clean_text(text) do
    text
    |> String.replace(~r/\\[ntr"\\]/, "")
    |> String.replace(~r/[\n\t\r]+/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
