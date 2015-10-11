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
  def handle_info({_port, {:data, "\e[A"}}, state) do
    selected = if state.selected == 0 do
      0
    else
      state.selected - 1
    end
    GenServer.cast self, :render
    {:noreply, %{state | selected: selected}}
  end

  # Down Arrow
  def handle_info({_port, {:data, "\e[B"}}, state) do
    max = Enum.count(state.data[:processes]) - 1
    selected = if state.selected >= max do
      max
    else
      state.selected + 1
    end
    GenServer.cast self, :render
    {:noreply, %{state | selected: selected}}
  end

  def handle_cast(:render, state) do
    IO.write [IO.ANSI.home,
              ExTop.View.render(state.data, selected: state.selected)]
    {:noreply, state}
  end
end
