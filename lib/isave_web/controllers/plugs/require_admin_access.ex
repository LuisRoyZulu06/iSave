defmodule IsaveWeb.Plugs.RequireAdminAccess do
  @behaviour Plug
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  alias Isave.Accounts

  def init(_params) do
  end

  def call(conn, _params) do
    user_id = get_session(conn, :current_user) || get_session(conn, :current_client)
    user = user_id && Accounts.get_user_account!(user_id)

    with true <- not is_nil(user) && user.user_role != "BACKOFFICE" do
      conn
      |> put_flash(:error, "Access denied!!!")
      |> redirect(to: IsaveWeb.Router.Helpers.session_path(conn, :new))
      |> halt()
    else
      _ -> conn
    end
  end
end
