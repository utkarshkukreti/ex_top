defmodule ExTop.Collector do
  def collect do
    processes = for pid <- :erlang.processes do
      info = :erlang.process_info(pid, [:memory,
                                        :message_queue_len,
                                        :reductions,
                                        :registered_name])
      [{:pid, pid} | info]
    end

    %{processes: processes}
  end
end
