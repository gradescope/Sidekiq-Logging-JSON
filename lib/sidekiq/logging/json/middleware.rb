class Sidekiq::Logging::Json::Middleware
  # Logs job parameters to Logstash
  def initialize
  end

  def call(worker, item, queue)
    worker.logger.info parameters: item['args']
    yield
  end
end
