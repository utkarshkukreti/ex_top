defmodule ExTop.View do
  @columns [{"PID", 13, :right},
            {"Registered Name", 24, :left},
            {"Memory", 9, :right},
            {"Reductions", 10, :right},
            {"Message Queue", 13, :right},
            {"Current Function", 32, :left}]

  def render(data, opts \\ []) do
    [concat(system(data[:system]),
            memory(data[:memory])),
     separator,
     heading,
     separator,
     rows(data[:processes], opts),
     separator] |> Enum.intersperse("\n\r")
  end

  defp system(system) do
    ["+---------------+------------",
     "            Statistics       ",
     "+---------------+------------",
     "| Uptime        | #{just(inspect(system[:uptime]), 9, :right)}s ",
     "| Process Count | #{just(inspect(system[:process_count]), 10, :right)} ",
     "| Process Limit | #{just(inspect(system[:process_limit]), 10, :right)} ",
     "| Run Queue     | #{just(inspect(system[:run_queue]), 10, :right)} ",
     "| IO Input      | #{just(inspect(system[:io_input]), 10, :right)} ",
     "| IO Output     | #{just(inspect(system[:io_output]), 10, :right)} "]
  end

  defp memory(memory) do
    ["+-------------+-----------+",
     "|          Memory         |",
     "+-------------+-----------+",
     "| Total       | #{just(inspect(memory[:total]), 9, :right)} |",
     "| Processes   | #{just(inspect(memory[:processes]), 9, :right)} |",
     "| Atom        | #{just(inspect(memory[:atom]), 9, :right)} |",
     "| Binary      | #{just(inspect(memory[:binary]), 9, :right)} |",
     "| Code        | #{just(inspect(memory[:code]), 9, :right)} |",
     "| ETS         | #{just(inspect(memory[:ets]), 9, :right)} |"]
  end

  defp separator do
    [?+,
    for {_, size, _} <- @columns do
      String.duplicate("-", size + 2)
    end |> Enum.intersperse(?+),
    ?+]
  end

  defp heading do
    ["| ",
    for {name, size, align} <- @columns do
      just(name, size, align)
    end |> Enum.intersperse(" | "),
    " |"]
  end

  defp rows(processes, opts) do
    for {process, index} <- Enum.with_index(processes) do
      row = ["| ",
       for {name, size, align} <- @columns do
         text = case name do
           "PID" -> IO.iodata_to_binary(:erlang.pid_to_list(process[:pid]))
           "Registered Name" -> inspect(process[:registered_name])
           "Memory" -> inspect(process[:memory])
           "Reductions" -> inspect(process[:reductions])
           "Message Queue" -> inspect(process[:message_queue_len])
           "Current Function" ->
             {m, f, a} = process[:current_function]
             "#{inspect(m)}.#{f}/#{a}"
         end
         just(text, size, align)
       end |> Enum.intersperse(" | "),
       " |"]
      if opts[:selected] == index do
        [IO.ANSI.blue_background, IO.ANSI.white, row, IO.ANSI.reset]
      else
        row
      end
    end |> Enum.intersperse("\n\r")
  end

  defp just(string, length, align) do
    if String.length(string) > length do
      String.slice(string, 0, length - 1) <> "…"
    else
      case align do
        :left -> String.ljust(string, length)
        :right -> String.rjust(string, length)
      end
    end
  end

  defp concat(left, right) do
    for {left, right} <- Enum.zip(left, right) do
      [left, right]
    end |> Enum.intersperse("\r\n")
  end
end
