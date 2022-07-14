defmodule Isave.Logs.User_logs do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_user_logs" do
    field :activity, :string
    # field :user_id, :string

    belongs_to :user, Isave.Accounts.UserAccounts, foreign_key: :user_id, type: :id
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_logs, attrs) do
    user_logs
    |> cast(attrs, [:id, :activity, :user_id])
    |> validate_required([:activity, :user_id])
  end
end
