defmodule Vendit.ProductsTest do
  use Vendit.DataCase

  alias Vendit.Products

  describe "products" do
    alias Vendit.Products.Product

    import Vendit.ProductsFixtures
    import Vendit.AccountsFixtures

    @invalid_attrs %{product_name: nil, cost: -27, amount_available: nil}

    setup do
      user = user_fixture()
      product = product_fixture(%{seller_id: user.id})

      %{user: user, product: product}
    end

    test "list_products/0 returns all products", %{product: product} do
      assert Products.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id", %{product: product} do
      assert Products.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product", %{product: product} do
      valid_attrs = %{
        product_name: "some product_name",
        cost: 42,
        amount_available: 42,
        seller_id: product.seller_id
      }

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.product_name == "some product_name"
      assert product.cost == 42
      assert product.amount_available == 42
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product", %{product: product} do
      update_attrs = %{product_name: "some updated product_name", cost: 43, amount_available: 43}

      assert {:ok, %Product{} = product} = Products.update_product(product, update_attrs)
      assert product.product_name == "some updated product_name"
      assert product.cost == 43
      assert product.amount_available == 43
    end

    test "update_product/2 with invalid data returns error changeset", %{product: product} do
      assert {:error, %Ecto.Changeset{}} = Products.update_product(product, @invalid_attrs)
      assert product == Products.get_product!(product.id)
    end

    test "delete_product/1 deletes the product", %{product: product} do
      assert {:ok, %Product{}} = Products.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset", %{product: product} do
      assert %Ecto.Changeset{} = Products.change_product(product)
    end
  end
end
