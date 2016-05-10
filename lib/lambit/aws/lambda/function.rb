# encoding: UTF-8

module Lambit
  module Aws
    module Lambda
      class Function
        OPTIONS = [
              :function_name,
              :runtime,
              :role,
              :handler,
              :code,
              :description,
              :timeout,
              :memory_size,
              :publish,
              :vpc_config
          ].each { |option| attr_reader option }

        attr_reader :client

        def initialize(config)
          @client = ::Aws::Lambda::Client.new

          OPTIONS.each do |option|
            if config.has_key?(option)
              instance_variable_set("@#{option}", config[option])
            end
          end
        end

        def options
          options = {}

          OPTIONS.each do |option|
            value = self.send(option)
            options[option] = value unless value.nil?
          end
          options
        end

        def create_function
          self.client.create_function options
        end

        def delete_function
          opts = {function_name: options[:function_name]}
          self.client.delete_function opts
        end
      end
    end
  end
end
