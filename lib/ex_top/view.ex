defmodule ExTop.View do
  @columns [{"PID", 12, :right},
            {"Registered Name", 24, :left},
            {"Memory", 9, :right},
            {"Reductions", 10, :right},
            {"Message Queue", 13, :right}]

  def render(data) do
    [separator,
     heading,
     separator,
     rows(data[:processes]),
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

  defp rows(processes) do
    for process <- processes do
      ["| ",
       for {name, size, align} <- @columns do
         text = case name do
           "PID" -> IO.iodata_to_binary(:erlang.pid_to_list(process[:pid]))
           "Registered Name" -> inspect(process[:registered_name])
           "Memory" -> inspect(process[:memory])
           "Reductions" -> inspect(process[:reductions])
           "Message Queue" -> inspect(process[:message_queue_len])
         end
         just(text, size, align)
       end |> Enum.intersperse(" | "),
       " |"]
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
