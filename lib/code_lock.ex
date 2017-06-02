defmodule CodeLock do
  @behaviour :gen_statem

  # api
  def start_link(code) do
    :gen_statem.start_link({:local, __MODULE__}, __MODULE__, code, [])
  end

  def button(digit) do
    :gen_statem.cast(__MODULE__, {:button, digit})
  end

  # gen_statem callbacks
  def init(code) do
    do_lock()

    data = %{code: code, remaining: code}

    {:ok, :locked, data}
  end

  def callback_mode(), do: :state_functions

  def locked(:cast, {:button, digit}, %{code: code, remaining: remaining} = data) do
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
  end

  def open(:state_timeout, :lock, data) do
    do_lock()
    {:next_state, :locked, data}
  end

  def open(:cast, {:button, _}, data) do
    # If they press a button while it's already unlocked, do nothing.
    {:next_state, :open, data}
  end

  def terminate(_reason, state, _data) do
    if state != :locked do
      do_lock()
    end

    :ok
  end

  def code_change(_vsn, state, data, _extra) do
    {:ok, state, data}
  end

  defp do_lock() do
    IO.puts "Lock"
  end

  defp do_unlock() do
    IO.puts "Unlock"
  end
end
