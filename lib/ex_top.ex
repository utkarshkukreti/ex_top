defmodule ExTop do
  use GenServer

  defstruct [:data, selected: 0, offset: 0]

  def start_link(opts \\ []) do
    GenServer.start_link ExTop, opts
  end

  def main(_) do
    ExTop.start_link
    :timer.sleep :infinity
  end

  def init(opts) do
    Port.open({:spawn, "tty_sl -c -e"}, [:binary, :eof])
    IO.write IO.ANSI.clear
    send self, :tick
    :timer.send_interval 1000, :tick
    {:ok, %ExTop{data: ExTop.Collector.collect}}
  end

  def handle_info(:tick, state) do
    GenServer.cast self, :render
    {:noreply, %{state | data: ExTop.Collector.collect}}
  end

  # Up Arrow
  def handle_info({port, {:data, "\e[A" <> rest}}, state) do
    state = case {state.selected, state.offset} do
              {0, 0} -> state
              {0, n} -> %{state | offset: n - 1}
              {n, _} -> %{state | selected: n - 1}
            end
    send self, {port, {:data, rest}}
    GenServer.cast self, :render
    {:noreply, state}
  end

  # Down Arrow
  def handle_info({port, {:data, "\e[B" <> rest}}, state) do
    max = Enum.count(state.data[:processes]) - 1
    state = cond do
      state.offset + state.selected + 1 >= max -> state
      state.selected == 19 -> %{state | offset: state.offset + 1}
      true -> %{state | selected: state.selected + 1}
    end
    send self, {port, {:data, rest}}
    GenServer.cast self, :render
    {:noreply, state}
  end

  # Empty
  def handle_info({_port, {:data, ""}}, state) do
    {:noreply, state}
  end

  def handle_cast(:render, state) do
    # Only show 20 processes at once.
    processes = state.data[:processes]
                |> Enum.drop(state.offset)
                |> Enum.take(20)
    data = %{state.data | processes: processes}
    IO.write [IO.ANSI.home,
              ExTop.View.render(data, selected: state.selected)]
    {:noreply, state}
  end
end
