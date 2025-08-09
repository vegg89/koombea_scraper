defmodule KoombeaScraper.ScraperTest do
  use ExUnit.Case, async: true

  import Mock

  alias KoombeaScraper.Scraper

  @html """
  <html>
    <head><title>Test Page</title></head>
    <body>
      <a href="http://external.com">External Link</a>
      <a href="https://external.com">Secure External Link</a>
      <a href="/relative/path">Relative Link</a>
      <a href="#section">Page section</a>
      <a href="mailto:someone@example.com">Email Link</a>
    </body>
  </html>
  """

  test "scrape/1 returns parsed title and normalized links" do
    with_mock Finch,
      request: fn _req, _name -> {:ok, %{body: @html}} end,
      build: fn method, url -> %{method: method, url: url, headers: []} end do
      assert {:ok, %{title: "Test Page", links: links}} = Scraper.scrape("https://example.com")

      assert Enum.any?(links, fn %{url: url, name: name} ->
               url == "http://external.com" and name == "External Link"
             end)

      assert Enum.any?(links, fn %{url: url, name: name} ->
               url == "https://external.com" and name == "Secure External Link"
             end)

      assert Enum.any?(links, fn %{url: url, name: name} ->
               url == "https://example.com/relative/path" and name == "Relative Link"
             end)

      assert Enum.any?(links, fn %{url: url, name: name} ->
               url == "https://example.com#section" and name == "Page section"
             end)

      assert Enum.any?(links, fn %{url: url, name: name} ->
               url == "mailto:someone@example.com" and name == "Email Link"
             end)
    end
  end

  test "scrape/1 returns error tuple if Finch returns error" do
    with_mock Finch,
      request: fn _req, _name -> {:error, :timeout} end,
      build: fn method, url -> %{method: method, url: url, headers: []} end do
      assert {:error, :timeout} = Scraper.scrape("https://example.com")
    end
  end
end
