# encoding: UTF-8

module Lambit
  module Aws
    module CloudWatchEvents
      class Rule
        OPTIONS = [
              :name,
              :rule,
              :schedule_expression,
              :event_pattern,
              :state,
              :description,
              :role_arn,
              :targets
          ].each { |option| attr_reader option }

        attr_reader :client
        attr_reader :options

        def initialize(config)
          @client = ::Aws::CloudWatchEvents::Client.new

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

        def put_rule
          self.client.put_rule options
        end

        def delete_rule
          opts = {name: options[:name]}
          self.client.delete_rule opts
        end

        def put_targets
          opts = {rule: options[:rule], targets: options[:targets]}
          self.client.put_targets opts
        end

        def remove_targets
          opts = {rule: options[:rule], ids: options[:targets].map{|i| i.map{|k,v| v if k == :id}.compact}.flatten}
          self.client.remove_targets opts
        end
      end
    end
  end
end
