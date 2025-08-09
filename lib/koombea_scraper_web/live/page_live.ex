defmodule KoombeaScraperWeb.PageLive do
  use KoombeaScraperWeb, :live_view

  alias KoombeaScraper.WebContent
  alias KoombeaScraper.WebContent.Page
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(KoombeaScraper.PubSub, "user_pages:#{socket.assigns.current_user.id}")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = params["page"] || 1

    %{entries: pages, page_number: page_number, total_pages: total_pages} =
      WebContent.paginate_user_pages(socket.assigns.current_user, preload: :links, page: page)

    {:noreply,
     socket
     |> assign(page_form: to_form(WebContent.change_page(%Page{})))
     |> assign(:pages, pages)
     |> assign(:page_number, page_number)
     |> assign(:total_pages, total_pages)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Pages
      </.header>
      <.simple_form for={@page_form} id="page-form" phx-submit="save">
        <div class="flex gap-1">
          <div class="w-full">
            <.input field={@page_form[:url]} type="text" value="" placeholder="Add new page" />
          </div>
          <div>
            <.button phx-disable-with="Processing...">Scrape</.button>
          </div>
        </div>
      </.simple_form>
    </div>
    <.table
      id="pages"
      rows={@pages}
      row_click={fn page -> JS.navigate(~p"/pages/#{page}/links") end}
    >
      <:col :let={page} label="Title">{page.title || page.url}</:col>
      <:col :let={page} label="Total links">
        {if page.status != :done,
          do: Phoenix.Naming.humanize(page.status),
          else: Enum.count(page.links)}
      </:col>
    </.table>
    <div class="mt-5 flex justify-between">
      <%= if @page_number <= 1 do %>
        <div></div>
      <% else %>
        <.link href={~p"/pages?page=#{@page_number - 1}"} class="underline">&lt Previous</.link>
      <% end %>
      <span class="font-bold">{@page_number} of {@total_pages}</span>
      <%= if @page_number >= @total_pages do %>
        <div></div>
      <% else %>
        <.link href={~p"/pages?page=#{@page_number + 1}"} class="underline">Next &gt</.link>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("save", %{"page" => page_params}, socket) do
    case WebContent.create_user_page(socket.assigns.current_user, page_params) do
      {:ok, _page} ->
        {:noreply,
         socket
         |> put_flash(:info, "Page created successfully")
         |> push_navigate(to: ~p"/pages")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, page_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_info({:page_processed_success, _updated_page}, socket) do
    pages =
      WebContent.paginate_user_pages(socket.assigns.current_user,
        preload: :links,
        page: socket.assigns.page_number
      )

    {:noreply,
     socket
     |> put_flash(:info, "Scraping complete!")
     |> assign(:pages, pages)}
  end

  @impl true
  def handle_info({:page_processed_fail, updated_page, reason}, socket) do
    pages =
      WebContent.paginate_user_pages(socket.assigns.current_user,
        preload: :links,
        page: socket.assigns.page_number
      )

    {:noreply,
     socket
     |> put_flash(:error, "Scraping failed for page: #{updated_page.url} #{inspect(reason)}")
     |> assign(:pages, pages)}
  end
end
