defmodule ExTop do
  use GenServer

  defstruct [:node, :data, :schedulers_snapshot,
             selected: 0, offset: 0, sort_by: :pid, sort_order: :ascending,
             paused?: false]

  def start_link(opts \\ []) do
    GenServer.start_link ExTop, opts
  end

  def main(args) do
    {opts, args, _} = OptionParser.parse(args)

    result = cond do
      sname = Keyword.get(opts, :sname) ->
        Node.start String.to_atom(sname), :shortnames
      name = Keyword.get(opts, :name) ->
        Node.start String.to_atom(name), :longnames
      true ->
        Node.start :ex_top, :shortnames
    end

    case result do
      {:ok, _} -> :ok
      {:error, _} ->
        IO.write [IO.ANSI.red,
                  "Failed to start a distributed Node.\n",
                  "Make sure `epmd` (the Erlang Port Mapper Daemon) is ",
                  "running by executing `epmd -daemon` in your shell.\n",
                  IO.ANSI.reset]
        :erlang.halt
    end

    if cookie = Keyword.get(opts, :cookie) do
      Node.set_cookie(String.to_atom(cookie))
    end

    node = case args do
             [] -> Node.self
             [node] -> String.to_atom(node)
           end

    if Node.ping(node) == :pang do
      IO.write [IO.ANSI.red,
                "Could not connect to node #{node} with cookie #{Node.get_cookie}\n",
                IO.ANSI.reset]
      :erlang.halt
    end

    # Load ExTop.Collector on the target node.
    {mod, bin, file} = :code.get_object_code(ExTop.Collector)
    :rpc.call node, :code, :load_binary, [mod, file, bin]
    # Enable :scheduler_wall_time on the target node.
    # FIXME: Is this a good idea?
    :rpc.call node, :erlang, :system_flag, [:scheduler_wall_time, true]

    {:ok, _} = ExTop.start_link(node: node)
    :timer.sleep :infinity
  end

  def init(opts) do
    Port.open({:spawn, "tty_sl -c -e"}, [:binary, :eof])
    IO.write IO.ANSI.clear
    send self, :collect
    {:ok, %ExTop{node: Keyword.get(opts, :node, Node.self)}}
  end

  def handle_info(:collect, %{paused?: paused?} = state) do
    if paused? do
      Process.send_after self, :collect, 1000
      {:noreply, state}
    else
      GenServer.cast self, :render
      schedulers_snapshot = state.data && state.data.schedulers
      data = :rpc.call state.node, ExTop.Collector, :collect, []
      Process.send_after self, :collect, 1000
      {:noreply, %{state | data: data, schedulers_snapshot: schedulers_snapshot}}
    end
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
    sort_by = case (ch - ?0) do
                1 -> :pid
                2 -> :name_or_initial_call
                3 -> :memory
                4 -> :reductions
                5 -> :message_queue_len
                6 -> :current_function
              end
    state = if state.sort_by == sort_by do
      if state.sort_order == :ascending do
        %{state | sort_order: :descending}
      else
        %{state | sort_order: :ascending}
      end
    else
      %{state | sort_by: sort_by, sort_order: :ascending}
    end
    GenServer.cast self, :render
    send self, {port, {:data, rest}}
    {:noreply, state}
  end
  def handle_info({port, {:data, "g" <> rest}}, state) do
    state = %{state | offset: 0, selected: 0}
    GenServer.cast self, :render
    send self, {port, {:data, rest}}
    {:noreply, state}
  end
  def handle_info({port, {:data, "G" <> rest}}, state) do
    last = Enum.count(state.data.processes)
    state = %{state | offset: last - 20, selected: 19}
    GenServer.cast self, :render
    send self, {port, {:data, rest}}
    {:noreply, state}
  end
  def handle_info({port, {:data, "p" <> rest}}, %{paused?: paused?} = state) do
    state = %{state | paused?: not paused?}
    send self, {port, {:data, rest}}
    {:noreply, state}
  end
  def handle_info({_port, {:data, "q" <> _rest}}, _state) do
    :erlang.halt
  end
  def handle_info({_port, {:data, _}}, state) do
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
      |> Enum.sort_by(fn process -> process[state.sort_by] end)
      |> (fn processes ->
        if state.sort_order == :ascending do
          processes
        else
          Enum.reverse(processes)
        end
      end).()
      |> Enum.drop(state.offset)
      |> Enum.take(20)
    data = %{state.data | processes: processes}
           |> Map.put(:schedulers_snapshot, state.schedulers_snapshot)
    IO.write [IO.ANSI.home,
              ExTop.View.render(data, selected: state.selected)]
    {:noreply, state}
  end
end
