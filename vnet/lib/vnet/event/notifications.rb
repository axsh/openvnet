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
      # TODO: Add a subscribe event that gets the item, or might even
      # retrieve the item from the database if not present.

      def subscribe_event(event_name, method = nil, options = {})
        self.event_definitions[event_name] = { method: method, options: options }
      end

      def event_handler_default_state
        @event_handler_default_state ||= :active
      end

      def event_handler_default_active
        @event_handler_default_state = :active
      end

      def event_handler_default_drop_all
        @event_handler_default_state = :drop_all
      end

      def event_handler_default_queue_only
        @event_handler_default_state = :queue_only
      end

      def event_definitions
        @event_definitions ||= {}
      end

      def event_method_for_event_name(event_name)
        event_definition = self.event_definitions[event_name]

        if event_definition.nil?
          warn "#{self.name} could not find event definition (event_name:#{event_name})"
        end

        event_method = event_definition[:method]

        if event_method.nil?
          warn "#{self.name} could not find event method (event_name:#{event_name} event_definition:#{event_definition})"
        end

        event_method
      end
    end

    module Initializer
      def initialize(*args, &block)
        @event_handler_state = self.class.event_handler_default_state
        @event_queues = {}
        @queue_statuses = {}

        super

        # debug "#{self.class.name} initialized with event handler state #{@event_handler_state}"

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

    def subscribe_events
      self.class.event_definitions.keys.each do |event_name|
        subscribe(event_name, :handle_event)
      end
    end

    def unsubscribe_events(actor, reason)
      self.class.event_definitions.keys.each { |e| unsubscribe(e) }
    rescue Celluloid::DeadActorError
    end

    #
    # Event handling:
    #

    # TODO: Rename this to something more meaningful such as queue event.
    def handle_event(event_name, params)
      return if @event_handler_state == :drop_all

      #debug "handle event: #{event_name} params: #{params.inspect}}"

      queue_id = params[:id]

      if queue_id.nil?
        warn "#{self.class.name} cannot handle an event with no or nil id (event_name:#{event_name} params:#{params.inspect})"
        return
      end

      event_queue = @event_queues[queue_id]

      if event_queue.nil?
        event_queue = @event_queues[queue_id] = []
      end

      event_queue << { event_name: event_name, params: params.dup }
      event_handler_start_queue(queue_id)
    end

    #
    # Internal:
    #

    private

    def event_handler_start_queue(queue_id)
      return if @event_handler_state != :active
      return if @queue_statuses[queue_id]

      @queue_statuses[queue_id] = true
      async(:event_handler_process_queue, queue_id)
    end

    def event_handler_pop_event(queue_id)
      event_queue = @event_queues[queue_id] || return
      event = event_queue.shift

      # Delete empty queues here to ensure continuous event handling
      # does not lead to the array's memory footprint growing ever
      # larger.
      @event_queues.delete(queue_id) if event.nil?

      event
    end

    # When called '@queue_statuses[id]' must be set to true in order
    # to ensure only a single fiber is executing the events for a
    # particular id.
    def event_handler_process_queue(queue_id)
      # We need to check the state to ensure that no new events are
      # executed, however we cannot guarantee that no events are still
      # executing after the state changes.
      while @event_handler_state == :active
        event = event_handler_pop_event(queue_id)
        break if event.nil?

        # Set by this module, no need to verify.
        event_name = event[:event_name]
        event_params = event[:params]

        event_method = self.class.event_method_for_event_name(event_name)
        next if event_method.nil?

        __send__(event_method, event_params)

        #debug "executed event: #{event_name} method: #{event_method} params: #{event_params.inspect}"
      end

    ensure
      @queue_statuses.delete(queue_id)
    end

  end
end
