defmodule TestEntity do
  defstruct [:value, :token, id: 0]
end

defmodule MnesiaDbManagerTest do
  use ExUnit.Case
  doctest MnesiaDbManager

  @test_entity %TestEntity{value: 15, token: "no token"}

  setup do
    clear_mnesia()
    init_table()
    on_exit(fn -> clear_mnesia() end)
  end

  test "can be initialized" do
    assert MnesiaDbManager.init([]) == :ok
  end

  test "can create table" do
    MnesiaDbManager.init([])
    assert MnesiaDbManager.create_table(TestEntity) == :ok
  end

  test "can create entities" do
    send(self(), seed_entity())
    assert_received {:ok, _}
  end

  test "can delete entity" do
    [to_delete | rest] = seed_many()
    assert MnesiaDbManager.delete(TestEntity, to_delete.id) == :ok
    assert MnesiaDbManager.get_all(TestEntity) == {:ok, rest}
  end

  test "can get entity" do
    {:ok, id} = seed_entity()
    assert MnesiaDbManager.get(TestEntity, id) == {:ok, %{@test_entity | id: id}}
  end

  test "can update entity" do
    {:ok, id} = seed_entity()
    {:ok, item} = MnesiaDbManager.get(TestEntity, id)
    assert MnesiaDbManager.update(%TestEntity{item | value: 21}) == :ok
    assert MnesiaDbManager.get(TestEntity, id) == {:ok, %TestEntity{item | value: 21}}
  end

  test "can get all entities" do
    result = seed_many()
    assert MnesiaDbManager.get_all(TestEntity) == {:ok, result}
  end

  test "can get all by pattern" do
    result = seed_many()
    filter = {:>=, :value, 17}
    assert MnesiaDbManager.get_all(TestEntity, filter) == {:ok, result |> Enum.filter(&(&1.value >= 17))}
  end

  defp seed_many do
    {:ok, id_1} = seed_entity()
    :ok = :timer.sleep(300)
    {:ok, id_2} = MnesiaDbManager.create(%TestEntity{@test_entity | value: 16})
    :ok = :timer.sleep(300)
    {:ok, id_3} = MnesiaDbManager.create(%TestEntity{@test_entity | value: 17})
    :ok = :timer.sleep(300)
    {:ok, id_4} = MnesiaDbManager.create(%TestEntity{@test_entity | value: 18})
    {:ok, item_1} = MnesiaDbManager.get(TestEntity, id_1)
    {:ok, item_2} = MnesiaDbManager.get(TestEntity, id_2)
    {:ok, item_3} = MnesiaDbManager.get(TestEntity, id_3)
    {:ok, item_4} = MnesiaDbManager.get(TestEntity, id_4)
    [item_4, item_3, item_2, item_1]
  end

  defp clear_mnesia do
    :mnesia.clear_table(TestEntity)
  end

  defp init_table do
    MnesiaDbManager.init([])
    MnesiaDbManager.create_table(TestEntity)
  end

  defp seed_entity(%TestEntity{} = entity) do
    MnesiaDbManager.create(entity)
  end

  defp seed_entity do
    seed_entity(@test_entity)
  end
end
