# KoombeaScraper

KoombeaScraper is a Phoenix application that allows users to register, submit URLs for scraping, and view the extracted links from those pages.

Scraping is performed in the background using Oban jobs, and results are updated in real-time via LiveView.

## Software used for development

I used asdf to install Elixir and Erlang versions. If you are using asdf you just need to run `asdf install` to install the required versions.

  * Elixir 1.18.4
  * Erlang 28.0.2

You don't need to install Phoenix explicitly, but if you want to install you can do it by running `mix archive.install hex phx_new`

  * Phoenix 1.7.21

Postgres is needed to use the application.

  * Postgres 17

## Installation

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

You will need to [`create an account`](http://localhost:4000/users/register) in order to use the application


## Libraries Used

  * ### Oban
      
    Used for background job processing. Handles scraping jobs asynchronously so slow or failing pages don't block the main application flow.

  * ### Scrivener

    Used for pagination of database queries. Provides Repo.paginate/2 to efficiently display large lists of pages and links in manageable chunks.

  * ### Floki

    Used to parse and query HTML documents. Extracts the `<title>` and `<a>` tag information (URLs and link names) from scraped pages.

  * ### Finch

    Used as the HTTP client for fetching HTML content from URLs before parsing them with Floki.

  * ### phx.gen.auth

    Used to scaffold authentication (registration, login, logout) for users with secure password hashing and session management.

  * ### Phoenix LiveView

    Used for building user interfaces without writing JavaScript. In this app, LiveView updates the UI when new pages are scraped or pagination changes.

  * ### Mock

    A library used for mocking calls to third party or external apps for Elixir projects. In this app was used to mock http requests to page urls
    and allow us to create tests for Scraper module.

