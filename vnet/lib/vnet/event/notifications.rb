module Vnet::Event::Notifications
  def self.included(klass)
    klass.class_eval do
      include Celluloid
      include Celluloid::Logger
      include Celluloid::Notifications
      include Vnet::Event
      prepend Initializer
      trap_exit :unsubscribe_events
    end
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def event_definitions
      @event_definitions ||= {}
    end

    def subscribe_event(event_name, method = nil, options = {})
      self.event_definitions[event_name] = { method: method, options: options }
    end
  end

  module Initializer
    def initialize(*args, &block)
      super
      @queue_statuses = {}
      @event_queues = {}
      subscribe_events
    end
  end

  def event_definitions
    self.class.event_definitions
  end

  def handle_event(event_name, params)
    #debug "handle event: #{event_name} params: #{params.inspect}}"
    event_queue = (@event_queues[params[:id]] || []).dup
    event_queue << { event_name: event_name, params: params.dup }
    @event_queues[params[:id]] = event_queue
    unless @queue_statuses[params[:id]]
      @queue_statuses[params[:id]] = true
      async(:fetch_queued_events, params[:id])
    end
  end

  def fetch_queued_events(id)
    while @event_queues[id].present?
      event_queue = @event_queues[id]
      event = event_queue.shift
      @event_queues[id] = event_queue

      event_definition = event_definitions[event[:event_name]]
      next unless event_definition[:method]

      #debug "execute event: #{event[:event_name]} method: #{event_definition[:method]} params: #{event[:params].inspect}"

      __send__(event_definition[:method], event[:params])
    end
    @event_queues.delete(id)
    return 
  ensure
    @queue_statuses.delete(id)
  end

  def subscribe_events
    self.event_definitions.keys.each do |event_name|
      subscribe(event_name, :handle_event)
    end
  end

  def unsubscribe_events(actor, reason)
    self.event_definitions.keys.each { |e| unsubscribe(e) } if Celluloid::Notifications.notifier
  end
end
