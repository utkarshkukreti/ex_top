defmodule ExTop do
  use GenServer

  defstruct [:node, :data, selected: 0, offset: 0, sort_by: 1]

  def start_link(opts \\ []) do
    GenServer.start_link ExTop, opts
  end

  def main(args) do
    {opts, args, _} = OptionParser.parse(args)

    name = Keyword.get(opts, :name, "ex_top") |> String.to_atom

    Node.start(name, :shortnames)

    if cookie = Keyword.get(opts, :cookie) do
      Node.set_cookie(String.to_atom(cookie))
    end

    node = case args do
             [] -> Node.self
             [node] -> String.to_atom(node)
           end
    :pong = Node.ping(node)

    # Load ExTop.Collector on the target node.
    {mod, bin, file} = :code.get_object_code(ExTop.Collector)
    :rpc.call node, :code, :load_binary, [mod, file, bin]

    ExTop.start_link node: node
    :timer.sleep :infinity
  end

  def init(opts) do
    Port.open({:spawn, "tty_sl -c -e"}, [:binary, :eof])
    IO.write IO.ANSI.clear
    send self, :tick
    :timer.send_interval 1000, :tick
    {:ok, %ExTop{node: Keyword.get(opts, :node, Node.self)}}
  end

  def handle_info(:tick, state) do
    GenServer.cast self, :render
    data = :rpc.call state.node, ExTop.Collector, :collect, []
    {:noreply, %{state | data: data}}
  end

  def handle_info({port, {:data, "\e[A" <> rest}}, state) do
    GenServer.cast self, {:key, :up}
    send self, {port, {:data, rest}}
    {:noreply, state}
  end
  def handle_info({port, {:data, "\e[B" <> rest}}, state) do
    GenServer.cast self, {:key, :down}
    send self, {port, {:data, rest}}
    {:noreply, state}
  end
  def handle_info({port, {:data, "j" <> rest}}, state) do
    GenServer.cast self, {:key, :down}
    send self, {port, {:data, rest}}
    {:noreply, state}
  end
  def handle_info({port, {:data, "k" <> rest}}, state) do
    GenServer.cast self, {:key, :up}
    send self, {port, {:data, rest}}
    {:noreply, state}
  end
  def handle_info({port, {:data, <<ch :: utf8, rest :: binary>>}}, state) when ch in '123456' do
    state = %{state | sort_by: ch - ?0}
    GenServer.cast self, :render
    send self, {port, {:data, rest}}
    {:noreply, state}
  end
  def handle_info({_port, {:data, ""}}, state) do
    {:noreply, state}
  end

  def handle_cast({:key, :up}, state) do
    state = case {state.selected, state.offset} do
              {0, 0} -> state
              {0, n} -> %{state | offset: n - 1}
              {n, _} -> %{state | selected: n - 1}
            end
    GenServer.cast self, :render
    {:noreply, state}
  end

  def handle_cast({:key, :down}, state) do
    max = Enum.count(state.data[:processes]) - 1
    state = cond do
      state.offset + state.selected + 1 >= max -> state
      state.selected == 19 -> %{state | offset: state.offset + 1}
      true -> %{state | selected: state.selected + 1}
    end
    GenServer.cast self, :render
    {:noreply, state}
  end

  def handle_cast(:render, state) do
    processes =
      state.data[:processes]
      |> Enum.sort_by(fn process ->
        case state.sort_by do
          1 -> process[:pid]
          2 -> process[:registered_name]
          3 -> process[:memory]
          4 -> process[:reductions]
          5 -> process[:message_queue_len]
          6 -> process[:current_function]
        end
      end)
      |> Enum.drop(state.offset)
      |> Enum.take(20)
    data = %{state.data | processes: processes}
    IO.write [IO.ANSI.home,
              ExTop.View.render(data, selected: state.selected)]
    {:noreply, state}
  end
end
