defmodule KoombeaScraper.WebContentTest do
  use KoombeaScraper.DataCase, async: true

  import KoombeaScraper.AccountsFixtures
  import KoombeaScraper.WebContentFixtures

  alias KoombeaScraper.WebContent
  alias KoombeaScraper.WebContent.Page

  describe "list_user_pages/1" do
    test "returns only the user's pages" do
      user = user_fixture()
      other_user = user_fixture()

      page1 = page_fixture(user_id: user.id)
      _page2 = page_fixture(user_id: other_user.id)

      assert [p] = WebContent.list_user_pages(user)
      assert p.id == page1.id
    end
  end

  describe "paginate_user_pages/1" do
    test "returns paginated pages for the user" do
      user = user_fixture()
      page_fixture(user_id: user.id)
      page_fixture(user_id: user.id)
      page_fixture(user_id: user.id)

      result = WebContent.paginate_user_pages(user)
      assert length(result.entries) == 3
      assert result.total_entries == 3
    end
  end

  describe "get_user_page/2" do
    test "returns the page for the given user" do
      user = user_fixture()
      %{id: id} = page = page_fixture(user_id: user.id)

      assert %Page{id: ^id} = WebContent.get_user_page(user, page.id)
    end

    test "returns nil if page does not belong to user" do
      user = user_fixture()
      other_user = user_fixture()
      page = page_fixture(user_id: user.id)

      assert WebContent.get_user_page(other_user, page.id) == nil
    end
  end

  describe "get_page/1" do
    test "returns the page by id" do
      user = user_fixture()
      %{id: id} = page = page_fixture(user_id: user.id)

      assert %Page{id: ^id} = WebContent.get_page(page.id)
    end

    test "returns nil if not found" do
      assert WebContent.get_page(-1) == nil
    end
  end

  describe "create_user_page/2" do
    test "creates a page with status in_progress and enqueues scraper" do
      user = user_fixture()

      {:ok, page} =
        WebContent.create_user_page(user, %{"title" => "My Page", "url" => "http://foo.com"})

      assert page.user_id == user.id
      assert page.status == :in_progress
      assert Repo.get(Page, page.id)
    end
  end

  describe "update_page/2" do
    test "updates the page attributes" do
      user = user_fixture()
      page = page_fixture(title: "Old Title", user_id: user.id)
      {:ok, page} = WebContent.update_page(page, %{"title" => "New Title"})
      assert page.title == "New Title"
    end
  end

  describe "change_page/1" do
    test "returns a changeset" do
      user = user_fixture()
      page = page_fixture(user_id: user.id)
      changeset = WebContent.change_page(page)
      assert %Ecto.Changeset{} = changeset
      assert changeset.data == page
    end
  end

  describe "enqueue_scraper_worker/1" do
    test "enqueues a scraper worker job" do
      user = user_fixture()
      page = page_fixture(user_id: user.id)
      {:ok, job} = WebContent.enqueue_scraper_worker(page)
      assert job.args["page_id"] == page.id
    end
  end

  describe "paginate_page_links/2" do
    test "returns paginated links for a page" do
      user = user_fixture()
      page = page_fixture(user_id: user.id)
      link_fixture(page_id: page.id)
      link_fixture(page_id: page.id)

      result = WebContent.paginate_page_links(page)
      assert length(result.entries) == 2
    end
  end
end
