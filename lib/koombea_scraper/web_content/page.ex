defmodule KoombeaScraper.WebContent.Page do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias KoombeaScraper.Accounts.User
  alias KoombeaScraper.WebContent.Link

  @type t() :: %__MODULE__{}

  schema "pages" do
    field :status, Ecto.Enum, values: [:in_progress, :done, :failed]
    field :title, :string
    field :url, :string

    belongs_to :user, User

    has_many :links, Link

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:url, :title, :status, :user_id])
    |> cast_assoc(:links)
    |> validate_required([:url, :status, :user_id])
    |> validate_url(:url)
    |> unique_constraint([:url, :user_id], message: "has already been added.")
  end

  @spec where_user(Ecto.Queryable.t(), User.t()) :: Ecto.Query.t()
  def where_user(query, user) do
    where(query, [p], p.user_id == ^user.id)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      case URI.parse(value) do
        %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and not is_nil(host) ->
          []

        _ ->
          [{field, "must be a valid URL starting with http or https"}]
      end
    end)
  end
end
