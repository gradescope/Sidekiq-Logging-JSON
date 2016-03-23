require "sidekiq/logging/json/version"
require "sidekiq/logging/json"
require "json"

module Sidekiq
  module Logging
    module Json
      class Logger < Sidekiq::Logging::Pretty
        # Provide a call() method that returns the formatted message.
        def call(severity, time, program_name, message)
          {
            '@timestamp' => time.utc.iso8601,
            :pid => ::Process.pid,
            :thread_id => "TID-#{Thread.current.object_id.to_s(36)}",
            :context => "#{context}",
            :program_name => program_name,
            :worker => "#{context}".split(" ")[0],
            :type => 'sidekiq',
            :job_status => nil,
            :severity => severity,
            :run_time => nil,
            :status_message => "#{message}",
          }.merge(process_message(severity, time, program_name, message)).to_json + "\n"
        end

        def process_message(severity, time, program_name, message)
          h = {}
          if message.is_a? Exception
            h[:job_status] = 'exception'
          elsif message.is_a? Hash
            if message["retry"]
              h[:job_status] = "retry"
              h[:status_message] = "#{message['class']} failed, retrying with args #{message['args']}."
            else
              h[:job_status] = "dead"
              h[:status_message] = "#{message['class']} failed with args #{message['args']}, not retrying."
            end

            h[:job_params] = message[:parameters] if message[:parameters]

            return {
              :job_status => job_status,
              :status_message => "#{msg}"
            }.merge(message[:parameters] || {})
          else
            result = message.split(" ")
            status = result[0].match(/^(start|done|fail):?$/) || []
            h[:job_status] = status[1]
            h[:run_time] = status[1] && result[1] && result[1].to_f   # run time in seconds
          end
          return h
        end
      end
    end
  end
end
