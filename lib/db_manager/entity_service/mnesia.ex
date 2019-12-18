defmodule DbManager.EntityService.Mnesia do
  alias DbManager.EntityService
  alias DbManager.EntityService.Utils

  @behaviour EntityService
  @behaviour EntityService.Initializer

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
    field_names = table_name |> struct() |> Map.keys() |> Enum.filter(&(&1 != :__struct__))

    case create_table(table_name, attributes: field_names ++ [:updated_at]) do
      {:ok, :already_exists} -> :mnesia.wait_for_tables([table_name], 5000)
      {:ok, _} -> :mnesia.add_table_index(table_name, :id)
      error -> error
    end
  end

  @impl true
  def create(item) do
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
  def update(item) do
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
  def get_all(table_name, pattern \\ []) do
    tran = fn -> :mnesia.select(table_name, build_filter(table_name, pattern)) end

    with {:atomic, items} <- :mnesia.transaction(tran) do
      result =
        items
        |> Enum.sort(sort_fn())
        |> Enum.map(&assemble_struct(table_name, &1))

      {:ok, result}
    else
      error -> {:error, error}
    end
  end

  @impl true
  def first(table_name, filter) do
    tran = fn -> :mnesia.select(table_name, build_filter(table_name, filter)) end

    with {:atomic, items} <- :mnesia.transaction(tran) do
      try do
        result =
          items
          |> Enum.map(&assemble_struct(table_name, &1))

        [first | _rest] = result

        {:ok, first}
      rescue
        _ -> {:error, :not_found}
      end
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

  defp sort_fn, do: &(List.last(&1) > List.last(&2))

  defp build_filter(table_name, pattern) do
    keys = table_name |> struct() |> Map.keys()
    selection = keys |> get_selection(table_name)
    guard = Utils.build(pattern, keys)
    [{selection, guard, [:"$$"]}]
  end

  defp get_selection(keys, table_name) do
    keys_count = keys |> Enum.count()

    1..(keys_count + 1)
    |> Enum.map(
      &with 1 <- &1 do
        table_name
      else
        i -> :"$#{i}"
      end
    )
    |> List.to_tuple()
  end
end
