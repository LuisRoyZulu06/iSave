defmodule Isave.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Isave.Accounts` context.
  """

  @doc """
  Generate a user_accounts.
  """
  def user_accounts_fixture(attrs \\ %{}) do
    {:ok, user_accounts} =
      attrs
      |> Enum.into(%{
        auto_pwd: "some auto_pwd",
        email: "some email",
        first_name: "some first_name",
        last_name: "some last_name",
        nrc_no: "some nrc_no",
        password: "some password",
        phone_no: "some phone_no",
        residential_address: "some residential_address",
        user_role: "some user_role",
        user_status: "some user_status",
        user_type: "some user_type"
      })
      |> Isave.Accounts.create_user_accounts()

    user_accounts
  end
end
