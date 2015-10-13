defmodule ExTop.Collector do
  def collect do
    memory = :erlang.memory

    processes = for pid <- :erlang.processes do
      info = :erlang.process_info(pid, [:current_function,
                                        :initial_call,
                                        :memory,
                                        :message_queue_len,
                                        :reductions,
                                        :registered_name])
      case info do
        :undefined -> nil
        info ->
          name_or_initial_call = case info[:registered_name] do
                                   [] -> info[:initial_call]
                                   otherwise -> otherwise
                                 end
          [{:pid, pid}, {:name_or_initial_call, name_or_initial_call} | info]
      end
    end |> Enum.reject(&is_nil/1)

    schedulers = :erlang.statistics(:scheduler_wall_time) |> Enum.sort

    {{:input, io_input}, {:output, io_output}} = :erlang.statistics(:io)
    run_queue = :erlang.statistics(:run_queue)
    process_count = :erlang.system_info(:process_count)
    process_limit = :erlang.system_info(:process_limit)
    uptime = :erlang.statistics(:wall_clock) |> elem(0) |> div(1000)

    %{memory: memory,
      processes: processes,
      schedulers: schedulers,
      statistics: %{
        io_input: io_input,
        io_output: io_output,
        process_count: process_count,
        process_limit: process_limit,
        run_queue: run_queue,
        uptime: uptime
      }}
  end
end
