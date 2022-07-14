defmodule Isave.NotificationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Isave.Notifications` context.
  """

  @doc """
  Generate a email.
  """
  def email_fixture(attrs \\ %{}) do
    {:ok, email} =
      attrs
      |> Enum.into(%{
        attempts: "some attempts",
        mail_body: "some mail_body",
        recipient_email: "some recipient_email",
        sender_email: "some sender_email",
        sender_name: "some sender_name",
        status: "some status",
        subject: "some subject"
      })
      |> Isave.Notifications.create_email()

    email
  end
end
