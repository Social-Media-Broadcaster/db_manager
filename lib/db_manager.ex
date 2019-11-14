defmodule DbManager do
  @callback init(opts :: term) :: :ok | {:error, reason :: term}
  @callback create_table(table_name :: atom) :: :ok | {:error, reason :: term}
  @callback create(item :: %{id: number}) :: {:ok, id :: String.t()} | {:error, reason :: term}
  @callback update(tem :: %{id: number}) :: :ok | {:error, reason :: term}
  @callback delete(table_name :: atom, id :: String.t()) :: :ok | {:error, reason :: term}
  @callback get(table_name :: atom, id :: String.t()) ::
              {:ok, %{id: number}} | {:error, reason :: term}
  @callback get_all(table_name :: atom) :: {:ok, list(%{id: number})}
  @callback get_all(table_name :: atom, pattern :: {atom, atom, term} | [{atom, atom, term}]) ::
              {:ok, list(%{id: number})}
end
