defmodule Vendit.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_name, :string
      add :cost, :integer
      add :amount_available, :integer
      add :seller_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:products, [:seller_id])
  end
end
