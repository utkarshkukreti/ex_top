defmodule ExTop.Collector do
  def collect do
    memory = :erlang.memory
    processes = for pid <- :erlang.processes do
      info = :erlang.process_info(pid, [:current_function,
                                        :memory,
                                        :message_queue_len,
                                        :reductions,
                                        :registered_name])
      [{:pid, pid} | info]
    end
    {{:input, io_input}, {:output, io_output}} = :erlang.statistics(:io)
    run_queue = :erlang.statistics(:run_queue)
    process_count = :erlang.system_info(:process_count)
    process_limit = :erlang.system_info(:process_limit)
    uptime = :erlang.statistics(:wall_clock) |> elem(0) |> div(1000)
    schedulers = :erlang.statistics(:scheduler_wall_time) |> Enum.sort

    %{memory: memory,
      processes: processes,
      system: %{
        io_input: io_input,
        io_output: io_output,
        process_count: process_count,
        process_limit: process_limit,
        run_queue: run_queue,
        uptime: uptime
      },
      schedulers: schedulers}
  end
end
