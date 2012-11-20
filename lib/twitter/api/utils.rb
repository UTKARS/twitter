require 'twitter/core_ext/array'
require 'twitter/core_ext/enumerable'
require 'twitter/core_ext/hash'
require 'twitter/core_ext/kernel'
require 'twitter/cursor'
require 'twitter/user'

module Twitter
  module API
    module Utils

      DEFAULT_CURSOR = -1

    private

      # @param klass [Class]
      # @param array [Array]
      # @return [Array]
      def collection_from_array(klass, array)
        array.map do |element|
          klass.fetch_or_new(element)
        end
      end

      # @param klass [Class]
      # @param request_method [Symbol]
      # @param path [String]
      # @param params [Hash]
      # @param options [Hash]
      # @return [Array]
      def collection_from_response(klass, request_method, path, params={})
        collection_from_array(klass, send(request_method.to_sym, path, params)[:body])
      end

      # @param klass [Class]
      # @param request_method [Symbol]
      # @param path [String]
      # @param params [Hash]
      # @param options [Hash]
      # @return [Object]
      def object_from_response(klass, request_method, path, params={})
        response = send(request_method.to_sym, path, params)
        klass.from_response(response)
      end

      # @param klass [Class]
      # @param request_method [Symbol]
      # @param path [String]
      # @param args [Array]
      # @return [Array]
      def objects_from_response(klass, request_method, path, args)
        options = args.extract_options!
        options.merge_user!(args.pop)
        collection_from_response(klass, request_method, path, options)
      end

      # @param request_method [Symbol]
      # @param path [String]
      # @param args [Array]
      # @return [Array<Integer>]
      def ids_from_response(request_method, path, args)
        options = args.extract_options!
        merge_default_cursor!(options)
        options.merge_user!(args.pop)
        cursor_from_response(:ids, nil, request_method, path, options, calling_method)
      end

      # @param collection_name [Symbol]
      # @param klass [Class]
      # @param request_method [Symbol]
      # @param path [String]
      # @param params [Hash]
      # @param options [Hash]
      # @return [Twitter::Cursor]
      def cursor_from_response(collection_name, klass, request_method, path, params={}, method_name=calling_method)
        response = send(request_method.to_sym, path, params)
        Twitter::Cursor.from_response(response, collection_name.to_sym, klass, self, method_name, params)
      end

      # @param request_method [Symbol]
      # @param path [String]
      # @param args [Array]
      # @return [Array<Twitter::User>]
      def users_from_response(request_method, path, args)
        options = args.extract_options!
        options.merge_user!(args.pop || screen_name)
        collection_from_response(Twitter::User, request_method, path, options)
      end

      # @param request_method [Symbol]
      # @param path [String]
      # @param args [Array]
      # @return [Array<Twitter::User>]
      def threaded_users_from_response(request_method, path, args)
        options = args.extract_options!
        args.flatten.threaded_map do |user|
          object_from_response(Twitter::User, request_method, path, options.merge_user(user))
        end
      end

      # @param klass [Class]
      # @param request_method [Symbol]
      # @param path [String]
      # @param args [Array]
      # @return [Array]
      def threaded_object_from_response(klass, request_method, path, args)
        options = args.extract_options!
        args.flatten.threaded_map do |id|
          object_from_response(klass, request_method, path, options.merge(:id => id))
        end
      end

      def handle_forbidden_error(klass, error)
        if error.message == klass::MESSAGE
          raise klass.new
        else
          raise error
        end
      end

      def merge_default_cursor!(options)
        options[:cursor] = DEFAULT_CURSOR unless options[:cursor]
      end

      def screen_name
        @screen_name ||= verify_credentials.screen_name
      end

    end
  end
end
