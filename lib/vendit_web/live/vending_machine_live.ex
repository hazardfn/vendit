defmodule VenditWeb.VendingMachineLive do
  use VenditWeb, :live_view

  alias Vendit.Products
  alias Vendit.Accounts

  @product_changed_topic "product_changed"
  @product_deleted_topic "product_deleted"
  @user_changed_topic "user_changed"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-4 lg:grid-cols-3 lg:gap-8">
      <div class="h-32 rounded-lg lg:col-span-2">
        <.table
          id="products"
          rows={@streams.products}
          row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
        >
          <:col :let={{_id, product}} label="Product"><%= product.product_name %></:col>
          <:col :let={{_id, product}} label="Cost">¢<%= product.cost %></:col>
          <:col :let={{_id, product}} label="No. Available"><%= product.amount_available %></:col>
          <:action :let={{_id, product}}>
            <.link phx-click={JS.push("buy", value: %{id: product.id})}>
              Buy
            </.link>
          </:action>
        </.table>
      </div>
      <div class="h-32 rounded-lg">
        <div class="my-5">
        <.button phx-click="deposit-5" class="m-2 text-white bg-gradient-to-r from-purple-400 via-purple-500 to-purple-600 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-purple-300 dark:focus:ring-purple-800 shadow-lg shadow-purple-500/50 dark:shadow-lg dark:shadow-purple-800/80 font-medium rounded-lg text-sm px-5 py-2.5 text-center me-2 mb-2">Deposit 5¢</.button>
        <.button phx-click="deposit-10" class="m-2 text-white bg-gradient-to-r from-purple-400 via-purple-500 to-purple-600 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-purple-300 dark:focus:ring-purple-800 shadow-lg shadow-purple-500/50 dark:shadow-lg dark:shadow-purple-800/80 font-medium rounded-lg text-sm px-5 py-2.5 text-center me-2 mb-2">Deposit 10¢</.button>
        <.button phx-click="deposit-20" class="m-2 text-white bg-gradient-to-r from-purple-400 via-purple-500 to-purple-600 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-purple-300 dark:focus:ring-purple-800 shadow-lg shadow-purple-500/50 dark:shadow-lg dark:shadow-purple-800/80 font-medium rounded-lg text-sm px-5 py-2.5 text-center me-2 mb-2">Deposit 20¢</.button>
        <.button phx-click="deposit-50" class="m-2 text-white bg-gradient-to-r from-purple-400 via-purple-500 to-purple-600 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-purple-300 dark:focus:ring-purple-800 shadow-lg shadow-purple-500/50 dark:shadow-lg dark:shadow-purple-800/80 font-medium rounded-lg text-sm px-5 py-2.5 text-center me-2 mb-2">Deposit 50¢</.button>
        <.button phx-click="deposit-100" class="m-2 text-white bg-gradient-to-r from-purple-400 via-purple-500 to-purple-600 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-purple-300 dark:focus:ring-purple-800 shadow-lg shadow-purple-500/50 dark:shadow-lg dark:shadow-purple-800/80 font-medium rounded-lg text-sm px-5 py-2.5 text-center me-2 mb-2">Deposit 100¢</.button>
        </div>
        <div class="my-5">
        <.button phx-click="reset" class="ml-2 text-white bg-gradient-to-r from-red-400 via-red-500 to-red-600 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-red-300 dark:focus:ring-red-800 shadow-lg shadow-red-500/50 dark:shadow-lg dark:shadow-red-800/80 font-medium rounded-lg text-sm px-5 py-2.5 text-center me-2 mb-2">Reset</.button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    VenditWeb.Endpoint.subscribe(@product_changed_topic)
    VenditWeb.Endpoint.subscribe(@product_deleted_topic)
    VenditWeb.Endpoint.subscribe("#{@user_changed_topic}_#{socket.assigns.current_user.id}")

    {:ok, stream(socket, :products, Products.list_products())}
  end

  @impl true
  def handle_event("buy", %{"id" => product_id}, socket) do
    case Accounts.purchase_product(socket.assigns.current_user, product_id) do
      {:ok, user, product, change} ->
        VenditWeb.Endpoint.broadcast_from(
          self(),
          "#{@user_changed_topic}_#{socket.assigns.current_user.id}",
          "user_changed",
          user
        )

        VenditWeb.Endpoint.broadcast_from(
          self(),
          @product_changed_topic,
          "saved_product",
          product
        )

        {:noreply,
         socket
         |> assign(current_user: user)
         |> stream_insert(:products, product)
         |> put_flash(
           :info,
           "Sucessfully purchased #{product.product_name}. Change: #{inspect(change, charlists: :as_lists)}"
         )}

      :error ->
        {:noreply,
         socket
         |> put_flash(:error, "Insufficient funds or product availability!")}
    end
  end

  def handle_event("deposit-" <> amount, _params, socket) do
    amount = String.to_integer(amount)

    case Accounts.update_user_deposit(socket.assigns.current_user, amount) do
      {:ok, user} ->
        VenditWeb.Endpoint.broadcast_from(
          self(),
          "#{@user_changed_topic}_#{user.id}",
          "user_changed",
          user
        )

        {:noreply, assign(socket, current_user: user)}

      {:error, changeset} ->
        error_msg =
          changeset
          |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
            Regex.replace(~r"%{(\w+)}", message, fn _, key ->
              opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
            end)
          end)
          |> Map.get(:deposit, "An unknown error ocurred!")

        {:noreply, put_flash(socket, :error, error_msg)}
    end
  end

  def handle_event("reset", _params, socket) do
    user = socket.assigns.current_user
    current_deposit = user.deposit

    case Accounts.update_user_deposit(user, -current_deposit) do
      {:ok, user} ->
        VenditWeb.Endpoint.broadcast_from(
          self(),
          "#{@user_changed_topic}_#{user.id}",
          "user_changed",
          user
        )

        {:noreply, assign(socket, current_user: user)}

      {:error, changeset} ->
        error_msg =
          changeset
          |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
          Regex.replace(~r"%{(\w+)}", message, fn _, key ->
            opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
          end)
        end)
        |> Map.get(:deposit, "An unknown error ocurred!")

          {:noreply, put_flash(socket, :error, error_msg)}
    end
  end

  @impl true
  def handle_info(%{topic: @product_changed_topic, payload: product}, socket),
    do: {:noreply, stream_insert(socket, :products, product)}

  @impl true
  def handle_info(%{topic: @product_deleted_topic, payload: product}, socket),
    do: {:noreply, stream_delete(socket, :products, product)}
end
