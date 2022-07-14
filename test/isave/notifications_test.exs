defmodule Isave.NotificationsTest do
  use Isave.DataCase

  alias Isave.Notifications

  describe "tbl_email_logs" do
    alias Isave.Notifications.Email

    import Isave.NotificationsFixtures

    @invalid_attrs %{attempts: nil, mail_body: nil, recipient_email: nil, sender_email: nil, sender_name: nil, status: nil, subject: nil}

    test "list_tbl_email_logs/0 returns all tbl_email_logs" do
      email = email_fixture()
      assert Notifications.list_tbl_email_logs() == [email]
    end

    test "get_email!/1 returns the email with given id" do
      email = email_fixture()
      assert Notifications.get_email!(email.id) == email
    end

    test "create_email/1 with valid data creates a email" do
      valid_attrs = %{attempts: "some attempts", mail_body: "some mail_body", recipient_email: "some recipient_email", sender_email: "some sender_email", sender_name: "some sender_name", status: "some status", subject: "some subject"}

      assert {:ok, %Email{} = email} = Notifications.create_email(valid_attrs)
      assert email.attempts == "some attempts"
      assert email.mail_body == "some mail_body"
      assert email.recipient_email == "some recipient_email"
      assert email.sender_email == "some sender_email"
      assert email.sender_name == "some sender_name"
      assert email.status == "some status"
      assert email.subject == "some subject"
    end

    test "create_email/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notifications.create_email(@invalid_attrs)
    end

    test "update_email/2 with valid data updates the email" do
      email = email_fixture()
      update_attrs = %{attempts: "some updated attempts", mail_body: "some updated mail_body", recipient_email: "some updated recipient_email", sender_email: "some updated sender_email", sender_name: "some updated sender_name", status: "some updated status", subject: "some updated subject"}

      assert {:ok, %Email{} = email} = Notifications.update_email(email, update_attrs)
      assert email.attempts == "some updated attempts"
      assert email.mail_body == "some updated mail_body"
      assert email.recipient_email == "some updated recipient_email"
      assert email.sender_email == "some updated sender_email"
      assert email.sender_name == "some updated sender_name"
      assert email.status == "some updated status"
      assert email.subject == "some updated subject"
    end

    test "update_email/2 with invalid data returns error changeset" do
      email = email_fixture()
      assert {:error, %Ecto.Changeset{}} = Notifications.update_email(email, @invalid_attrs)
      assert email == Notifications.get_email!(email.id)
    end

    test "delete_email/1 deletes the email" do
      email = email_fixture()
      assert {:ok, %Email{}} = Notifications.delete_email(email)
      assert_raise Ecto.NoResultsError, fn -> Notifications.get_email!(email.id) end
    end

    test "change_email/1 returns a email changeset" do
      email = email_fixture()
      assert %Ecto.Changeset{} = Notifications.change_email(email)
    end
  end
end
