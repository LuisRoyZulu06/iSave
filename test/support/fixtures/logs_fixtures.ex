defmodule Isave.LogsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Isave.Logs` context.
  """

  @doc """
  Generate a user_logs.
  """
  def user_logs_fixture(attrs \\ %{}) do
    {:ok, user_logs} =
      attrs
      |> Enum.into(%{
        activity: "some activity",
        user_id: "some user_id"
      })
      |> Isave.Logs.create_user_logs()

    user_logs
  end
end
