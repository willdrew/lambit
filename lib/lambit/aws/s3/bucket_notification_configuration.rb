# encoding: UTF-8

using Lambit::Common::HashHelper

module Lambit
  module Aws
    module S3
      class BucketNotificationConfiguration
        OPTIONS = [
              :bucket,
              :notification_configuration,
              :use_accelerate_endpoint
          ].each { |option| attr_reader option }

        attr_reader :client
        attr_reader :options

        def initialize(config)
          @client = ::Aws::S3::Client.new

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

        def notification_configuration_types
          types = [
            :topic_configurations,
            :lambda_function_configurations,
            :queue_configurations
          ]
        end

        def add
          config = self.client.get_bucket_notification_configuration(:bucket => options[:bucket])

          notification_configuration_types.each do |type|
            options_hash = options[:notification_configuration][type].to_a.map { |r| [r[:id], r] }.to_h
            config_hash  = config.send(type).to_a.map { |r| [r[:id], r.to_hash] }.to_h
            options[:notification_configuration][type] = config_hash.merge(options_hash).values
          end

          put(options)
        end

        def remove
          config = self.client.get_bucket_notification_configuration(:bucket => options[:bucket])

          notification_configuration_types.each do |type|
            options_hash = options[:notification_configuration][type].to_a.map { |r| [r[:id], r] }.to_h
            config_hash  = config.send(type).to_a.map { |r| [r[:id], r.to_hash] }.to_h
            options[:notification_configuration][type] = config_hash.difference(options_hash).values
          end

          put(options)
        end

        def put(opts)
          r = self.client.put_bucket_notification_configuration(opts)
          notification_configuration_types.each do |type|
            puts self.client.get_bucket_notification_configuration(:bucket => opts[:bucket]).send type
          end if Lambit.is_debug?

          r
        end
      end
    end
  end
end
