# encoding: UTF-8

require 'time'

using Lambit::Common::StringHelper

module Lambit::Commands
  module Common
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

    class Base
      attr_reader :run
      attr_reader :dry_run
      attr_reader :exitstatus

      def initialize(opts, args)
        @dry_run          = opts['dry-run']
        @exitstatus       = 1
      end

      def self.run(opts, args)
        output, exitstatus = self.new(opts, args).execute
        return output, exitstatus
      end

      def command
        return '', self.exitstatus
      end

      def execute
        command
      end
    end

    class CreateWorkspaceCommand < Base
      attr_reader :workspace

      def initialize(opts, args)
        super
        @workspace = opts['workspace']
      end

      def command
        begin
          FileUtils.mkdir_p self.workspace
          @exitstatus = 0
        rescue Exception => e
          if Lambit.is_debug?
            Lambit.logger.error e
          else
            Lambit.logger.error e.message
          end
          @exitstatus = 1
        end
        return '', self.exitstatus
      end
    end

    register_handler_for :create_workspace_command
  end
end
