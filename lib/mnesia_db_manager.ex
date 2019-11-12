defmodule MnesiaDbManager do
  import Ex2ms

  @behaviour DbManager

  @impl true
  def init(_options) do
    case [:mnesia.create_schema([node()]), :mnesia.start()] do
      [:ok, :ok] -> :ok
      [{:error, {_, {:already_exists, _}}}, :ok] -> :ok
      [{:error, reason}, _] -> {:error, reason}
      [_, {:error, reason}] -> {:error, reason}
    end
  end

  @impl true
  def create_table(table_name) do
    case create_table(table_name, attributes: [:id, :item, :updated_at]) do
      {:ok, :already_exists} -> :mnesia.wait_for_tables([table_name], 5000)
      {:ok, _} -> :mnesia.add_table_index(table_name, :id)
      error -> error
    end
  end

  @impl true
  def create(table_name, item) do
    id = UUID.uuid4()
    item_with_id = %{item | id: id}
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    tran = fn -> :mnesia.write({table_name, id, item_with_id, timestamp}) end

    case :mnesia.transaction(tran) do
      {_, :ok} -> {:ok, id}
      error -> {:error, error}
    end
  end

  @impl true
  def update(table_name, id, item) do
    tran = fn ->
      :mnesia.delete({table_name, id})
      timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      :mnesia.write({table_name, id, %{item | id: id}, timestamp})
    end

    with {:ok, _el} <- get(table_name, id),
         {_, :ok} <- :mnesia.transaction(tran) do
      :ok
    else
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  @impl true
  def delete(table_name, id) do
    tran = fn -> :mnesia.delete({table_name, id}) end

    with {:ok, _el} <- get(table_name, id),
         {_, :ok} <- :mnesia.transaction(tran) do
      :ok
    else
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  @impl true
  def get(table_name, id) do
    filter =
      fun do
        {table_name, id, item, _updated_at} when table_name == ^table_name and id == ^id -> item
      end

    tran = fn -> :mnesia.select(table_name, filter) end

    case :mnesia.transaction(tran) do
      {:atomic, [item | _]} -> {:ok, item}
      {:atomic, []} -> {:error, :not_found}
      error -> {:error, error}
    end
  end

  @impl true
  def get_all(table_name) do
    filter =
      fun do
        {table_name, _id, item, updated_at} when table_name == ^table_name -> {item, updated_at}
      end

    tran = fn -> :mnesia.select(table_name, filter) end

    with {:atomic, items} <- :mnesia.transaction(tran) do
      result =
        items
        |> Enum.sort(sort_fn())
        |> Enum.map(fn {item, _} -> item end)

      {:ok, result}
    else
      error -> {:error, error}
    end
  end

  @impl true
  def get_all(table_name, pattern) do
    filter =
      fun do
        {table_name, _id, item, updated_at} when table_name == ^table_name -> {item, updated_at}
      end

    tran = fn -> :mnesia.select(table_name, filter) end

    with {:atomic, items} <- :mnesia.transaction(tran) do
      result =
        items
        |> Enum.sort(sort_fn())
        |> Enum.map(fn {item, _} -> item end)
        |> Enum.filter(pattern)

      {:ok, result}
    else
      error -> {:error, error}
    end
  end

  defp create_table(table_name, options) do
    case :mnesia.create_table(table_name, [disc_copies: [node()]] ++ options) do
      {:atomic, :ok} -> {:ok, :new}
      {:aborted, {:already_exists, _table_name}} -> {:ok, :already_exists}
      other -> {:error, other}
    end
  end

  defp sort_fn, do: fn {_, updated_at_1}, {_, updated_at_2} -> updated_at_1 > updated_at_2 end
end
