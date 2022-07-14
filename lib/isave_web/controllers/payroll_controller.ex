defmodule IsaveWeb.PayrollController do
  use IsaveWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
