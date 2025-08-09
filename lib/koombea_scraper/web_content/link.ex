defmodule KoombeaScraper.WebContent.Link do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias KoombeaScraper.WebContent.Page

  @type t() :: %__MODULE__{}

  schema "links" do
    field :name, :string
    field :url, :string

    belongs_to :page, Page

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(link, attrs) do
    link
    |> cast(attrs, [:name, :url, :page_id])
    |> validate_required([:url])
  end

  @spec where_page(Ecto.Queryable.t(), Page.t()) :: Ecto.Query.t()
  def where_page(query, page) do
    where(query, [p], p.page_id == ^page.id)
  end
end
