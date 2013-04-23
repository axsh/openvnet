# -*- coding: utf-8 -*-

require 'json'

require 'sinatra/respond_with'
require 'sinatra/namespace'
require 'sinatra/json'

# common setup for Vnmgr API Sinatra App. Based on the same file form Wakame-vdc
module Sinatra

  module Namespace
    module InstanceMethods
      def error_block!(key, *block_params)
        if block = @namespace.errors[key]
          instance_exec(*block_params, &block)
        else
          # The issue is that the error blocks defined in the base
          # Sinatra are ignored with Sinatra::Namespace.
          # settings() returns the Module class represents the current
          # namespace. the blocks from errors() also need to be
          # checked in settings.base which has the reference to the
          # base Sinatra object of the namespace.
          base = settings.base
          while base.respond_to?(:errors)
            next base = base.superclass unless args = base.errors[key]
            args += [block_params]
            return process_route(*args)
          end
          return false unless key.respond_to? :superclass and key.superclass < Exception
          error_block!(key.superclass, *block_params)
        end
      end
    end
  end

  module VnmgrAPISetup
    # Returns deserialized hash from HTTP body. Serialization fromat
    # is guessed from content type header. The query string params
    # is returned if none of content type header is in HTTP headers.
    # This method is called only when the request method is POST.

    DEFAULT_OUTPUT_CONTENT_TYPE='application/json'

    BODY_PARSER = {
      'application/json' => proc { |body| ::JSON.load(body) },
      'text/json' => proc { |body| ::JSON.load(body) },
      'application/yaml' => proc { |body| ::YAML.load(body) },
      'text/yaml' => proc { |body| ::YAML.load(body) },
    }


    DO= proc {
      disable :sessions
      disable :show_exceptions

      register Sinatra::RespondWith
      register Sinatra::Namespace

      # avoid using Sinatra::JSON builtin encoder.
      set :json_encoder, ::JSON

      # remove trailing extension from URI and add mapped mime types to
      # http accept header. This helps to use file extension in URI with Sinatra::Namespace.
      before do
        rpi = request.path_info.sub(%r{\.([^\./]+)$}, '')
        ext = $1
        if ext
          (settings.mime_types(ext) || []).each.each { |i|
            request.accept.unshift(i)
          }
          request.path_info = rpi
        else
          request.accept.unshift(DEFAULT_OUTPUT_CONTENT_TYPE)
        end
      end

      # merge request body data into @params.
      before do
        next if !(request.content_length.to_i > 0)
        parser = BODY_PARSER[(request.content_type || request.preferred_type)]
        hash = if parser.nil?
                 # ActiveResource gives the one level nested hash which has
                 # {'something key'=>real_params} so that dummy key is assinged here.
                 {:dummy=>@params}
               else
                 begin
                   parser.call(request.body)
                 rescue => e
                   error(400, 'Invalid request body.')
                 end
               end

        @params.merge!(hash.values.first)
      end

    }

    def self.registered(app)
      app.class_eval &DO

      app.configure :development do
        require 'sinatra/reloader'
        app.register Sinatra::Reloader
      end
    end
  end
end
