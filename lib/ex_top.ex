defmodule ExTop do
  use GenServer

  defstruct [:data]

  def start_link(opts \\ []) do
    GenServer.start_link ExTop, opts
  end

  def main(_) do
    ExTop.start_link
    :timer.sleep :infinity
  end

  def init(opts) do
    IO.write IO.ANSI.clear
    send self, :tick
    :timer.send_interval 1000, :tick
    {:ok, %ExTop{data: ExTop.Collector.collect}}
  end

  def handle_info(:tick, state) do
    GenServer.cast self, :render
    {:noreply, %{state | data: ExTop.Collector.collect}}
  end

  def handle_cast(:render, state) do
    IO.write [IO.ANSI.home, ExTop.View.render(state.data)]
    {:noreply, state}
  end
end
