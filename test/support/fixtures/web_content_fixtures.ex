defmodule KoombeaScraper.WebContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KoombeaScraper.WebContent` context.
  """

  @doc """
  Generate a unique page url.
  """
  def unique_page_url, do: "http://some_url#{System.unique_integer([:positive])}"

  @doc """
  Generate a page.
  """
  def page_fixture(attrs \\ %{}) do
    {:ok, page} =
      attrs
      |> Enum.into(%{
        status: :in_progress,
        title: "some title",
        url: unique_page_url()
      })
      |> KoombeaScraper.WebContent.create_page()

    page
  end

  @doc """
  Generate a link.
  """
  def link_fixture(attrs \\ %{}) do
    {:ok, link} =
      attrs
      |> Enum.into(%{
        name: "some name",
        url: "some url"
      })
      |> KoombeaScraper.WebContent.create_link()

    link
  end
end
