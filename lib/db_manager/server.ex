defmodule DbManager.Server do
  alias DbManager.EntityService.Mnesia
  use GenServer

  # Client
  def start_link(_opts) do
    db_manager = Application.get_env(:crud_service, :db_manager, Mnesia)
    GenServer.start_link(__MODULE__, db_manager, name: __MODULE__)
  end

  @spec create_table(atom) :: :ok | {:error, term}
  def create_table(table) do
    GenServer.cast(__MODULE__, {:create_table, table})
  end

  @spec create(%{id: String.t()}) :: {:ok, String.t()} | {:error, term}
  def create(entity) do
    GenServer.call(__MODULE__, {:create, entity})
  end

  @spec update(%{id: String.t()}) :: :ok | {:error, term}
  def update(entity) do
    GenServer.cast(__MODULE__, {:update, entity})
  end

  @spec delete(atom, String.t()) :: :ok | {:error, term}
  def delete(table, id) do
    GenServer.cast(__MODULE__, {:delete, table, id})
  end

  @spec get_all(atom, {atom, atom, term} | [{atom, atom, term}]) ::
          {:ok, list(%{id: String.t()})} | {:error, term}
  def get_all(table, filter \\ []) do
    GenServer.call(__MODULE__, {:get_all, table, filter})
  end

  @spec get(atom, String.t()) :: {:ok, %{id: String.t()}} | {:error, term}
  def get(table, id) do
    GenServer.call(__MODULE__, {:get, table, id})
  end

  # Server
  @impl true
  def init(db_manager) do
    db_manager.init(nil)
    {:ok, db_manager}
  end

  @impl true
  def handle_call({:get, table, id}, _from, db_manager) do
    {:reply, db_manager.get(table, id), db_manager}
  end

  @impl true
  def handle_call({:get_all, table, filter}, _from, db_manager) do
    {:reply, db_manager.get_all(table, filter), db_manager}
  end

  @impl true
  def handle_call({:create, entity}, _from, db_manager) do
    {:reply, db_manager.create(entity), db_manager}
  end

  @impl true
  def handle_cast({:update, entity}, db_manager) do
    :ok = db_manager.update(entity)

    {:noreply, db_manager}
  end

  @impl true
  def handle_cast({:delete, table, id}, db_manager) do
    :ok = db_manager.delete(table, id)

    {:noreply, db_manager}
  end

  @impl true
  def handle_cast({:create_table, table}, db_manager) do
    :ok = db_manager.create_table(table)

    {:noreply, db_manager}
  end
end
