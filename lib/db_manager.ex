defmodule DbManager do
  alias DbManager.{EntityService, Server}
  @behaviour EntityService

  @impl true
  defdelegate create_table(table), to: Server
  @impl true
  defdelegate get(table, id), to: Server
  @impl true
  defdelegate get_all(table, filter \\ []), to: Server
  @impl true
  defdelegate create(entity), to: Server
  @impl true
  defdelegate update(entity), to: Server
  @impl true
  defdelegate delete(table, id), to: Server
end
