# encoding: UTF-8

using Lambit::Common::StringHelper

module Lambit::Commands
  module Subcommands
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
      attr_reader :subcommand
      attr_reader :dry_run
      attr_reader :exitstatus

      def initialize(opts, args)
        @dry_run          = opts['dry-run']
        @exitstatus       = 1
      end

      def self.run(opts, args)
        output, exitstatus = self.new(opts, args).run
        return output, exitstatus
      end

      def subcommand
        @subcommand = nil
      end

      def output(stdout)
        stdout
      end

      def run
        raise "subcommand can't be nil" if subcommand.nil?

        if dry_run
          stdout      = "DRY RUN: Subcommand => #{subcommand}"
          @exitstatus = 0
        else
          # puts "Running: Subcommand => #{subcommand}"
          stdout      = `#{subcommand}`
          @exitstatus = $?.exitstatus
        end

        return output(stdout), self.exitstatus
      end

      def successful?
        self.exitstatus == 0
      end

      def is_successful?(status)
        status == 0
      end
    end
  end
end
