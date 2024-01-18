defmodule VenditWeb.UserHeaderLive do
  use VenditWeb, :live_view

  on_mount {VenditWeb.UserAuth, :mount_current_user}

  @user_changed_topic "user_changed"

  @impl true
  def render(assigns) do
    ~H"""
    <li class="text-[1rem] leading-6 text-zinc-900">
      <.icon name="hero-user-circle" class="h-5 w-5" /> <%= assigns[:current_user].email %>
      <.icon name="hero-banknotes" class="h-5 w-5" /> ¢<%= assigns[:current_user].deposit %>
    </li>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    VenditWeb.Endpoint.subscribe("#{@user_changed_topic}_#{socket.assigns.current_user.id}")

    {:ok, socket, layout: false}
  end

  @impl true
  def handle_info(%{topic: _, payload: user}, socket),
    do: {:noreply, assign(socket, current_user: user)}
end
