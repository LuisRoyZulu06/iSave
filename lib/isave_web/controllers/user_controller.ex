defmodule IsaveWeb.UserController do
  use IsaveWeb, :controller
  import Ecto.Query, warn: false
  alias Isave.Repo
  alias Isave.Auth
  alias Isave.Logs
  alias Isave.Emails
  alias Isave.Accounts
  alias Isave.Utilities
  alias Isave.Emails.Email
  alias Isave.Logs.User_logs
  alias Isave.Accounts.UserAccounts
  alias Isave.Utilities.ReportUtils

  plug(
    IsaveWeb.Plugs.RequireAuth
    when action in [
           :new,
           :dashboard,
           :user_mgt,
           :update_user,
           :user_logs,
           :user_profile,
           :user_pwd_change,
           :self_pwd_change,
           :user_report,
           :create_user,

           # -----------RECONSIDER
           :list_users,
           :edit,
           :delete,
           :user_logs,
           :update,
           :create,
           :update_status,
           :user_actitvity
         ]
  )

  plug(
    IsaveWeb.Plugs.EnforcePasswordPolicy
    when action in [:new_password, :change_password]
  )

  plug(
    IsaveWeb.Plugs.RequireAdminAccess
    when action in [:dashboard, :user_mgt, :user_logs, :user_report]
  )

  def dashboard(conn, _params) do
    render(conn, "dashboard.html")
  end

  # def system_users_table(conn, params) do
  #   {start, length, search_params} = ReportUtils.search_options(params)
  #   results = Accounts.system_users(search_params, start, length)
  #   total_entries = ReportUtils.total_entries(results)
  #   users = check_tellers(results.entries)
  #   results = Map.put(results, :entries, users)
  #   results = ReportUtils.display(results, total_entries)
  #   json(conn, results)
  # end

  def user_mgt(conn, _search_params) do
    deleted_users = Accounts.list_users()
    render(conn, "user_mgt.html", deleted_users: deleted_users)
  end

  def get_user_mgt(conn, params) do
    {start, length, search_params} = ReportUtils.search_options(params)
    results = Accounts.system_users(search_params, start, length)
    results = ReportUtils.prep_results(results)
    json(conn, results)
  end

  def get_blckd_user(conn, params) do
    {start, length, search_params} = ReportUtils.search_options(params)
    results = Accounts.blocked_users(search_params, start, length)
    results = ReportUtils.prep_results(results)
    json(conn, results)
  end

  def create_user(conn, params) do
    IO.inspect('================HT=============')
    IO.inspect(conn)

    case Accounts.get_user_by_username(params["username"]) do
      nil ->
        pwd = random_string(6)
        params = Map.put(params, "password", pwd)

        Ecto.Multi.new()
        |> Ecto.Multi.insert(:useraccount, UserAccounts.changeset(%UserAccounts{}, params))
        |> Ecto.Multi.run(:user_log, fn _repo, %{useraccount: useraccount} ->
          activity = "Created new user on the system. of ID #{useraccount.id}"
          user_log = %{user_id: conn.assigns.user.id, activity: activity}

          User_logs.changeset(%User_logs{}, user_log)
          |> Repo.insert()
        end)
        |> Repo.transaction()
        |> case do
          {:ok, %{useraccount: _useraccount, user_log: _user_log}} ->
            Email.send_alert(pwd, params["email"], params["username"])

            conn
            |> put_flash(:info, "User created Successfully")
            |> redirect(to: Routes.user_path(conn, :user_mgt, id: params["company_id"]))

          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to create user.")
            |> redirect(to: Routes.user_path(conn, :user_mgt, id: params["company_id"]))
        end

      _user ->
        conn
        |> put_flash(:error, "User with #{params["email"]} already exists.")
        |> redirect(to: Routes.user_path(conn, :user_mgt))
    end
  end

  def update_user(conn, %{"id" => id} = params) do
    user = Accounts.get_user_account!(id)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:update_user, User.changeset(user, params))
    |> Ecto.Multi.run(:user_log, fn _repo, %{update_user: user} ->
      activity = "updated user with id #{user.id}"

      user_log = %{
        user_id: conn.assigns.user.id,
        activity: activity
      }

      User_logs.changeset(%User_logs{}, user_log)
      |> Repo.insert()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{update_user: user, user_log: _user_log}} ->
        conn
        |> put_flash(:info, "User updated Successfully")
        |> redirect(to: Routes.user_path(conn, :user_mgt, id: user.id))

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to update user.")
        |> redirect(to: Routes.user_path(conn, :user_mgt, id: user.id))
    end
  end

  def user_logs(conn, _params) do
    logs = Logs.list_user_logs()
    render(conn, "user_logs.html", logs: logs)
  end

  def user_profile(conn, _params) do
    render(conn, "user_profile.html")
  end

  def user_report(conn, %{"user_id" => id} = params) do
    logged_issues = IssueLogger.total_issues_logged()
    resolved_issues = IssueLogger.resolved_issues(id)
    pending_approval = IssueLogger.user_pending_approval_issues(id)
    assigned_issues = IssueLogger.user_assigned_issues(id)
    user_activity = Logs.get_user_logs_by_user_id(id)
    wip_issue = IssueLogger.wip_issue(id)

    render(conn, "user_report.html",
      user_activity: user_activity,
      logged_issues: logged_issues,
      assigned_issues: assigned_issues,
      pending_approval: pending_approval,
      resolved_issues: resolved_issues,
      wip_issue: wip_issue
    )
  end

  # ------------------ Self password change
  def user_pwd_change(conn, params) do
    render(conn, "change_pwd.html")
  end

  def self_pwd_change(conn, %{"user" => user_params}) do
    case confirm_old_password(conn, user_params) do
      false ->
        conn
        |> put_flash(:error, "some fields were submitted empty!")
        |> redirect(to: Routes.user_path(conn, :user_pwd_change))

      result ->
        with {:error, reason} <- result do
          conn
          |> put_flash(:error, reason)
          |> redirect(to: Routes.user_path(conn, :user_pwd_change))
        else
          {:ok, _} ->
            conn.assigns.user
            |> change_pwd(user_params)
            |> Repo.transaction()
            |> case do
              {:ok, %{update: _update, insert: _insert}} ->
                conn
                |> put_flash(
                  :info,
                  "Password changed successfully."
                )
                |> redirect(to: Routes.user_path(conn, :user_pwd_change))

              {:error, _failed_operation, failed_value, _changes_so_far} ->
                reason = traverse_errors(failed_value.errors) |> List.first()

                conn
                |> put_flash(:info, reason)
                |> redirect(to: Routes.user_path(conn, :user_pwd_change))
            end
        end
    end

    # rescue
    #   _ ->
    #     conn
    #     |> put_flash(:error, "Password changed with errors")
    #     |> redirect(to: Routes.user_path(conn, :new_password))
  end

  # ------------------ first time loggin password change
  def change_password(conn, %{"user" => user_params}) do
    case confirm_old_password(conn, user_params) do
      false ->
        conn
        |> put_flash(:error, "some fields were submitted empty!")
        |> redirect(to: Routes.user_path(conn, :new_password))

      result ->
        with {:error, reason} <- result do
          conn
          |> put_flash(:error, reason)
          |> redirect(to: Routes.user_path(conn, :new_password))
        else
          {:ok, _} ->
            conn.assigns.user
            |> change_pwd(user_params)
            |> Repo.transaction()
            |> case do
              {:ok, %{update: _update, insert: _insert}} ->
                conn
                |> put_flash(
                  :info,
                  "Password changed successful, please login using your new password."
                )
                |> redirect(to: Routes.session_path(conn, :new))

              {:error, _failed_operation, failed_value, _changes_so_far} ->
                reason = traverse_errors(failed_value.errors) |> List.first()

                conn
                |> put_flash(:info, reason)
                |> redirect(to: Routes.session_path(conn, :new))
            end
        end
    end
  end

  defp confirm_old_password(
         conn,
         %{"old_password" => pwd, "new_password" => new_pwd}
       ) do
    with true <- String.trim(pwd) != "",
         true <- String.trim(new_pwd) != "" do
      Auth.confirm_password(
        conn.assigns.user,
        String.trim(pwd)
      )
    else
      false -> false
    end
  end

  def change_pwd(user, user_params) do
    pwd = String.trim(user_params["new_password"])

    Ecto.Multi.new()
    |> Ecto.Multi.update(:update, User.changeset(user, %{password: pwd, auto_pwd: "N"}))
    |> Ecto.Multi.insert(
      :insert,
      User_logs.changeset(
        %User_logs{},
        %{user_id: user.id, activity: "changed account password"}
      )
    )
  end

  # def user_actitvity(conn, %{"id" => user_id}) do
  #   with :error <- confirm_token(conn, user_id) do
  #     conn
  #     |> put_flash(:error, "invalid token received")
  #     |> redirect(to: Routes.user_path(conn, :list_users))
  #   else
  #     {:ok, user} ->
  #       user_logs = Logs.get_user_logs_by(user.id)
  #       page = %{first: "Users", last: "Activity logs"}
  #       render(conn, "activity_logs.html", user_logs: user_logs, page: page)
  #   end
  # end

  def activity_logs(conn, _params) do
    results = Logs.get_all_activity_logs()
    page = %{first: "Users", last: "Activity logs"}
    render(conn, "activity_logs.html", user_logs: results, page: page)
  end

  defp prepare_status_change(changeset, conn, user, status) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.insert(
      :user_log,
      User_logs.changeset(
        %User_logs{},
        %{
          user_id: conn.assigns.user.id,
          activity: """
          #{case status,
            do: (
              "1" -> "Activated"
              _ -> "Disabled"
            )}
          #{user.first_name} #{user.last_name}
          """
        }
      )
    )
  end

  # def edit(conn, %{"id" => id}) do
  #   with :error <- confirm_token(conn, id) do
  #     conn
  #     |> put_flash(:error, "invalid token received")
  #     |> redirect(to: Routes.user_path(conn, :list_users))
  #   else
  #     {:ok, user} ->
  #       user = %{user | id: sign_user_id(conn, user.id)}
  #       page = %{first: "Users", last: "Edit user"}
  #       render(conn, "edit.html", result: user, page: page)
  #   end
  # end
  #
  # def update(conn, %{"user" => user_params}) do
  #   with :error <- confirm_token(conn, user_params["id"]) do
  #     conn
  #     |> put_flash(:error, "invalid token received")
  #     |> redirect(to: Routes.user_path(conn, :list_users))
  #   else
  #     {:ok, user} ->
  #       Ecto.Multi.new()
  #       |> Ecto.Multi.update(:update, User.changeset(user, Map.delete(user_params, "id")))
  #       |> Ecto.Multi.run(:log, fn %{update: _update} ->
  #         activity =
  #           "Modified user details with Email \"#{user.email}\" and First Name \"#{
  #             user.first_name
  #           }\""
  #
  #         user_log = %{
  #           user_id: conn.assigns.user.id,
  #           activity: activity
  #         }
  #
  #         User_log.changeset(%User_logs{}, user_log)
  #         |> Repo.insert()
  #       end)
  #       |> Repo.transaction()
  #       |> case do
  #         {:ok, %{update: _update, log: _log}} ->
  #           conn
  #           |> put_flash(:info, "Changes applied successfully!")
  #           |> redirect(to: Routes.user_path(conn, :edit, id: user_params["id"]))
  #
  #         {:error, _failed_operation, failed_value, _changes_so_far} ->
  #           reason = traverse_errors(failed_value.errors) |> List.first()
  #
  #           conn
  #           |> put_flash(:error, reason)
  #           |> redirect(to: Routes.user_path(conn, :edit, id: user_params["id"]))
  #       end
  #   end
  # rescue
  #   _ ->
  #     conn
  #     |> put_flash(:error, "An error occurred, reason unknown")
  #     |> redirect(to: Routes.user_path(conn, :list_users))
  # end

  # def new(conn, _params) do
  #   render(conn, "new.html", page: %{first: "Users", last: "New user"})
  # end

  # -----------helper functions---------
  def get_user_by_email(email) do
    case Repo.get_by(UserAccounts, email: email) do
      nil -> {:error, "invalid email address"}
      user -> {:ok, user}
    end
  end

  def get_user_by_username(username) do
    case Repo.get_by(UserAccounts, username: username) do
      nil -> {:error, "Invalid username"}
      user -> {:ok, user}
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user_accounts!(id)

    Ecto.Multi.new()
    |> Ecto.Multi.delete(:user, user)
    |> Ecto.Multi.run(:user_log, fn %{user: user} ->
      activity = "Deleted user with Email \"#{user.email}\" and First Name \"#{user.first_name}\""

      user_log = %{
        user_id: conn.assigns.user.id,
        activity: activity
      }

      User_logs.changeset(%User_logs{}, user_log)
      |> Repo.insert()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user, user_log: _user_log}} ->
        conn
        |> put_flash(:info, "#{String.capitalize(user.first_name)} deleted successfully.")
        |> redirect(to: Routes.user_path(conn, :list_users))

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = traverse_errors(failed_value.errors) |> List.first()

        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.user_path(conn, :list_users))
    end
  end

  def get_user_by(nt_username) do
    case Repo.get_by(User, nt_username: nt_username) do
      nil -> {:error, "invalid username/password"}
      user -> {:ok, user}
    end
  end

  defp sign_user_id(conn, id),
    do: Phoenix.Token.sign(conn, "user salt", id, signed_at: System.system_time(:second))

  # ------------------ Password Reset ---------------------
  def new_password(conn, _params) do
    page = %{first: "Settings", last: "Change password"}
    render(conn, "login_change_password.html", page: page)
  end

  def forgot_password(conn, _params) do
    conn
    |> put_layout(false)
    |> render("forgot_password.html")
  end

  # def token(conn, %{"user" => user_params}) do
  #   with {:error, reason} <- get_user_by_email(user_params["email"]) do
  #     conn
  #     |> put_flash(:error, reason)
  #     |> redirect(to: Routes.user_path(conn, :forgot_password))
  #   else
  #     {:ok, user} ->
  #       token =
  #         Phoenix.Token.sign(conn, "user salt", user.id, signed_at: System.system_time(:second))
  #
  #       Email.confirm_password_reset(token, user.email)
  #
  #       conn
  #       |> put_flash(:info, "We have sent you a mail")
  #       |> redirect(to: Routes.session_path(conn, :new))
  #   end
  # end

  # defp confirm_token(conn, token) do
  #   case Phoenix.Token.verify(conn, "user salt", token, max_age: 86400) do
  #     {:ok, user_id} ->
  #       user = Repo.get!(User, user_id)
  #       {:ok, user}
  #
  #     {:error, _} ->
  #       :error
  #   end
  # end

  # def default_password(conn, %{"token" => token}) do
  #   with :error <- confirm_token(conn, token) do
  #     conn
  #     |> put_flash(:error, "Invalid/Expired token")
  #     |> redirect(to: Routes.user_path(conn, :forgot_password))
  #   else
  #     {:ok, user} ->
  #       pwd = random_string(6)
  #
  #       case Accounts.update_user(user, %{password: pwd, auto_password: "Y"}) do
  #         {:ok, _user} ->
  #           Email.password_alert(user.email, pwd)
  #
  #           conn
  #           |> put_flash(:info, "Password reset successful")
  #           |> redirect(to: Routes.session_path(conn, :new))
  #
  #         {:error, _reason} ->
  #           conn
  #           |> put_flash(:error, "An error occured, try again!")
  #           |> redirect(to: Routes.user_path(conn, :forgot_password))
  #       end
  #   end
  # end

  # def reset_pwd(conn, %{"id" => id}) do
  #   with :error <- confirm_token(conn, id) do
  #     conn
  #     |> put_flash(:error, "invalid token received")
  #     |> redirect(to: Routes.user_path(conn, :list_users))
  #   else
  #     {:ok, user} ->
  #       pwd = random_string(6)
  #       changeset = User.changeset(user, %{password: pwd, auto_password: "Y"})
  #
  #       Ecto.Multi.new()
  #       |> Ecto.Multi.update(:user, changeset)
  #       |> Ecto.Multi.insert(
  #         :user_log,
  #         User_log.changeset(
  #           %User_logs{},
  #           %{
  #             user_id: conn.assigns.user.id,
  #             activity: """
  #             Reserted account password for user with mail \"#{user.email}\"
  #             """
  #           }
  #         )
  #       )
  #       |> Repo.transaction()
  #       |> case do
  #         {:ok, %{user: user, user_log: _user_log}} ->
  #           Email.password(user.email, pwd)
  #           conn |> json(%{"info" => "Password changed to: #{pwd}"})
  #
  #         # conn |> json(%{"info" => "Password changed successfully"})
  #
  #         {:error, _failed_operation, failed_value, _changes_so_far} ->
  #           reason = traverse_errors(failed_value.errors) |> List.first()
  #           conn |> json(%{"error" => reason})
  #       end
  #   end
  # end

  # ------------------ / password reset -------------------
  def traverse_errors(errors) do
    for {key, {msg, _opts}} <- errors, do: "#{key} #{msg}"
  end

  def default_dashboard do
    today = Date.utc_today()
    days = Date.days_in_month(today)

    Date.range(%{today | day: 1}, %{today | day: days})
    |> Enum.map(&%{count: 0, day: "#{&1}", status: nil})
  end

  def random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
