defmodule ExTop.View do
  @columns [{"PID", 12, :right},
            {"Registered Name", 24, :left},
            {"Memory", 9, :right},
            {"Reductions", 10, :right},
            {"Message Queue", 13, :right},
            {"Current Function", 24, :left}]

  def render(data, opts \\ []) do
    [separator,
     heading,
     separator,
     rows(data[:processes], opts),
     separator] |> Enum.intersperse("\n\r")
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
      String.slice(string, 0, length)
    else
      case align do
        :left -> String.ljust(string, length)
        :right -> String.rjust(string, length)
      end
    end
  end
end
