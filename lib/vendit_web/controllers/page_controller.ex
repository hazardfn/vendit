defmodule VenditWeb.PageController do
  use VenditWeb, :controller

  def home(conn, _params) do
    if conn.assigns.current_user,
      do: redirect(conn, to: ~p"/app"),
      else: conn |> assign(:socket, nil) |> render(:instructions)
  end
end
