# encoding: UTF-8

module Lambit
  module Aws
    module CloudWatch
      class Alarm
        OPTIONS = [
              :alarm_name,
              :alarm_description,
              :actions_enabled,
              :ok_actions,
              :alarm_actions,
              :insufficient_data_actions,
              :metric_name,
              :namespace,
              :statistic,
              :dimensions,
              :period,
              :unit,
              :evaluation_periods,
              :threshold,
              :comparison_operator,
              :alarm_names
          ].each { |option| attr_reader option }

        attr_reader :client
        attr_reader :options

        def initialize(config)
          @client = ::Aws::CloudWatch::Client.new

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

        def put_metric_alarm
          self.client.put_metric_alarm options
        end

        def delete_alarms
          self.client.delete_alarms options
        end
      end
    end
  end
end
