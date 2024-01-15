defmodule Vendit.Repo do
  use Ecto.Repo,
    otp_app: :vendit,
    adapter: Ecto.Adapters.SQLite3
end
