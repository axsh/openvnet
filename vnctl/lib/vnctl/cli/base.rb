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

      # Some syntax sugar for the actual api calls
      [:post, :get, :delete, :put].each { |req_type|
        define_method(req_type) { |*args|
          uri = args.shift
          format = Vnctl.conf.output_format

          Vnctl::WebApi.send(req_type, "#{uri}.#{format}", *args)
        }
      }

      ####################################################
      # Metaprogramming to define standard CRUD commands #
      ####################################################

      # The standard crud commands are:
      # * add
      # * modify
      # * del
      # * show

      # 'Add' and 'modify' often use mostly the same options. Use this method to
      # define them
      def self.add_modify_shared_options(&blk)
        if block_given?
          @shared_options = blk
        else
          @shared_options.call
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

      # And here we have the methods that create the actual CRUD tasks
      def self.define_add
        desc "add [OPTIONS]", "Creates a new #{namespace}."
        set_required_options.each { |o|
          options[o].instance_variable_set(:@required, true)
        }
        define_method(:add) do
          puts post(suffix, :query => options)
        end
      end

      def self.define_show
        desc "show [UUID(S)]", "Shows all or a specific set of #{namespace}(s)."
        define_method(:show) do |*uuids|
          if uuids.empty?
            puts get(suffix)
          else
            uuids.each { |uuid| puts get("#{suffix}/#{uuid}") }
          end
        end
      end

      def self.define_del
        desc "del UUID(S)", "Deletes one or more #{namespace}(s) separated by a space."
        define_method(:del) do |*uuids|
          puts uuids.map { |uuid|
            delete("#{suffix}/#{uuid}")
          }.join("\n")
        end
      end

      def self.define_modify
        desc "modify UUID [OPTIONS]", "Modify a #{namespace}."
        define_method(:modify) do |uuid|
          puts put("#{suffix}/#{uuid}", :query => options)
        end
      end

      # And one little convenient method to define all CRUD commands
      def self.define_standard_crud_commands
        option_uuid
        add_modify_shared_options
        define_add

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

      # Some times there are extra options involved for a relation. For example
      # every network related to a datapath will have its own broadcast mac
      # address. If a relation has such options, use this method to define them.
      def self.rel_option(name, desc)
        @relation_options ||= []
        @relation_options << {:name => name, :desc => desc}
      end

      # This magical method creates a new Cli::Base subclass that will define
      # the relation commands for you.
      def self.define_relation(relation_name, add_options = [])
        parent = self
        rel_opts = @relation_options

        c = Class.new(Base) do
          no_tasks {
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

          desc "add #{base_uuid_label} #{relation_uuid_label} OPTIONS",
            "Adds #{desc_label} to a(n) #{parent.namespace}."
          rel_opts && rel_opts.each { |o| option(o[:name], o[:desc]) }
          def add(base_uuid, rel_uuid)
            puts post("#{suffix}/#{base_uuid}/#{rel_name}/#{rel_uuid}", :query => options)
          end

          desc "show #{base_uuid_label}",
            "Shows all #{desc_label} in this #{parent.namespace}."
          def show(base_uuid)
            puts get("#{suffix}/#{base_uuid}/#{rel_name}")
          end

          desc "del #{base_uuid_label} #{relation_uuid_label}(S)",
            "Removes #{desc_label} from a(n) #{parent.namespace}."
          def del(base_uuid, *rel_uuids)
            puts rel_uuids.map { |rel_uuid|
              delete("#{suffix}/#{base_uuid}/#{rel_name}/#{rel_uuid}")
            }.join("\n")
          end
        end

        c.namespace "#{self.namespace} #{relation_name}"
        c.api_suffix self.api_suffix

        register(c, "#{relation_name}", "#{relation_name} OPTIONS",
          "subcommand to manage #{relation_name} in this #{self.namespace}.")

        @relation_options = []
      end
    }
  end
end
