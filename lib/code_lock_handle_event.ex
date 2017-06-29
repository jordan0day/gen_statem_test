defmodule CodeLockHandleEvent do
  @behaviour :gen_statem

  # api
  def start_link(code) do
    :gen_statem.start_link({:local, __MODULE__}, __MODULE__, code, [])
  end

  def button(digit) do
    :gen_statem.cast(__MODULE__, {:button, digit})
  end

  def code_length() do
    :gen_statem.call(__MODULE__, :code_length)
  end
  

  # gen_statem callbacks
  def init(code) do
    # Process.flag(:trap_exit, true)
    do_lock()

    data = %{code: code, remaining: code}

    {:ok, :locked, data}
  end

  def callback_mode(), do: :handle_event_function

  def handle_event(:cast, {:button, digit}, state, %{code: code, remaining: remaining} = data) do
    case state do
      :locked ->
        case remaining do
          [^digit] ->
            # They've entered the full code
            do_unlock()
            {:next_state, :open, %{data | remaining: code}, [{:state_timeout, 10_000, :lock}]}
          [^digit | rest] ->
            # Correct so far, but not yet to the last digit
            {:next_state, :locked, %{data | remaining: rest}}
          _wrong ->
            # Incorrect digit entered
            {:next_state, :locked, %{data | remaining: code}}
        end
      :open ->
        {:keep_state, data}
    end
  end

  def handle_event(:state_timeout, :lock, :open, data) do
    do_lock()
    {:next_state, :locked, data}
  end

  def handle_event({:call, from}, :code_length, _state, %{code: code} = data) do
    {:keep_state, data, [{:reply, from, length(code)}]}
  end

  def code_change(_vsn, state, data, _extra) do
    {:ok, state, data}
  end

  def terminate(_reason, state, _data) do
    IO.puts "Shutting down..."
    if state != :locked do
      do_lock()
    end

    :ok
  end

  defp do_lock() do
    IO.puts "Lock"
  end

  defp do_unlock() do
    IO.puts "Unlock"
  end
end