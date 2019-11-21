defmodule DbManager.EntityService.Ets do
  alias :ets, as: Ets
  alias DbManager.EntityService
  alias DbManager.EntityService.Utils

  @behaviour EntityService
  @behaviour EntityService.Initializer

  @impl true
  def init(_opts), do: :ok

  @impl true
  def create_table(table) do
    Ets.new(table, [:set, :protected, :named_table])
    :ok
  end

  @impl true
  def create(item) do
    id = UUID.uuid4()
    item_with_id = %{item | id: id}
    [table | result] = disassemble_struct(item_with_id)

    if Ets.insert_new(table, result |> List.to_tuple()) do
      {:ok, id}
    else
      {:error, :create_failed}
    end
  end

  @impl true
  def update(item) do
    [table | result] = disassemble_struct(item)

    case Ets.lookup(table, item.id) do
      [] ->
        {:error, :not_found}

      _ ->
        Ets.delete(table, item.id)
        Ets.insert_new(table, result |> List.to_tuple())
        :ok
    end
  end

  @impl true
  def delete(table, id) do
    case Ets.lookup(table, id) do
      [] ->
        {:error, :not_found}

      _ ->
        Ets.delete(table, id)
        :ok
    end
  end

  @impl true
  def get_all(table, pattern \\ []) do
    raw_result = Ets.select(table, build_filter(table, pattern))

    result =
      raw_result
      |> Enum.sort(sort_fn())
      |> Enum.map(&assemble_struct(&1, table))

    {:ok, result}
  end

  @impl true
  def get(table, id) do
    case Ets.lookup(table, id) do
      [] ->
        {:error, :not_found}

      items ->
        item = items |> List.first() |> assemble_struct(table)
        {:ok, item}
    end
  end

  defp sort_fn, do: &(List.last(&1) > List.last(&2))

  defp assemble_struct(item, table_name) when is_list(item) do
    [_type | keys] = table_name |> struct() |> Map.keys()
    values = item |> List.delete_at(Enum.count(keys))
    struct(table_name, Enum.zip(keys, values))
  end

  defp assemble_struct(item, table_name) when is_tuple(item) do
    [_type | keys] = table_name |> struct() |> Map.keys()
    values = item |> Tuple.to_list() |> List.delete_at(Enum.count(keys))
    struct(table_name, Enum.zip(keys, values))
  end

  defp disassemble_struct(item) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    Map.values(item) ++ [timestamp]
  end

  defp build_filter(table_name, pattern) do
    keys = table_name |> struct() |> Map.keys()
    selection = get_selection(keys)
    guard = Utils.build(pattern, keys |> List.delete_at(0))
    [{selection, guard, [:"$$"]}]
  end

  defp get_selection(keys) do
    keys_count = keys |> Enum.count()

    1..(keys_count)
    |> Enum.map(&:"$#{&1}")
    |> List.to_tuple()
  end
end
