defmodule DbManager.Server do
  alias DbManager.EntityService.Mnesia
  use GenServer
  require Logger

  # Client
  def start_link(_opts) do
    entity_service = Application.get_env(:db_manager, :entity_service, Mnesia)
    GenServer.start_link(__MODULE__, entity_service, name: __MODULE__)
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
  def init(entity_service) do
    opts = Application.get_env(:db_manager, :options, nil)
    entity_service.init(opts)
    Logger.debug("#{__MODULE__} initialized with #{inspect(entity_service)} entity service with options: #{inspect(opts)}")
    {:ok, entity_service}
  end

  @impl true
  def handle_call({:get, table, id}, _from, entity_service) do
    {:reply, entity_service.get(table, id), entity_service}
  end

  @impl true
  def handle_call({:get_all, table, filter}, _from, entity_service) do
    {:reply, entity_service.get_all(table, filter), entity_service}
  end

  @impl true
  def handle_call({:create, entity}, _from, entity_service) do
    {:reply, entity_service.create(entity), entity_service}
  end

  @impl true
  def handle_cast({:update, entity}, entity_service) do
    :ok = entity_service.update(entity)

    {:noreply, entity_service}
  end

  @impl true
  def handle_cast({:delete, table, id}, entity_service) do
    :ok = entity_service.delete(table, id)

    {:noreply, entity_service}
  end

  @impl true
  def handle_cast({:create_table, table}, entity_service) do
    :ok = entity_service.create_table(table)

    {:noreply, entity_service}
  end
end
