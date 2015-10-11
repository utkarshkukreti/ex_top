defmodule ExTop do
  use GenServer

  defstruct [:data, selected: 0]

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
    selected = if state.selected == 0 do
      0
    else
      state.selected - 1
    end
    send self, {port, {:data, rest}}
    GenServer.cast self, :render
    {:noreply, %{state | selected: selected}}
  end

  # Down Arrow
  def handle_info({port, {:data, "\e[B" <> rest}}, state) do
    max = Enum.count(state.data[:processes]) - 1
    selected = if state.selected >= max do
      max
    else
      state.selected + 1
    end
    send self, {port, {:data, rest}}
    GenServer.cast self, :render
    {:noreply, %{state | selected: selected}}
  end

  # Empty
  def handle_info({_port, {:data, ""}}, state) do
    {:noreply, state}
  end

  def handle_cast(:render, state) do
    # Only show 20 processes at once.
    processes = Enum.take(state.data[:processes], 20)
    data = %{state.data | processes: processes}
    IO.write [IO.ANSI.home,
              ExTop.View.render(data, selected: state.selected)]
    {:noreply, state}
  end
end
