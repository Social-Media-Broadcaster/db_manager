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
    field_names =
      table_name |> struct() |> Map.keys() |> Enum.filter(fn key -> key != :__struct__ end)

    case create_table(table_name, attributes: field_names ++ [:updated_at]) do
      {:ok, :already_exists} -> :mnesia.wait_for_tables([table_name], 5000)
      {:ok, _} -> :mnesia.add_table_index(table_name, :id)
      error -> error
    end
  end

  @impl true
  def create(_table_name, item) do
    id = UUID.uuid4()
    item_with_id = %{item | id: id}
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    tran = fn ->
      item_with_id
      |> Map.values()
      |> List.to_tuple()
      |> Tuple.append(timestamp)
      |> :mnesia.write()
    end

    case :mnesia.transaction(tran) do
      {_, :ok} -> {:ok, id}
      error -> {:error, error}
    end
  end

  @impl true
  def update(_table_name, _id, item) do
    [table_name, id | _] = values_list = Map.values(item)

    tran = fn ->
      :mnesia.delete({table_name, id})
      timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      values_list |> List.to_tuple() |> Tuple.append(timestamp) |> :mnesia.write()
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
    tran = fn -> :mnesia.read({table_name, id}) end

    with {:atomic, [item | _]} <- :mnesia.transaction(tran) do
      [_type | values] = item |> Tuple.to_list()
      {:ok, assemble_struct(table_name, values)}
    else
      {:atomic, []} -> {:error, :not_found}
      error -> {:error, error}
    end
  end

  @impl true
  def get_all(table_name) do
    keys_count = table_name |> struct() |> Map.values() |> Enum.count()

    selection =
      1..keys_count + 1
      |> Enum.map(fn i ->
        with 1 <- i do
          table_name
        else
          i -> String.to_existing_atom("$#{i}")
        end
      end)
      |> List.to_tuple()

    tran = fn -> :mnesia.select(table_name, [{selection, [], [:"$$"]}]) end

    with {:atomic, items} <- :mnesia.transaction(tran) do
      result =
        items
        |> Enum.sort(sort_fn())
        |> Enum.map(fn item -> assemble_struct(table_name, item) end)

      {:ok, result}
    else
      error -> {:error, error}
    end
  end

  @impl true
  def get_all(table_name, pattern) do
    keys_count = table_name |> struct() |> Map.values() |> Enum.count()

    selection =
      1..keys_count + 1
      |> Enum.map(fn i ->
        with 1 <- i do
          table_name
        else
          i -> String.to_existing_atom("$#{i}")
        end
      end)
      |> List.to_tuple()

    tran = fn -> :mnesia.select(table_name, [{selection, [], [:"$$"]}]) end

    with {:atomic, items} <- :mnesia.transaction(tran) do
      result =
        items
        |> Enum.sort(sort_fn())
        |> Enum.map(fn item -> assemble_struct(table_name, item) end)
        |> Enum.filter(pattern)

      {:ok, result}
    else
      error -> {:error, error}
    end
  end

  defp assemble_struct(table_name, item) do
    [_type | keys] = all_keys = Map.keys(struct(table_name))
    values = item |> List.delete_at(Enum.count(all_keys))

    struct(table_name, Enum.zip(keys, values))
  end

  defp create_table(table_name, options) do
    case :mnesia.create_table(table_name, [disc_copies: [node()]] ++ options) do
      {:atomic, :ok} -> {:ok, :new}
      {:aborted, {:already_exists, _table_name}} -> {:ok, :already_exists}
      other -> {:error, other}
    end
  end

  defp sort_fn, do: fn el_1, el_2 -> List.last(el_1) > List.last(el_2) end
end
