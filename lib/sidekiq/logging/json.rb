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
          return { :job_status => 'exception' } if message.is_a?(Exception)

          if message.is_a? Hash
            if message["retry"]
              job_status = "retry"
              msg = "#{message['class']} failed, retrying with args #{message['args']}."
            else
              job_status = "dead"
              msg = "#{message['class']} failed with args #{message['args']}, not retrying."
            end
            return {
              :job_status => job_status,
              :status_message => "#{msg}"
            }.merge(message[:parameters] || {})
          end

          result = message.split(" ")
          job_status = result[0].match(/^(start|done|fail):?$/) || []

          {
            job_status: job_status[1],                                   # start or done
            run_time: status[1] && result[1] && result[1].to_f   # run time in seconds
          }
        end
      end
    end
  end
end
