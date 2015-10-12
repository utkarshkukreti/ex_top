defmodule ExTop.View do
  def render(data, opts \\ []) do
    [concat3(schedulers(data[:prev_schedulers], data[:schedulers]),
             memory(data[:memory]),
             statistics(data[:system])),
     processes_separator,
     processes_heading,
     processes_separator,
     processes_rows(data[:processes], opts),
     processes_separator] |> Enum.intersperse("\n\r")
  end

  defp statistics(system) do
    ["+-----------------+----------------+",
     "|             Statistics           |",
     "+-----------------+----------------+",
     "| Uptime          | #{just(inspect(system[:uptime]), 13, :right)}s |",
     "| Process Count   | #{just(inspect(system[:process_count]), 14, :right)} |",
     "| Process Limit   | #{just(inspect(system[:process_limit]), 14, :right)} |",
     "| Run Queue       | #{just(inspect(system[:run_queue]), 14, :right)} |",
     "| IO Input        | #{just(inspect(system[:io_input]), 14, :right)} |",
     "| IO Output       | #{just(inspect(system[:io_output]), 14, :right)} |"]
  end

  defp memory(memory) do
    ["+------------+---------------",
     "|            Memory          ",
     "+------------+---------------",
     "| Total      | #{just(inspect(memory[:total]), 13, :right)} ",
     "| Processes  | #{just(inspect(memory[:processes]), 13, :right)} ",
     "| Atom       | #{just(inspect(memory[:atom]), 13, :right)} ",
     "| Binary     | #{just(inspect(memory[:binary]), 13, :right)} ",
     "| Code       | #{just(inspect(memory[:code]), 13, :right)} ",
     "| ETS        | #{just(inspect(memory[:ets]), 13, :right)} "]
  end

  defp schedulers(prev, now) do
    width = 41
    usages = if prev do
      for {{n, a1, t1}, {n, a2, t2}} <- Enum.zip(prev, now) |> Enum.take(8) do
        {n, (a2 - a1) / (t2 - t1)}
      end
    else
      []
    end

    ["+------------------------------------------------------"]
    ++
    for {n, usage} <- usages do
      ["| ",
       inspect(n),
       " [",
       IO.ANSI.green,
       just(String.duplicate("|", trunc(usage * width)), width, :left),
       IO.ANSI.reset,
       just(Float.to_string(usage * 100, decimals: 2) <> "%", 6, :right),
       " ] "]
    end
    ++
    for _ <- 0..(8 - Enum.count(usages)) do
      ["| ", String.duplicate(" ", width + 12)]
    end
  end

  @processes_columns [{"PID", 13, :right},
                      {"Registered Name", 24, :left},
                      {"Memory", 9, :right},
                      {"Reductions", 10, :right},
                      {"Message Queue", 13, :right},
                      {"Current Function", 32, :left}]

  defp processes_separator do
    [?+,
    for {_, size, _} <- @processes_columns do
      String.duplicate("-", size + 2)
    end |> Enum.intersperse(?+),
    ?+]
  end

  defp processes_heading do
    ["| ",
    for {name, size, align} <- @processes_columns do
      just(name, size, align)
    end |> Enum.intersperse(" | "),
    " |"]
  end

  defp processes_rows(processes, opts) do
    for {process, index} <- Enum.with_index(processes) do
      row = ["| ",
       for {name, size, align} <- @processes_columns do
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

  defp concat3(a, b, c) do
    for {{a, b}, c} <- Enum.zip(Enum.zip(a, b), c) do
      [a, b, c]
    end |> Enum.intersperse("\r\n")
  end
end
