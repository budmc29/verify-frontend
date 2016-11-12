require 'statsd-ruby'
require 'metrics'

if CONFIG.metrics_enabled
  event_source = ActiveSupport::Notifications
  statsd_client = Statsd.new(CONFIG.statsd_host, CONFIG.statsd_port).tap { |sd| sd.namespace = CONFIG.statsd_prefix }
  event_subscriber = Metrics::EventSubscriber.new(event_source)

  controller_action_reporter = Metrics::ControllerActionReporter.new(statsd_client)
  event_subscriber.subscribe(/process_action.action_controller/, controller_action_reporter)

  response_status_reporter = Metrics::ResponseStatusReporter.new(statsd_client)
  event_subscriber.subscribe(/process_action.action_controller/, response_status_reporter)

  api_request_reporter = Metrics::ApiRequestReporter.new(statsd_client)
  event_subscriber.subscribe(/api_request/, api_request_reporter)
end
