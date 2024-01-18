defmodule Vendit.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "products" do
    field :product_name, :string, default: "New Product"
    field :cost, :integer, default: 0
    field :amount_available, :integer, default: 1
    field :seller_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:product_name, :cost, :amount_available, :seller_id])
    |> validate_required([:product_name, :cost, :amount_available, :seller_id])
    |> validate_number(:amount_available, greater_than_or_equal_to: 0)
    |> validate_number(:cost, greater_than_or_equal_to: 1)
  end

  @doc false
  def purchase_changeset(product) do
    product
    |> cast(%{amount_available: product.amount_available - 1}, [:amount_available])
    |> validate_number(:amount_available, greater_than_or_equal_to: 0)
  end
end
