# Usage: `require 'sidekiq/logging/json/error_handler'`
# Automatically removes the default Sidekiq error handler since it
# creates multi-line outputs which is annoying for Logstash
class Sidekiq::Logging::Json::ExceptionLogger
  def call(ex, ctxHash)
    logdata = {
      exception: ex.class.name,
      exception_message: ex.message
    }
    logdata.merge! ctxHash unless ctxHash.empty?
    logdata[:backtrace] = ex.backtrace.join("\n") unless ex.backtrace.nil?
    Sidekiq.logger.warn logdata
  end


  def install
  # Set up our handler instead
    Sidekiq.error_handlers << self
  end

  def self.remove_default_logger
    # Remove the default Sidekiq exception logger
    Sidekiq.error_handlers.select! { |handler| handler.class != Sidekiq::ExceptionHandler::Logger }
  end

end
