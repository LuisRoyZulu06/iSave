defmodule Isave.Repo.Migrations.CreateTblUsers do
  use Ecto.Migration

  def change do
    create table(:tbl_users) do
      add :first_name, :string
      add :last_name, :string
      add :username, :string
      add :email, :string
      add :password, :string
      add :user_type, :integer
      add :user_role, :string
      add :user_status, :string
      add :auto_pwd, :string
      add :nrc_no, :string
      add :phone_no, :string
      add :residential_address, :string

      timestamps()
    end
  end
end
