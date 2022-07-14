defmodule Isave.Repo do
  use Ecto.Repo,
    otp_app: :isave,
    # -------------------- postgres
    # adapter: Ecto.Adapters.Postgres
    # -------------------- mssql
    adapter: Ecto.Adapters.Tds

  use Scrivener, page_size: 10
end
