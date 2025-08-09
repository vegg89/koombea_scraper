defmodule KoombeaScraper.WebContent do
  @moduledoc """
  The WebContent context.
  """
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias KoombeaScraper.Accounts.User
  alias KoombeaScraper.Repo
  alias KoombeaScraper.WebContent.Link
  alias KoombeaScraper.WebContent.Page

  @doc """
  Returns the list of user pages.

  ## Examples

      iex> list_pages(%User{})
      [%Page{}, ...]

  """
  @spec list_user_pages(User.t()) :: [Page.t()]
  @spec list_user_pages(User.t(), Keyword.t()) :: [Page.t()]
  def list_user_pages(user, opts \\ []) do
    preload = opts[:preload] || []

    Page
    |> Page.where_user(user)
    |> preload(^preload)
    |> Repo.all()
  end

  @doc """
  Returns the list of user pages paginated.

  ## Examples

      iex> list_pages(%User{})
      [%Page{}, ...]

  """
  @spec paginate_user_pages(User.t()) :: Scrivener.Page.t(Page.t())
  @spec paginate_user_pages(User.t(), Keyword.t()) :: Scrivener.Page.t(Page.t())
  def paginate_user_pages(user, opts \\ []) do
    preload = opts[:preload] || []

    Page
    |> Page.where_user(user)
    |> preload(^preload)
    |> order_by([p], desc: :inserted_at)
    |> Repo.paginate(opts)
  end

  @doc """
  Gets a single user page.

  Returns `nil` if the Page does not exist.

  ## Examples

      iex> get_user_page(%User{}, 123)
      %Page{}

      iex> get_user_page(%User{}, 456)
      nil

  """
  @spec get_user_page(User.t(), integer() | binary()) :: Page.t() | nil
  @spec get_user_page(User.t(), integer() | binary(), Keyword.t()) :: Page.t() | nil
  def get_user_page(user, id, opts \\ []) do
    preload = opts[:preload] || []

    Page
    |> Page.where_user(user)
    |> preload(^preload)
    |> Repo.get(id)
  end

  @doc """
  Gets a single page.

  Returns `nil` if the Page does not exist.

  ## Examples

      iex> get_page(123)
      %Page{}

      iex> get_page(456)
      nil

  """
  @spec get_page(integer() | binary()) :: Page.t() | nil
  @spec get_page(integer() | binary(), Keyword.t()) :: Page.t() | nil
  def get_page(id, opts \\ []) do
    preload = opts[:preload] || []

    Page
    |> preload(^preload)
    |> Repo.get(id)
  end

  @doc """
  Creates a page.

  ## Examples

      iex> create_page(%User{}, %{field: value})
      {:ok, %Page{}}

      iex> create_page(%User{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_user_page(User.t()) :: {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  @spec create_user_page(User.t(), map()) :: {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def create_user_page(user, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put("user_id", user.id)
      |> Map.put("status", :in_progress)

    Multi.new()
    |> Multi.insert(:page, Page.changeset(%Page{}, attrs))
    |> Multi.run(:enqueue_scraper, fn _repo, %{page: page} ->
      enqueue_scraper_worker(page)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{page: page}} ->
        {:ok, page}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  @doc """
  Creates a page.

  ## Examples

      iex> create_page(%{field: value})
      {:ok, %Page{}}

      iex> create_page(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_page(attrs \\ %{}) do
    %Page{}
    |> Page.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a page.

  ## Examples

      iex> update_page(page, %{field: new_value})
      {:ok, %Page{}}

      iex> update_page(page, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_page(Page.t(), map()) :: {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def update_page(%Page{} = page, attrs) do
    page
    |> Page.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking page changes.

  ## Examples

      iex> change_page(page)
      %Ecto.Changeset{data: %Page{}}

  """
  @spec change_page(Page.t()) :: Ecto.Changeset.t()
  @spec change_page(Page.t(), map()) :: Ecto.Changeset.t()
  def change_page(%Page{} = page, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end

  @doc """
  Enqueues a background scraping job for the given `page`.

  Returns `{:ok, job}` if the job was successfully enqueued, or
  `{:error, reason}` if the insertion into the job queue failed.

  ## Examples

      iex> enqueue_scraper_worker(%Page{id: 1})
      {:ok, %Oban.Job{}}

      iex> enqueue_scraper_worker(%Page{id: nil})
      {:error, changeset}

  """
  @spec enqueue_scraper_worker(Page.t()) :: {:ok, Oban.Job.t()} | {:error, any()}
  def enqueue_scraper_worker(page) do
    %{"page_id" => page.id}
    |> KoombeaScraper.Workers.ScraperWorker.new()
    |> Oban.insert()
  end

  @doc """
  Creates a link.

  ## Examples

      iex> create_link(%{field: value})
      {:ok, %Link{}}

      iex> create_link(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_link(attrs \\ %{}) do
    %Link{}
    |> Link.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of user pages paginated.

  ## Examples

      iex> paginate_page_links(%Page{})
      [%Page{}, ...]

  """
  @spec paginate_page_links(Page.t()) :: Scrivener.Page.t(Page.t())
  @spec paginate_page_links(Page.t(), Keyword.t()) :: Scrivener.Page.t(Link.t())
  def paginate_page_links(page, opts \\ []) do
    preload = opts[:preload] || []

    Link
    |> Link.where_page(page)
    |> preload(^preload)
    |> order_by([p], desc: :inserted_at)
    |> Repo.paginate(opts)
  end
end
