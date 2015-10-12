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

    %{memory: memory,
      processes: processes}
  end
end
