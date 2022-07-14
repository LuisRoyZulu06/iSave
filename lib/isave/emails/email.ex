defmodule Isave.Emails.Email do
  import Bamboo.Email
  alias Isave.Emails.Mailer
  alias Isave.Notifications.Email
  alias Isave.Repo
  use Bamboo.Phoenix, view: IsaveWeb.EmailView

  def password_alert(email, password) do
    password(email, password) |> Mailer.deliver_later()
  end

  def confirm_password_reset(token, email) do
    confirmation_token(token, email) |> Mailer.deliver_later()
  end

  def password(email, password) do
    new_email()
    |> from("natsaveepay@natsave.co.zm")
    |> to("#{email}")
    |> put_html_layout({IsaveWeb.LayoutView, "email.html"})
    |> subject("Isave Login Credentials")
    |> assign(:password, password)
    |> render("password_content.html")
  end

  def confirmation_token(token, email) do
    new_email()
    |> from("natsaveepay@natsave.co.zm")
    |> to("#{email}")
    |> put_html_layout({IsaveWeb.LayoutView, "email.html"})
    |> subject("Isave Login Credentials")
    |> assign(:token, token)
    |> render("token_content.html")
  end

  def send_alert(pwd, email, username) do
    sender_email = "Probase"
    sender_name = "ProBASE Limited Zm"
    subject = "Login Credentials"

    mail_body = "Hello #{username},\nYour username is: #{username}, and password: #{pwd}"

    params = %{
      subject: subject,
      sender_email: sender_email,
      sender_name: sender_name,
      mail_body: mail_body,
      recipient_email: email
    }

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:create_email, Email.changeset(%Email{}, params))
    |> Repo.transaction()
    |> case do
      {:ok, changeset} ->
        IO.inspect(changeset)

      {:error, xch} ->
        IO.inspect(xch)
    end
  end

  def forgot_pwd_confirmation(pwd, email, first_name) do
    sender_email = "natsaveepay@natsave.co.zm"
    sender_name = "Stanbic Bank"
    subject = "New Isave Password"

    mail_body = "Hello #{email},\nYour new login password is: #{pwd}."

    params = %{
      subject: subject,
      sender_email: sender_email,
      sender_name: sender_name,
      mail_body: mail_body,
      recipient_email: email
    }

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:create_email, Email.changeset(%Email{}, params))
    |> Repo.transaction()
    |> case do
      {:ok, changeset} ->
        IO.inspect(changeset)

      {:error, xch} ->
        IO.inspect(xch)
    end
  end

  def send_mail(to, subject, body) do
    sender_email = "natsaveepay@natsave.co.zm"
    sender_name = "Natsave"

    params = %{
      subject: subject,
      sender_email: sender_email,
      sender_name: sender_name,
      mail_body: body,
      recipient_email: to
    }

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:create_email, Email.changeset(%Email{}, params))
    |> Repo.transaction()
    |> case do
      {:ok, changeset} -> IO.inspect("Mail Submited")
      {:error, xch} -> IO.inspect("Failed to log mail")
    end
  end

  def notify_assessment_approver(email_addr, batch_ref, token) do
    new_email()
    |> from("natsaveepay@natsave.co.zm")
    |> to(email_addr)
    |> subject("Assessments for approval")
    |> text_body("""
    Dear ASCUDA World user, \r\n you have assessments with batch reference #{batch_ref} awaiting your approval\r\n.
    \r\n your approval token is #{token} \r\n.
    Regards Isave.
    """)
    |> Mailer.deliver_later()
  end

  def notify_bill_approver(email_addr, batch_ref, token) do
    new_email()
    |> from("natsaveepay@natsave.co.zm")
    |> to(email_addr)
    |> subject("Bills for approval")
    |> text_body("""
    Dear Isave user, \r\n you have a bill service with reference #{batch_ref} awaiting your approval\r\n.
    \r\n your approval token is #{token} \r\n.
    Regards Isave.
    """)
    |> Mailer.deliver_later()
  end

  def notify_bulk_ft_approver(email_addr, batch_no, token) do
    new_email()
    |> from("natsaveepay@natsave.co.zm")
    |> to(email_addr)
    |> subject("Bulk Fund Transfer Approval")
    |> text_body("""
    Dear Isave user, \r\n you have a bulk fund transfer batch with batch number #{batch_no} awaiting your approval\r\n.
    \r\n your approval token is #{token} \r\n.
    Regards Isave.
    """)
    |> Mailer.deliver_later()
  end
end
