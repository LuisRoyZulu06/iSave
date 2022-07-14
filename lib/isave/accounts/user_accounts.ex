defmodule Isave.Accounts.UserAccounts do
  use Ecto.Schema
  import Ecto.Changeset

  @fields ~w(id first_name last_name phone_no email user_type user_role user_status residential_address username nrc_no auto_pwd)a

  @derive {Jason.Encoder, only: @fields}

  schema "tbl_users" do
    field :auto_pwd, :string
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :username, :string
    field :nrc_no, :string
    field :password, :string
    field :phone_no, :string
    field :residential_address, :string
    field :user_role, :string
    field :user_status, :string
    field :user_type, :integer

    timestamps()
  end

  @doc false
  def changeset(user_accounts, attrs) do
    user_accounts
    |> cast(attrs, [
      :first_name,
      :last_name,
      :username,
      :email,
      :password,
      :user_type,
      :user_role,
      :user_status,
      :auto_pwd,
      :nrc_no,
      :phone_no,
      :residential_address
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :email,
      :password,
      :user_type,
      :user_role,
      :user_status,
      :auto_pwd,
      :nrc_no,
      :phone_no,
      :residential_address
    ])
    |> validate_length(:password,
      min: 4,
      max: 40,
      message: " Password should be atleast 4 to 40 characters"
    )
    |> validate_length(:username,
      min: 3,
      max: 40,
      message: "Username should be between 3 to 40 characters"
    )
    |> validate_length(:email,
      min: 10,
      max: 150,
      message: "Email address should be between 10 to 150 characters"
    )
    |> unique_constraint(:email, name: :unique_email, message: "Email address already in use.")
    |> unique_constraint(:username, name: :unique_username, message: "Username already in use.")
    |> put_pass_hash
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    Ecto.Changeset.put_change(changeset, :password, encrypt_password(password))
  end

  defp put_pass_hash(changeset), do: changeset

  def encrypt_password(password), do: Base.encode16(:crypto.hash(:sha512, password))
end

# Isave.Accounts.create_user_accounts(%{
#   first_name: "Luis Roy",
#   last_name: "Zulu",
#   username: "Luis",
#   email: "luis@probasegroup.com",
#   password: "password06",
#   auto_pwd: "Y",
#   user_type: 1,
#   user_status: "ACTIVE",
#   user_role: "BACKOFFICE",
#   nrc_no: "000000/10/1",
#   phone_no: "260979797337",
#   residential_address: "202/20",
#   inserted_at: NaiveDateTime.utc_now(),
#   updated_at: NaiveDateTime.utc_now()
# })
