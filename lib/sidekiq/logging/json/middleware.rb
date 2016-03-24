# Middleware for improving Sidekiq logging with Logstash
class Sidekiq::Logging::Json::Middleware
  def initialize
  end

  # Logs job parameters to Logstash
  def call(worker, item, queue)
    params = worker.class.instance_method(:perform).parameters.map { |x| x[1] }
    worker.logger.info job_params: params.zip(item['args']).to_h
    yield
  end
end
