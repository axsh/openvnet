# -*- coding: utf-8 -*-

# All events with the same ':id => value' are executed using FIFO
# ordering on the same fiber. Events with differing ':id => value'
# will each use their own fiber.
#
# Events with no :id key set use the :default queue id.
#
# Usage:
#
# class Foo
#   subscribe_event "event_foo", :method_foo
#
#   private
#
#   def method_foo(params)
#     id = params[:id]
#     foo = params[:foo]
#   end    
# end

module Vnet::Event
  module Notifications

    def self.included(klass)
      klass.class_eval do
        # TODO: Consider removing Celluloid and Celluloid::Logger
        # includes.
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

      # TODO: Add a subscribe event that gets the item, or might even
      # retrieve the item from the database if not present.

      def subscribe_event(event_name, method = nil, options = {})
        self.event_definitions[event_name] = { method: method, options: options }
      end
    end

    module Initializer
      def initialize(*args, &block)
        @event_handler_state = :active # Test with :drop_all
        @event_queues = {}
        @queue_statuses = {}

        super

        subscribe_events
      end
    end

    #
    # Public methods:
    #

    def event_handler_active
      @event_handler_state = :active

      @event_queues.keys.each { |queue_id|
        event_handler_start_queue(queue_id)
      }
    end

    def event_handler_drop_all
      @event_handler_state = :drop_all

      # The @queue_statuses should be cleared when all fibers in
      # 'event_handler_process_queue' finish.
      @event_queues.clear
    end

    def event_handler_queue_only
      @event_handler_state = :queue_only

      # Do nothing, however we need to check state each iteration in
      # queue handler.
    end

    def event_definitions
      self.class.event_definitions
    end

    def subscribe_events
      self.event_definitions.keys.each do |event_name|
        subscribe(event_name, :handle_event)
      end
    end

    def unsubscribe_events(actor, reason)
      self.event_definitions.keys.each { |e| unsubscribe(e) }
    rescue Celluloid::DeadActorError
    end

    #
    # Event handling:
    #

    def handle_event(event_name, params)
      #debug "handle event: #{event_name} params: #{params.inspect}}"

      queue_id = params[:id] || :default

      # TODO: Clean this up...
      event_queue = @event_queues[queue_id] || []
      event_queue << { event_name: event_name, params: params.dup }

      @event_queues[queue_id] = event_queue

      event_handler_start_queue(queue_id)
    end

    #
    # Internal:
    #

    private

    def event_handler_start_queue(queue_id)
      return if @queue_statuses[queue_id]

      @queue_statuses[queue_id] = true
      async(:event_handler_process_queue, queue_id)
    end

    # When called '@queue_statuses[id]' must be set to true in order
    # to ensure only a single fiber is executing the events for a
    # particular id.
    def event_handler_process_queue(queue_id)
      # TODO: Don't retrieve the queue needlessly, however do keep in
      # mind the states.

      while @event_queues[queue_id].present?
        event_queue = @event_queues[queue_id]
        event = event_queue.shift

        event_definition = event_definitions[event[:event_name]]
        next unless event_definition[:method]

        #debug "execute event: #{event[:event_name]} method: #{event_definition[:method]} params: #{event[:params].inspect}"

        __send__(event_definition[:method], event[:params])
      end

      @event_queues.delete(queue_id)
      return

    ensure
      @queue_statuses.delete(queue_id)
    end

  end
end
