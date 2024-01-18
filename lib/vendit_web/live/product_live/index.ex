defmodule VenditWeb.ProductLive.Index do
  use VenditWeb, :live_view

  alias Vendit.Products
  alias Vendit.Products.Product

  @product_changed_topic "product_changed"
  @product_deleted_topic "product_deleted"

  @impl true
  def mount(_params, _session, socket) do
    VenditWeb.Endpoint.subscribe(@product_changed_topic)
    VenditWeb.Endpoint.subscribe(@product_deleted_topic)

    {:ok, stream(socket, :products, Products.list_products())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Product")
    |> assign(:product, Products.get_product!(id))
  end

  defp apply_action(socket, :new, params) do
    socket
    |> assign(:page_title, "New Product")
    |> assign(:product, struct(Product, params))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Products")
    |> assign(:product, nil)
  end

  @impl true
  def handle_info({VenditWeb.ProductLive.FormComponent, {:saved, product}}, socket) do
    VenditWeb.Endpoint.broadcast_from(self(), @product_changed_topic, "saved_product", product)

    {:noreply, stream_insert(socket, :products, product)}
  end

  def handle_info(%{topic: @product_changed_topic, payload: product}, socket),
    do: {:noreply, stream_insert(socket, :products, product)}

  def handle_info(%{topic: @product_deleted_topic, payload: product}, socket),
    do: {:noreply, stream_delete(socket, :products, product)}

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Products.get_product!(id)
    {:ok, _} = Products.delete_product(product)

    VenditWeb.Endpoint.broadcast_from(self(), @product_deleted_topic, "deleted_product", product)

    {:noreply, stream_delete(socket, :products, product)}
  end
end
