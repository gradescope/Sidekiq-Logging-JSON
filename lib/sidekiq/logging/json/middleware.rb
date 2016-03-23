class Sidekiq::Logging::Json::Middleware
  # Logs job parameters to Logstash
  def initialize
  end

  def call(worker, item, queue)
    logger.info parameters: item['args']
    yield
  end
end
