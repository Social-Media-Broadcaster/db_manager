defmodule DbManagerTest do
  use ExUnit.Case
  doctest DbManager

  test "greets the world" do
    assert DbManager.hello() == :world
  end
end
