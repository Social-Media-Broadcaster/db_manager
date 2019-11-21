defmodule DbManager.EntityService.Utils do
  # taken from https://github.com/sheharyarn/memento/blob/master/lib/memento/query/spec.ex as a temporary solution

  def build(guards, keys_list) when is_list(guards) do
    translate(keys_list, guards)
  end

  def build(guard, keys_list) when is_tuple(guard) do
    build([guard], keys_list)
  end

  defp rewrite_guard(:or), do: :orelse
  defp rewrite_guard(:and), do: :andalso
  defp rewrite_guard(:<=), do: :"=<"
  defp rewrite_guard(:!=), do: :"/="
  defp rewrite_guard(:===), do: :"=:="
  defp rewrite_guard(:!==), do: :"=/="
  defp rewrite_guard(term), do: term

  defp translate(keys_list, list) when is_list(list) do
    Enum.map(list, &translate(keys_list, &1))
  end

  defp translate(keys_list, atom) when is_atom(atom) do
    case Enum.find_index(keys_list, &(&1 == atom)) do
      nil -> atom
      value -> :"$#{value + 1}"
    end
  end

  defp translate(map, {operation, arg1, arg2}) do
    {
      rewrite_guard(operation),
      translate(map, arg1),
      translate(map, arg2)
    }
  end

  defp translate(_map, term) do
    term
  end
end
