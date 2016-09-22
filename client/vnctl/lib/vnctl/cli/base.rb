# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Base < Thor

    # Monkey patch to get better help output. subcommand needs to be true by
    # default or things like 'vnctl interface help add' won't output correctly.
    def self.banner(command, namespace = nil, subcommand = true)
      "#{basename} #{command.formatted_usage(self, $thor_runner, subcommand)}"
    end

    no_tasks {

      ######################
      # API helper methods #
      ######################

      # Every subclass represents one of OpenVNet's api suffixes. Use this
      # method to get/set them.
      def self.api_suffix(suffix = nil)
        @api_suffix = suffix unless suffix.nil?
        @api_suffix
      end

      def suffix
        self.class.api_suffix
      end

      ####################################################
      # Metaprogramming to define standard CRUD commands #
      ####################################################

      # The standard crud commands are:
      # * add
      # * modify
      # * del
      # * show

      # 'Add' often use mostly the same options. Use this method to
      # define them
      def self.add_shared_options(&blk)
        if block_given?
          @add_shared_options = blk
        else
          @add_shared_options && @add_shared_options.call
        end
      end

      # 'Modify' often use mostly the same options. Use this method to
      # define them
      def self.modify_shared_options(&blk)
        if block_given?
          @modify_shared_options = blk
        else
          @modify_shared_options && @modify_shared_options.call
        end
      end

      # 'Add' and 'modify' often use mostly the same options. Use this method to
      # define them
      def self.add_modify_shared_options(&blk)
        if block_given?
          @shared_options = blk
        else
          @shared_options && @shared_options.call
        end
      end

      # 'Add' often has required options while 'modify' tends to be all optional
      # Use this method to set which options defined in the add_modify_shared_options
      # method are required for 'add'.
      def self.set_required_options(opts = nil)
        @required_options_for_add = opts unless opts.nil?
        @required_options_for_add || []
      end

      # 'uuid', 'display_name' and 'description' options are used very often.
      # These methods are here so you don't have to type the same thing again
      # for every subclass.
      def self.option_uuid
        option :uuid, :type => :string, :desc => "Unique UUID for the #{namespace}."
      end

      def self.option_display_name
        option :display_name, :type => :string, :desc => "Human readable display name."
      end

      def self.option_description
        option :description, :type => :string, :desc => "Optional verbose description."
      end

      def self.option_offset
        option :offset, type: :numeric, desc: "Providing X offset will not return the first X records from the WebAPI"
      end

      def self.option_limit
        option :limit, type: :numeric, desc: "Limits the amount of records the WebAPI returns."
      end

      # And here we have the methods that create the actual CRUD tasks
      def self.define_add
        desc "add [OPTIONS]", "Creates a new #{namespace}."
        set_required_options.each { |o|
          options[o].instance_variable_set(:@required, true)
        }
        define_method(:add) do
          puts Vnctl.webapi.post(suffix, options)
        end
      end

      def self.define_show
        desc "show [UUID(S)]", "Shows all or a specific set of #{namespace}(s)."
        option_limit
        option_offset
        define_method(:show) do |*uuids|
          if uuids.empty?
            puts Vnctl.webapi.get(suffix, options)
          else
            uuids.each { |uuid| puts Vnctl.webapi.get("#{suffix}/#{uuid}") }
          end
        end
      end

      def self.define_del
        desc "del UUID(S)", "Deletes one or more #{namespace}(s) separated by a space."
        define_method(:del) do |*uuids|
          puts uuids.map { |uuid|
            Vnctl.webapi.delete("#{suffix}/#{uuid}")
          }.join("\n")
        end
      end

      def self.define_modify
        desc "modify UUID [OPTIONS]", "Modify a #{namespace}."
        define_method(:modify) do |uuid|
          puts Vnctl.webapi.put("#{suffix}/#{uuid}", options)
        end
      end

      def self.define_rename
        desc "rename UUID", "Rename a #{namespace}."
        option_uuid
        option :new_uuid, :type => :string, :required => true,
          :desc => "New unique UUID for the #{namespace}."
        define_method(:rename) do |uuid|
          puts Vnctl.webapi.put("#{suffix}/#{uuid}/rename", options)
        end
      end

      def self.define_custom_method(method_name, require_relation_uuid_label = false, &block)
        return define_method(method_name) do |uuid, relation_uuid|
          yield uuid, relation_uuid, options
        end if require_relation_uuid_label

        define_method(method_name) do |uuid|
          yield uuid, options
        end
      end

      # And one little convenient method to define all CRUD commands
      def self.define_standard_crud_commands
        option_uuid
        add_shared_options
        add_modify_shared_options
        define_add

        modify_shared_options
        add_modify_shared_options
        define_modify

        define_show
        define_del
      end

      #######################################
      # Metaprogramming to define relations #
      #######################################

      # These define commands for relations. Every relation uses three commands:
      # * add
      # * show
      # * del

      # For example, you might have datapath related to networks.
      # That translates to the following commands:
      # ./vnctl datapath networks add
      # ./vnctl datapath networks show
      # ./vnctl datapath networks del

      # This magical method creates a new Cli::Base subclass that will define
      # the relation commands for you.
      def self.define_relation(relation_name, add_options = {}, &block)
        parent = self

        c = Class.new(Base) do
          no_tasks {
            def self.get_option(options, key, default = nil)
              if options.has_key?(key)
                options[key]
              else
                default
              end
            end

            def self.rel_name(name = nil)
              @rel_name = name unless name.nil?
              @rel_name
            end

            def rel_name
              self.class.rel_name
            end
          }

          rel_name relation_name

          relation_singular = relation_name.to_s.chomp("s")
          base_uuid_label = "#{parent.namespace.upcase}_UUID"
          relation_uuid_label = "#{relation_singular.upcase}_UUID"
          desc_label = relation_name.to_s.gsub('_', ' ')

          only_include_show = get_option(add_options, :only_include_show, false)
          require_relation_uuid_label = get_option(add_options, :require_relation_uuid_label, true)

          yield self if block_given?

          if !only_include_show
            if require_relation_uuid_label
              desc "add #{base_uuid_label} #{relation_uuid_label} OPTIONS",
              "Adds #{desc_label} to a(n) #{parent.namespace}."
              def add(base_uuid, rel_uuid)
                full_uri_suffix = "#{suffix}/#{base_uuid}/#{rel_name}/#{rel_uuid}"
                puts Vnctl.webapi.post(full_uri_suffix, options)
              end
            else
              desc "add #{base_uuid_label} OPTIONS",
              "Adds #{desc_label} to a(n) #{parent.namespace}."
              def add(base_uuid)
                puts Vnctl.webapi.post("#{suffix}/#{base_uuid}/#{rel_name}", options)
              end
            end

            desc "del #{base_uuid_label} #{relation_uuid_label}(S)",
            "Removes #{desc_label} from a(n) #{parent.namespace}."
            def del(base_uuid, *rel_uuids)
              puts rel_uuids.map { |rel_uuid|
                Vnctl.webapi.delete("#{suffix}/#{base_uuid}/#{rel_name}/#{rel_uuid}")
              }.join("\n")
            end
          end

          desc "show #{base_uuid_label}",
            "Shows all #{desc_label} in this #{parent.namespace}."
          option_limit
          option_offset
          def show(base_uuid)
            puts Vnctl.webapi.get("#{suffix}/#{base_uuid}/#{rel_name}", options)
          end

        end

        c.namespace "#{self.namespace} #{relation_name}"
        c.api_suffix self.api_suffix

        register(c, "#{relation_name}", "#{relation_name} OPTIONS",
          "subcommand to manage #{relation_name} in this #{self.namespace}.")

        c
      end

      # Method for mode type relationships

      def self.define_mode_relation(mode_type, required_opts = [], &block)
        parent = self
        c = Class.new(Base) do

          base_uuid = "#{parent.namespace.chomp('s')}"

          yield self if block_given?
          desc "add #{base_uuid.upcase}_UUID OPTIONS", "Adds a(n) #{mode_type} #{base_uuid}."
          define_method("add") { | uuid |
            puts Vnctl.webapi.post("#{suffix}/#{uuid}/#{mode_type}", options)
          }

          yield self if block_given?
          desc "del #{base_uuid.upcase}_UUID OPTIONS", "Removes a(n) #{mode_type} #{base_uuid}."
          define_method("del") { | uuid |
            puts Vnctl.webapi.delete("#{suffix}/#{uuid}/#{mode_type}", options)
          }

          desc "show #{mode_type} #{base_uuid.upcase}_UUID",  "Shows all #{mode_type}s."
          define_method("show") { | uuid = nil |
            puts Vnctl.webapi.get("#{suffix}/#{mode_type}/#{uuid}")
          }
        end

        c.namespace "#{self.namespace} #{mode_type}"
        c.api_suffix self.api_suffix

        register(c, "#{mode_type}", "#{mode_type} OPTIONS",
                 "subcommand to manage #{mode_type} in this #{self.namespace}.")
        c
      end
    }
  end
end

