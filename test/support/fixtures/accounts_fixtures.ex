defmodule Vendit.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Vendit.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    attrs
    |> valid_user_attributes()
    |> Vendit.Accounts.register_user()
    |> case do
      {:ok, user} ->
        user
        |> Ecto.Changeset.cast(%{role: :seller}, [:role])
        |> Vendit.Repo.update!()

      :error ->
        raise("Unable to insert seller account!")
    end
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
