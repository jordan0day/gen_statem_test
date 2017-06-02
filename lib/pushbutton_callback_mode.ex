defmodule PushbuttonCallbackMode do
  @behaviour :gen_statem

  # client api
  def start() do
    :gen_statem.start({:local, __MODULE__}, __MODULE__, [], [])
  end

  def push() do
    :gen_statem.call(__MODULE__, :push)
  end

  def get_count() do
    :gen_statem.call(__MODULE__, :get_count)
  end

  def stop() do
    :gen_statem.stop(__MODULE__)
  end

  # gen_statem required callbacks
  def callback_mode(), do: :handle_event_function

  def code_change(_vsn, state, data, _extra), do: {:ok, state, data}
  def terminate(_reason, _state, _data), do: :ok

  def init([]) do
    # Set the initial state + data. Data is used only as a counter.
    state = :off
    data = 0

    {:ok, state, data}
  end

  # state callbacks
  def handle_event({:call, from}, :push, :off, data) do
    # Go to "on", increment count and reply that the resulting status is "on"
    {:next_state, :on, data + 1, [{:reply, from, :on}]}
  end

  def handle_event({:call, from}, :push, :on, data) do
    # go to "off" and reply that the resulting status is "off"
    {:next_state, :off, data, [{:reply, from, :off}]}
  end

  # Handle events common to all states
  def handle_event({:call, from}, :get_count, state, data) do
    # reply with the current count
    {:next_state, state, data, [{:reply, from, data}]}
  end

  def handle_event(_, _, state, data) do
    # ignore all other events
    {:next_state, state, data}
  end
end
