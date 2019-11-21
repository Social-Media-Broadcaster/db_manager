defmodule TestEntity do
  defstruct [:value, :token, id: 0, prop_3: 0, prop_4: 0, prop_5: 0, prop_6: 0]
end

defmodule DbManagerTest do
  use ExUnit.Case
  doctest DbManager

  @test_entity %TestEntity{value: 15, token: "no token"}

  setup do
    clear_mnesia()
    init_table()
    on_exit(fn -> clear_mnesia() end)
  end

  test "can create entities" do
    send(self(), seed_entity())
    assert_received {:ok, _}
  end

  test "can delete entity" do
    [to_delete | rest] = seed_many()
    assert DbManager.delete(TestEntity, to_delete.id) == :ok
    assert DbManager.get_all(TestEntity) == {:ok, rest}
  end

  test "can get entity" do
    {:ok, id} = seed_entity()
    assert DbManager.get(TestEntity, id) == {:ok, %{@test_entity | id: id}}
  end

  test "can update entity" do
    {:ok, id} = seed_entity()
    {:ok, item} = DbManager.get(TestEntity, id)
    assert DbManager.update(%TestEntity{item | value: 21}) == :ok
    assert DbManager.get(TestEntity, id) == {:ok, %TestEntity{item | value: 21}}
  end

  test "can get all entities" do
    result = seed_many()
    assert DbManager.get_all(TestEntity) == {:ok, result}
  end

  test "can get all by pattern" do
    result = seed_many()
    filter = {:>=, :value, 17}
    assert DbManager.get_all(TestEntity, filter) == {:ok, result |> Enum.filter(&(&1.value >= 17))}
  end

  defp seed_many do
    {:ok, id_1} = seed_entity()
    :ok = :timer.sleep(300)
    {:ok, id_2} = DbManager.create(%TestEntity{@test_entity | value: 16})
    :ok = :timer.sleep(300)
    {:ok, id_3} = DbManager.create(%TestEntity{@test_entity | value: 17})
    :ok = :timer.sleep(300)
    {:ok, id_4} = DbManager.create(%TestEntity{@test_entity | value: 18})
    {:ok, item_1} = DbManager.get(TestEntity, id_1)
    {:ok, item_2} = DbManager.get(TestEntity, id_2)
    {:ok, item_3} = DbManager.get(TestEntity, id_3)
    {:ok, item_4} = DbManager.get(TestEntity, id_4)
    [item_4, item_3, item_2, item_1]
  end

  defp clear_mnesia do
    :mnesia.clear_table(TestEntity)
  end

  defp init_table do
    DbManager.create_table(TestEntity)
  end

  defp seed_entity(%TestEntity{} = entity) do
    DbManager.create(entity)
  end

  defp seed_entity do
    seed_entity(@test_entity)
  end
end
