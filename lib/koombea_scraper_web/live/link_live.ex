defmodule KoombeaScraperWeb.LinkLive do
  use KoombeaScraperWeb, :live_view

  alias KoombeaScraper.WebContent

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(%{"id" => id} = params, _uri, socket) do
    page_number = params["page"] || 1

    case WebContent.get_user_page(socket.assigns.current_user, id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Page not found.")
         |> redirect(to: ~p"/pages")}

      page ->
        %{entries: links, page_number: page_number, total_pages: total_pages} =
          WebContent.paginate_page_links(page, page: page_number)

        {:noreply,
         assign(socket,
           page: page,
           links: links,
           page_number: page_number,
           total_pages: total_pages
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {"#{@page.title}(#{@page.url})"}
        <:actions>
          <.link href={~p"/pages"} class="underline text-blue-800">&lt Back to Pages</.link>
        </:actions>
      </.header>
    </div>
    <.table
      id="links"
      rows={@links}
    >
      <:col :let={link} label="Name">{link.name || "(No link name found)"}</:col>
      <:col :let={link} label="Link">
        <a class="underline text-blue-800" href={link.url} target="_blank">{link.url}</a>
      </:col>
    </.table>
    <div class="mt-5 flex justify-between">
      <%= if @page_number <= 1 do %>
        <div></div>
      <% else %>
        <.link href={~p"/pages/#{@page.id}/links?page=#{@page_number - 1}"} class="underline">
          &lt Previous
        </.link>
      <% end %>
      <span class="font-bold">{@page_number} of {@total_pages}</span>
      <%= if @page_number >= @total_pages do %>
        <div></div>
      <% else %>
        <.link href={~p"/pages/#{@page.id}/links?page=#{@page_number + 1}"} class="underline">
          Next &gt
        </.link>
      <% end %>
    </div>
    """
  end
end
