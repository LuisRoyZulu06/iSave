defmodule Isave.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Isave.Repo

  alias Isave.Accounts.UserAccounts

  @doc """
  Returns the list of tbl_users.

  ## Examples

      iex> list_tbl_users()
      [%UserAccounts{}, ...]

  """
  def list_users do
    Repo.all(UserAccounts)
  end

  @doc """
  Gets a single user_accounts.

  Raises `Ecto.NoResultsError` if the User accounts does not exist.

  ## Examples

      iex> get_user_account!(123)
      %UserAccounts{}

      iex> get_user_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_account!(id), do: Repo.get!(UserAccounts, id)

  @doc """
  Creates a user_accounts.

  ## Examples

      iex> create_user_accounts(%{field: value})
      {:ok, %UserAccounts{}}

      iex> create_user_accounts(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_accounts(attrs \\ %{}) do
    %UserAccounts{}
    |> UserAccounts.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_accounts.

  ## Examples

      iex> update_user_accounts(user_accounts, %{field: new_value})
      {:ok, %UserAccounts{}}

      iex> update_user_accounts(user_accounts, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_accounts(%UserAccounts{} = user_accounts, attrs) do
    user_accounts
    |> UserAccounts.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_accounts.

  ## Examples

      iex> delete_user_accounts(user_accounts)
      {:ok, %UserAccounts{}}

      iex> delete_user_accounts(user_accounts)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_accounts(%UserAccounts{} = user_accounts) do
    Repo.delete(user_accounts)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_accounts changes.

  ## Examples

      iex> change_user_accounts(user_accounts)
      %Ecto.Changeset{data: %UserAccounts{}}

  """
  def change_user_accounts(%UserAccounts{} = user_accounts, attrs \\ %{}) do
    UserAccounts.changeset(user_accounts, attrs)
  end

  # -------------------------------- custom queries
  def get_user_by_username(username) do
    Repo.one(
      from(
        u in UserAccounts,
        where: fragment("lower(?) = lower(?)", u.username, ^username),
        limit: 1,
        select: u
      )
    )
    |> case do
      [] ->
        nil

      user ->
        user
    end
  end

  # ----- For active user
  def system_users(search_params) do
    UserAccounts
    # |> join(:left, [u], r in "tbl_user_role", on: u.role_id == r.id)
    |> where([u], u.user_status == "ACTIVE")
    # |> handle_user_filter(search_params)
    # |> order_by(desc: :inserted_at)
    # |> compose_user_select()
    # |> select_merge([_u, r], %{user_role: r.name})
    # |> Repo.paginate(page: page, page_size: size)
    |> Repo.all()
  end

  def system_users(search_params, page, size) do
    UserAccounts
    # |> join(:left, [u], r in "tbl_user_role", on: u.role_id == r.id)
    # |> where([u], u.status != "DELETED" and u.user_type !="3")
    |> handle_user_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_user_select()
    |> Repo.paginate(page: page, page_size: size)
  end

  # ----- For blocked user
  # def blocked_users(search_params) do
  #   UserAccounts
  #   |> where([u], u.user_status == "BLOCKED")
  #   |> Repo.all()
  # end

  def blocked_users(search_params, page, size) do
    UserAccounts
    |> where([u], u.user_status == "BLOCKED")
    |> handle_user_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_user_select()
    |> Repo.paginate(page: page, page_size: size)
  end

  defp handle_user_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        user_isearch_filter(query, sanitize_term(value))

      {"first_name", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("lower(?) LIKE lower(?)", a.first_name, ^sanitize_term(value)))

      {"last_name", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("lower(?) LIKE lower(?)", a.last_name, ^sanitize_term(value)))

      {"username", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("lower(?) LIKE lower(?)", a.username, ^sanitize_term(value)))

      {"email", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("lower(?) LIKE lower(?)", a.email, ^sanitize_term(value)))

      {"from", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("CAST(? AS DATE) >= ?", a.inserted_at, ^value))

      {"to", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("CAST(? AS DATE) <= ?", a.inserted_at, ^value))

      {_, _}, query ->
        # Not a where parameter
        query
    end)
  end

  defp user_isearch_filter(query, search_term) do
    where(
      query,
      [a],
      fragment("lower(?) LIKE lower(?)", a.first_name, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.last_name, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.username, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.email, ^search_term)
    )
  end

  defp sanitize_term(term), do: "%#{String.replace(term, "%", "\\%")}%"

  defp compose_user_select(query) do
    query
    |> select(
      [t],
      map(t, [
        :id,
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
        :residential_address,
        :inserted_at,
        :updated_at
      ])
    )
  end
end
