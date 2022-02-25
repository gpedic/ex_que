# Q

Q attempts to provide a way to queue execution with behavior similar to Ecto.Multi.
Operations are queued and executed in order and the results of every processing step are accumulated. 
In case of error all interim results are available which simplifies error handling.

```elixir
    iex> pipeline = Q.new()
    |> Q.put(:init, %{test: "setup"})
    |> Q.run(:read, fn _ -> {:ok, "Once upon a time ..."} end)

    iex> pipeline |> Q.exec()

    {:ok, %{init: %{test: "setup"}, read: "Once upon a time ..."}}


    iex> pipeline 
    |> Q.run(:write, fn %{read: _read} -> {:error, :write_failed} end)
    |> Q.exec()

    {:error, :write, :write_failed, %{init: %{test: "setup"}, read: "Once upon a time ..."}
```

## Comparison

As mentioned previously considerable benefit of Q over using regular with is that the results of all steps
are available until the error.

```elixir
  account_id = 1234
  with {:ok, account} <- Accounts.fetch_account(account_id),
    {:ok, post} <- Accounts.create_post(account, "test") do
    broadcast(post)
  else
    {:error, :create_post_failed} = error ->
      Logger.error("Failed to create post for account #{account_id}")
      error
    {:error, error} = error ->
      Logger.error(error)
      error
  end
```
### Note
* `account` is not available if for error handling if create_post fails
* `create_post/2` has to return a special error tuple for it to be identifiable


```elixir
  pipeline = Q.new()
  |> Q.put(:account_id, 1234)
  |> Q.run(:account, fn %{account_id: id} -> Accounts.fetch_account(1234) end)
  |> Q.run(:post, fn %{account: account} -> Account.create_post(account, "test") end)

  with {:ok, %{post: post}} <- Q.exec(pipeline) do
    broadcast(post)
  else
    {:error, :post, failed_value, %{account: account}} ->
      Logger.error("Failed to create post for account #{account.id}")
      {:error, failed_value}
    {:error, failed_operation, failed_value, _changes_so_far} ->
      Logger.error("Operation #{failed_operation} failed, #{inspect(failed_value)}")
      {:error, failed_value}
  end
```
### Note
* `account` is available if for error handling if create_post fails
* `create_post/2` can return a regular error tuple since every step is named

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `que` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:que, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/que](https://hexdocs.pm/que).

