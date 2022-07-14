defmodule Isave.AccountsTest do
  use Isave.DataCase

  alias Isave.Accounts

  describe "tbl_users" do
    alias Isave.Accounts.UserAccounts

    import Isave.AccountsFixtures

    @invalid_attrs %{auto_pwd: nil, email: nil, first_name: nil, last_name: nil, nrc_no: nil, password: nil, phone_no: nil, residential_address: nil, user_role: nil, user_status: nil, user_type: nil}

    test "list_tbl_users/0 returns all tbl_users" do
      user_accounts = user_accounts_fixture()
      assert Accounts.list_tbl_users() == [user_accounts]
    end

    test "get_user_accounts!/1 returns the user_accounts with given id" do
      user_accounts = user_accounts_fixture()
      assert Accounts.get_user_accounts!(user_accounts.id) == user_accounts
    end

    test "create_user_accounts/1 with valid data creates a user_accounts" do
      valid_attrs = %{auto_pwd: "some auto_pwd", email: "some email", first_name: "some first_name", last_name: "some last_name", nrc_no: "some nrc_no", password: "some password", phone_no: "some phone_no", residential_address: "some residential_address", user_role: "some user_role", user_status: "some user_status", user_type: "some user_type"}

      assert {:ok, %UserAccounts{} = user_accounts} = Accounts.create_user_accounts(valid_attrs)
      assert user_accounts.auto_pwd == "some auto_pwd"
      assert user_accounts.email == "some email"
      assert user_accounts.first_name == "some first_name"
      assert user_accounts.last_name == "some last_name"
      assert user_accounts.nrc_no == "some nrc_no"
      assert user_accounts.password == "some password"
      assert user_accounts.phone_no == "some phone_no"
      assert user_accounts.residential_address == "some residential_address"
      assert user_accounts.user_role == "some user_role"
      assert user_accounts.user_status == "some user_status"
      assert user_accounts.user_type == "some user_type"
    end

    test "create_user_accounts/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user_accounts(@invalid_attrs)
    end

    test "update_user_accounts/2 with valid data updates the user_accounts" do
      user_accounts = user_accounts_fixture()
      update_attrs = %{auto_pwd: "some updated auto_pwd", email: "some updated email", first_name: "some updated first_name", last_name: "some updated last_name", nrc_no: "some updated nrc_no", password: "some updated password", phone_no: "some updated phone_no", residential_address: "some updated residential_address", user_role: "some updated user_role", user_status: "some updated user_status", user_type: "some updated user_type"}

      assert {:ok, %UserAccounts{} = user_accounts} = Accounts.update_user_accounts(user_accounts, update_attrs)
      assert user_accounts.auto_pwd == "some updated auto_pwd"
      assert user_accounts.email == "some updated email"
      assert user_accounts.first_name == "some updated first_name"
      assert user_accounts.last_name == "some updated last_name"
      assert user_accounts.nrc_no == "some updated nrc_no"
      assert user_accounts.password == "some updated password"
      assert user_accounts.phone_no == "some updated phone_no"
      assert user_accounts.residential_address == "some updated residential_address"
      assert user_accounts.user_role == "some updated user_role"
      assert user_accounts.user_status == "some updated user_status"
      assert user_accounts.user_type == "some updated user_type"
    end

    test "update_user_accounts/2 with invalid data returns error changeset" do
      user_accounts = user_accounts_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user_accounts(user_accounts, @invalid_attrs)
      assert user_accounts == Accounts.get_user_accounts!(user_accounts.id)
    end

    test "delete_user_accounts/1 deletes the user_accounts" do
      user_accounts = user_accounts_fixture()
      assert {:ok, %UserAccounts{}} = Accounts.delete_user_accounts(user_accounts)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user_accounts!(user_accounts.id) end
    end

    test "change_user_accounts/1 returns a user_accounts changeset" do
      user_accounts = user_accounts_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user_accounts(user_accounts)
    end
  end
end
