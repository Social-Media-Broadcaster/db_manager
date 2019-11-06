defmodule MnesiaDbManager do
  @behaviour DbManager

  @counter_table_name :counter_table

  def init(_options) do
    :mnesia.create_schema([__MODULE__])
    :mnesia.start()
  end

  def create_table(table_name) do
    case create_table(table_name, [attributes: [:id, :item]]) do
      {:ok, _} ->
        :mnesia.add_table_index(table_name, :id)
        init_counter(table_name)
      error -> error
    end
  end

  def create(table_name, item) do
    id = :mnesia.dirty_update_counter(@counter_table_name, table_name, 1)
    item_with_id = %{item | id: id}
    tran = fn ->
      :mnesia.write({table_name, id, item_with_id})
    end
    case :mnesia.transaction(tran) do
      {_, :ok} -> {:ok, id}
      error -> {:error, error}
    end
  end

  def update(table_name, id, item) do
    case get(table_name, id) do
      {:error, reason} -> {:error, reason}
      _ ->
        tran = fn ->
          :mnesia.delete({table_name, id})
          :mnesia.write({table_name, id, item})
        end
        case :mnesia.transaction(tran) do
          {_, :ok} -> {:ok}
          error -> {:error, error}
        end
    end
  end

  def delete(table_name, id) do
    case get(table_name, id) do
      {:error, reason} -> {:error, reason}
      _ ->
        tran = fn ->
          :mnesia.delete({table_name, id})
        end
        case :mnesia.transaction(tran) do
          {_, :ok} -> {:ok}
          error -> {:error, error}
        end
    end
  end

  def get(table_name, id) do
    tran = fn ->
      :mnesia.select(table_name, [{{table_name, :"$1",  :"$2"}, [{:==, :"$1", id}], [:"$2"]}])
    end
    case :mnesia.transaction(tran) do
      {:atomic, [item | _]} -> {:ok, item}
      {:atomic, []} -> {:error, :not_found}
      error -> {:error, error}
    end
  end

  def get_all(table_name) do
    tran = fn ->
      :mnesia.match_object({table_name, :_, :_})
    end
    case :mnesia.transaction(tran) do
      {:atomic, items} -> {:ok, Enum.map(items, fn {_, _, item} -> item end)}
      error -> {:error, error}
    end
  end

  def get_all(table_name, pattern) do
    tran = fn ->
      :mnesia.match_object({table_name, :_, pattern})
    end
    case :mnesia.transaction(tran) do
      {:atomic, items} -> {:ok, Enum.map(items, fn {_, _, item} -> item end)}
      error -> {:error, error}
    end
  end

  defp create_table(table_name, options) do
    case :mnesia.create_table(table_name, options) do
      {:atomic, :ok} -> {:ok, []}
      {:aborted, {:already_exists, _table_name}} ->
        :mnesia.wait_for_tables([table_name], 5000)
        {:ok, []}
      other -> {:error, other}
    end
  end

  defp init_counter(table_name) do
    create_table(@counter_table_name, [attributes: [table_name, :id]])
    tran = fn ->
      :mnesia.write({@counter_table_name, table_name, 0})
    end
    case :mnesia.transaction(tran) do
      {:atomic, :ok} -> {:ok, []}
      other -> {:error, other}
    end
  end
end
