 defmodule TestEntity do
   defstruct [:value, :token, id: 0]
 end

defmodule MnesiaDbManagerTest do
  use ExUnit.Case
  doctest MnesiaDbManager

  @test_entity %TestEntity{value: 15, token: "no token"}

  test "can be initialized" do
    init_table()
    assert MnesiaDbManager.init([]) == {:ok}
    clear_mnesia()
  end

  test "can create table" do
    init_table()
    MnesiaDbManager.init([])
    assert MnesiaDbManager.create_table(TestEntity) == {:ok}
    clear_mnesia()
  end

  test "can create entities" do
    init_table()
    assert seed_entity() == {:ok, 1}
    clear_mnesia()
  end

  test "can delete entity" do
    init_table()
    [to_delete | rest] = seed_many()
    assert MnesiaDbManager.delete(TestEntity, to_delete.id) == {:ok}
    assert MnesiaDbManager.get_all(TestEntity) == {:ok, rest}
    clear_mnesia()
  end

  test "can get entity" do
    init_table()
    {:ok, id} = seed_entity()
    assert MnesiaDbManager.get(TestEntity, id) == {:ok, %{@test_entity | id: id}}
    clear_mnesia()
  end

  test "can update entity" do
    init_table()
    {:ok, id} = seed_entity()
    {:ok, item} = MnesiaDbManager.get(TestEntity, id)
    assert MnesiaDbManager.update(TestEntity, id, %TestEntity{item | value: 21}) == {:ok}
    assert MnesiaDbManager.get(TestEntity, id) == {:ok, %TestEntity{item | value: 21}}
    clear_mnesia()
  end

  test "can get all entities" do
    init_table()
    result = seed_many()
    assert MnesiaDbManager.get_all(TestEntity) == {:ok, result}
    clear_mnesia()
  end

  test "can get all by pattern" do
    init_table()
    result = seed_many()
    filter = fn el -> el.value >= 17 end
    assert MnesiaDbManager.get_all(TestEntity, filter) == {:ok, result |> Enum.filter(filter)}
    clear_mnesia()
  end

  defp seed_many do
    {:ok, id_1} = seed_entity()
    {:ok, id_2} = MnesiaDbManager.create(TestEntity, %TestEntity{@test_entity | value: 16})
    {:ok, id_3} = MnesiaDbManager.create(TestEntity, %TestEntity{@test_entity | value: 17})
    {:ok, id_4} = MnesiaDbManager.create(TestEntity, %TestEntity{@test_entity | value: 18})
    {:ok, item_1} = MnesiaDbManager.get(TestEntity, id_1)
    {:ok, item_2} = MnesiaDbManager.get(TestEntity, id_2)
    {:ok, item_3} = MnesiaDbManager.get(TestEntity, id_3)
    {:ok, item_4} = MnesiaDbManager.get(TestEntity, id_4)
    [item_4, item_3, item_2, item_1]
  end

  defp clear_mnesia do
    :mnesia.stop()
    :ok = :mnesia.start()
    :ok = :mnesia.wait_for_tables([TestEntity], 5000)
  end

  defp init_table do
    MnesiaDbManager.init([])
    MnesiaDbManager.create_table(TestEntity)
  end

  defp seed_entity(%TestEntity{} = entity) do
    MnesiaDbManager.create(TestEntity, entity)
  end

  defp seed_entity do
    seed_entity(@test_entity)
  end
end
