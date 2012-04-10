begin
  require 'v8' unless defined?(V8)
rescue LoadError => e
  warn "[WARNING] Please install gem 'therubyracer' to use Less."
  raise e
end

require 'pathname'

module Less
  module JavaScript
    
    class V8Context

      def self.instance
        return new
      end
      
      def initialize(globals = nil)
        lock do
          @v8_context = V8::Context.new
          globals.each { |key, val| @v8_context[key] = val } if globals
        end
      end

      def exec(&block)
        lock(&block)
      end

      def eval(source, options = nil) # passing options not supported
        source = source.encode('UTF-8') if source.respond_to?(:encode)

        lock do
          @v8_context.eval("(#{source})")
        end
      end

      def call(properties, *args)
        args.last.is_a?(::Hash) ? args.pop : nil # extract_options!

        lock do
          @v8_context.eval(properties).call(*args)
        end
      end

      private
      
        def lock(&block)
          do_lock(&block)
        rescue V8::JSError => e
          if e.value["name"] == "SyntaxError" || e.in_javascript?
            raise Less::ParseError.new(e)
          else
            raise Less::Error.new(e)
          end
        end
      
        def do_lock
          result, exception = nil, nil
          V8::C::Locker() do
            begin
              result = yield
            rescue Exception => e
              exception = e
            end
          end

          if exception
            raise exception
          else
            result
          end
        end
        
    end
  end
end