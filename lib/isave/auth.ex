defmodule Isave.Auth do
  def confirm_password(%{password: password_hash} = user, password) do
    IO.inspect(password_hash)
    IO.inspect(Base.encode16(:crypto.hash(:sha512, password)))

    case Base.encode16(:crypto.hash(:sha512, password)) do
      pwd when pwd == password_hash ->
        {:ok, user}

      _ ->
        {:error, "Invalid username or password!"}
    end
  end
end
