# encoding: UTF-8

using Lambit::Common::StringHelper
using Lambit::Common::HashHelper

module Lambit::Commands
  module Lambdas
    def self.run(cmd, opts, args)
      handler            = handler_for cmd
      output, exitstatus = handler.run opts, args

      # Send Subcommand output to STDOUT if :debug
      if Lambit.is_debug?
        puts output unless output.nil? || output.empty?
      end

      # Return exit status
      exitstatus
    end

    def self.normalize_cmd(cmd)
      cmd.to_s.downcase
    end

    def self.handler_for(cmd)
      if @handlers
        @handlers[normalize_cmd(cmd)]
      else
        raise 'Uh Oh!'
      end
    end

    def self.register_handler_for(cmd, handler=nil)
      normalized_cmd = normalize_cmd(cmd)
      handler        = self.const_get(normalized_cmd.classify) if handler.nil?

      @handlers ||= {}
      @handlers[normalized_cmd] = handler
    end

    class Base < Lambit::Commands::Common::Base
      attr_reader :tmpdir, :project_path, :config
      attr_accessor :workspace

      def initialize(opts, args)
        super
        @tmpdir = opts['tmpdir']
        @workspace = opts['workspace']
        @project_path = opts['project-path']
        @config = Lambit.config
      end
    end

    class Lambdas < Base
      attr_reader :lambdas, :regexp
      attr_accessor :lambda_config, :function_name, :index, :common_opts

      def initialize(opts, args)
        super
        @regexp     = opts['regexp']
        @lambdas    = self.config['lambdas']
      end

      def parse_hash(hash)
        hash.update(hash) do |k, v|
          if v.respond_to?(:has_key?)
            parse_hash(v)
          elsif v.respond_to?(:each)
            v.flatten.each { |x| parse_hash(x) if x.respond_to?(:has_key?) }
          else
            if v.respond_to?(:to_str)
              eval('"' + v + '"')
            else
              v
            end
          end
        end
      end

      def filter
        if regexp.nil? || regexp.empty?
          yield
        elsif function_name.match Regexp.new(regexp)
          yield
        end
      end

      def process
        Lambit.logger.info "Processing Lambda: #{function_name}"
        Lambit.logger.info "Using Workspace: #{workspace}"
      end

      def command
        self.lambdas.each do |object|
          @lambda_config  = Marshal.load(Marshal.dump(object))
          @function_name  = @lambda_config['lambda_function']['function_name']
          @workspace      = File.join(tmpdir, Lambit.config['name'], function_name)
          @common_opts    = {'workspace' => workspace}
          filter { process }
        end

        return '', self.exitstatus
      end

      protected

      def graceful_continue
        begin
          yield
        rescue Exception => e
          if Lambit.is_debug?
            Lambit.logger.error e
          else
            Lambit.logger.error e.message
          end
        end
      end

      def verbose_msg_for(title, opts, args=nil)
        Lambit.logger.info "#{title} with: #{opts}, #{args}" if Lambit.is_verbose?
      end
    end

    class BuildLambdas < Lambdas
      def create_workspace
        # TODO: Create Workspaces (src and pkg)
        opts  = common_opts
        args  = []
        title = "Create Workspace"

        verbose_msg_for(title, opts, args)
        Lambit::Commands::Common.run :create_workspace_command, common_opts, args unless Lambit.is_dry_run?
      end

      def package_templates
        lambda_config['templates'].each do |tmpl_name, tmpl_config|
          opts  = common_opts.merge('project_path' => self.project_path)
          args  = [tmpl_name, tmpl_config]
          title = "Create Templates"

          verbose_msg_for(title, opts, args)
          Lambit::Commands::Build.run :package_templates_command, opts, args unless Lambit.is_dry_run?
        end if lambda_config['templates']
      end

      def package_pips
        lambda_config['required_pips'].each do |required_pip|
          opts  = common_opts
          args  = [required_pip]
          title = "Install pip"

          verbose_msg_for(title, opts, args)
          Lambit::Commands::Build.run :package_pip_command, opts, args unless Lambit.is_dry_run?
        end if lambda_config['required_pips']
      end

      def package_source
        opts  = common_opts.merge('project_path' => self.project_path)
        args  = []
        title = "Package Source"

        verbose_msg_for(title, opts, args)
        Lambit::Commands::Build.run :package_source_command, opts, args unless Lambit.is_dry_run?
      end

      def compress_package
        opts  = common_opts
        args  = []
        title = "Compress Package"

        verbose_msg_for(title, opts, args)
        Lambit::Commands::Build.run :compress_package_command, common_opts, args unless Lambit.is_dry_run?
      end

      def process
        super
        # Create Workspace
        graceful_continue { create_workspace }

        # Package Templates
        graceful_continue { package_templates }

        # Package Pip(s)
        graceful_continue { package_pips }

        # Package Source
        graceful_continue { package_source }

        # Compress Package
        graceful_continue { compress_package }
      end
    end

    register_handler_for :build_lambdas

    class CreateLambdas < Lambdas
      def create_lambda
        opt_hash  = lambda_config['lambda_function'].merge 'code': {'zip_file': IO.read("#{workspace}/package.zip")}
        opt_hashv = lambda_config['lambda_function'].merge('code': {'zip_file': 'IO.read("#{workspace}/package.zip"'})
        opts      = opt_hash.symbolize_keys
        optsv     = opt_hashv.symbolize_keys
        title     = "Deploy"

        verbose_msg_for(title, optsv)
        Lambit::Aws::Lambda::Function.new(opts).create_function unless Lambit.is_dry_run?
      end

      def process
        super
        graceful_continue { create_lambda }
      end
    end

    register_handler_for :create_lambdas

    class DeleteLambdas < Lambdas
      def delete_lambda
        opt_hash = lambda_config['lambda_function'].symbolize_keys
        opts     = opt_hash.symbolize_keys
        title    = "Delete"

        verbose_msg_for(title, opts)
        Lambit::Aws::Lambda::Function.new(opts).delete_function unless Lambit.is_dry_run?
      end

      def process
        super
        graceful_continue { delete_lambda }
      end
    end

    register_handler_for :delete_lambdas

    class AddEventSourcesLambdas < Lambdas
      def add_lambda_permissions
        lambda_config['lambda_permissions'].each_with_index do |permission, index|
          @index = index
          opt_hash = parse_hash(permission)
          opts     = opt_hash.symbolize_keys
          title    = "Add Lambda Permission"

          verbose_msg_for(title, opts)
          Lambit::Aws::Lambda::Permission.new(opts).add unless Lambit.is_dry_run?
        end if lambda_config['lambda_permissions']
      end

      def add_s3_bucket_notification_configurations
        lambda_config['s3_bucket_notification_configurations'].each_with_index do |configuration, index|
          @index = index
          opt_hash = parse_hash(configuration)
          opts     = opt_hash.symbolize_keys_deep
          title    = "Add S3 Bucket Configurations"

          verbose_msg_for(title, opts)
          Lambit::Aws::S3::BucketNotificationConfiguration.new(opts).add unless Lambit.is_dry_run?
        end if lambda_config['s3_bucket_notification_configurations']
      end

      def put_cloudwatch_event_rules
        lambda_config['cloudwatch_event_rules'].each do |rule|
          opt_hash = parse_hash(rule)
          opts     = rule.merge(opt_hash).symbolize_keys
          title    = "Add CloudWatch Event Rule"

          verbose_msg_for(title, opts)
          Lambit::Aws::CloudWatchEvents::Rule.new(opts).put_rule unless Lambit.is_dry_run?
        end if lambda_config['cloudwatch_event_rules']
      end

      def add_cloudwatch_event_targets
        lambda_config['cloudwatch_event_targets'].each_with_index do |targets, index|
          @index = index
          opt_hash = parse_hash(targets)
          opts     = opt_hash.symbolize_keys_deep
          title    = "Add CloudWatch Event Targets"

          verbose_msg_for(title, opts)
          Lambit::Aws::CloudWatchEvents::Rule.new(opts).put_targets unless Lambit.is_dry_run?
        end if lambda_config['cloudwatch_event_targets']
      end

      def process
        super
        # Add Lambda Permissions
        graceful_continue { add_lambda_permissions }

        # Add S3 Bucket Notification Configurations
        graceful_continue { add_s3_bucket_notification_configurations }

        # Put CloudWatch Event Rules
        graceful_continue { put_cloudwatch_event_rules }

        # Add CloudWatch Event Targets
        graceful_continue { add_cloudwatch_event_targets }
      end
    end

    register_handler_for :add_event_sources_lambdas

    class RemoveEventSourcesLambdas < Lambdas
      def remove_lambda_permissions
        lambda_config['lambda_permissions'].each_with_index do |permission, index|
          @index = index
          opt_hash = parse_hash(permission)
          opts     = opt_hash.symbolize_keys
          title    = "Remove Lambda Permissions"

          verbose_msg_for(title, opts)
          Lambit::Aws::Lambda::Permission.new(opts).remove unless Lambit.is_dry_run?
        end if lambda_config['lambda_permissions']
      end

      def remove_s3_bucket_notification_configurations
        lambda_config['s3_bucket_notification_configurations'].each_with_index do |configuration, index|
          @index = index
          opt_hash = parse_hash(configuration)
          opts     = opt_hash.symbolize_keys_deep
          title    = "Remove S3 Bucket Configurations"

          verbose_msg_for(title, opts)
          Lambit::Aws::S3::BucketNotificationConfiguration.new(opts).remove unless Lambit.is_dry_run?
        end if lambda_config['s3_bucket_notification_configurations']
      end

      def remove_cloudwatch_event_targets
        lambda_config['cloudwatch_event_targets'].each_with_index do |targets, index|
          @index = index
          opt_hash = parse_hash(targets)
          opts     = opt_hash.symbolize_keys_deep
          title    = "Remove CloudWatch Event Targets"

          verbose_msg_for(title, opts)
          Lambit::Aws::CloudWatchEvents::Rule.new(opts).remove_targets unless Lambit.is_dry_run?
        end if lambda_config['cloudwatch_event_targets']
      end

      def remove_cloudwatch_event_rules
        lambda_config['cloudwatch_event_rules'].each do |rule|
          @index = index
          opt_hash = parse_hash(rule)
          opts     = opt_hash.symbolize_keys
          title    = "Remove CloudWatch Event Rules"

          verbose_msg_for(title, opts)
          Lambit::Aws::CloudWatchEvents::Rule.new(opts).delete_rule unless Lambit.is_dry_run?
        end if lambda_config['cloudwatch_event_rules']
      end

      def process
        super
        # Remove Lambda Permissions
        graceful_continue { remove_lambda_permissions }

        # Remove S3 Bucket Notification Configurations
        graceful_continue { remove_s3_bucket_notification_configurations }

        # Remove CloudWatch Event Targets
        graceful_continue { remove_cloudwatch_event_targets }

        # Remove CloudWatch Event Rules
        graceful_continue { remove_cloudwatch_event_rules }
      end
    end

    register_handler_for :remove_event_sources_lambdas

    class AddAlarmsLambdas < Lambdas
      def add_alarms
        lambda_config['cloudwatch_alarms'].each_with_index do |alarm_config, index|
          @index = index
          opt_hash = parse_hash(alarm_config)
          opts     = opt_hash.symbolize_keys_deep
          title    = "Remove CloudWatch Alarms"

          verbose_msg_for(title, opts)
          Lambit::Aws::CloudWatch::Alarm.new(opts).put_metric_alarm unless Lambit.is_dry_run?
        end
      end

      def process
        super
        graceful_continue { add_alarms }
      end
    end

    register_handler_for :add_alarms_lambdas

    class DeleteAlarmsLambdas < Lambdas
      def delete_alarms
        alarm_names = []

        lambda_config['cloudwatch_alarms'].each_with_index do |alarm_config, index|
          alarm_hash = parse_hash(alarm_config)
          alarm_names << alarm_hash['alarm_name']
        end

        opts     = {:alarm_names => alarm_names}
        title    = "Delete CloudWatch Alarms"
        verbose_msg_for(title, opts)
        Lambit::Aws::CloudWatch::Alarm.new(opts).delete_alarms unless Lambit.is_dry_run?
      end

      def process
        super
        graceful_continue { delete_alarms }
      end
    end

    register_handler_for :delete_alarms_lambdas
  end
end
