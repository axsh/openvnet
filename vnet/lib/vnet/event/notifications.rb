module Vnet::Event::Notifications
  def self.included(klass)
    klass.class_eval do
      include Celluloid
      include Celluloid::Logger
      include Celluloid::Notifications
      prepend Initializer
    end
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def events
      @events ||= {}
    end

    def subscribe_event(event_name, method = nil, options = {})
      options.fetch(:before)
      options.fetch(:during)
      options.fetch(:after)
      options[:pending] = [options[:pending] || []].flatten
      self.events[event_name] = { method: method, options: options }
    end
  end

  module Initializer
    def initialize(*args, &block)
      super
      @item_statuses = {}
      @event_queues = {}
      subscribe_events
    end
  end

  def events
    self.class.events
  end

  def handle_event(event_name, params)
    #debug "handle event: #{event_name} params: #{params.inspect} status: #{@item_statuses[params[:target_id]]}"

    event = events[event_name]

    return unless event[:method]

    item_status = @item_statuses[params[:target_id]]

    if event[:options][:pending].member?(item_status)
      event_queue = (@event_queues[params[:target_id]] || []).dup
      event_queue << { event_name: event_name, params: params.dup }
      @event_queues[params[:target_id]] = event_queue
      return
    end

    return unless item_status == event[:options][:before]

    @item_statuses[params[:target_id]] = event[:options][:during]

    __send__(event[:method], params)

    @item_statuses[params[:target_id]] = event[:options][:after]

    (@event_queues[params[:target_id]] || []).dup.tap do |event_queue|
      while e = event_queue.shift
        if events[e[:event_name]][:options][:before] == @item_statuses[params[:target_id]]
          @event_queues[params[:target_id]] = event_queue
          # the rest of queues will be processed recursively
          async(:handle_event, e[:event_name], e[:params])
          return
        end
      end
    end

    return nil
  end

  def subscribe_events
    self.events.keys.each do |event_name|
      subscribe(event_name, :handle_event)
    end
  end
end
