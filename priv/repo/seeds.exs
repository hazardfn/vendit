# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Vendit.Repo.insert!(%Vendit.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Vendit.Accounts
alias Vendit.Repo

import Ecto.Changeset

create_seller = fn email, password ->
  case Accounts.get_user_by_email_and_password(email, password) do
    nil ->
      %{email: email, password: password}
      |> Accounts.register_user()
      |> case do
        {:ok, user} ->
          user
          |> cast(%{role: :seller}, [:role])
          |> Repo.update!()

        :error ->
          raise("Unable to insert seller account!")
      end

    user ->
      user
      |> cast(%{role: :seller}, [:role])
      |> Repo.update!()
  end
end

# Create Seller
create_seller.("admin@mvpmatch.co", "password1234")
create_seller.("someseller@mvpmatch.co", "password1234")
