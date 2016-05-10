# encoding: UTF-8

module Lambit
  module Aws
    module Lambda
      class Permission
        OPTIONS = [
              :function_name,
              :statement_id,
              :action,
              :principal,
              :source_arn,
              :source_account,
              :event_source_token,
              :qualifier
          ].each { |option| attr_reader option }

        attr_reader :client
        attr_reader :options

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

        def add
          self.client.add_permission options
        end

        def remove
          opts = {function_name: options[:function_name], statement_id: options[:statement_id]}
          self.client.remove_permission opts
        end
      end
    end
  end
end
