defmodule DbManager do
  @callback init(table_name :: atom, opts :: term) :: {:ok} | {:error, reason :: term}
  @callback create(table_name :: atom, item :: %{id: number | String.t}) :: {:ok, id :: number | String.t} | {:error, reason :: term}
  @callback update(table_name :: atom, id :: number | String.t, item :: %{id: number | String.t}) :: {:ok} | {:error, reason :: term}
  @callback delete(table_name :: atom, id :: number | String.t) :: {:ok} | {:error, reason :: term}
  @callback get(table_name :: atom, id :: number | String.t) :: {:ok, %{id: number | String.t}} | {:error, reason :: term}
  @callback get_all(table_name :: atom) :: {:ok, list(%{id: number | String.t})}
  @callback get_all(table_name :: atom, pattern :: %{id: number | String.t}) :: {:ok, list(%{id: number | String.t})}
end
