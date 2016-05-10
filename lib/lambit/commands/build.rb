# encoding: UTF-8

require 'json'
require 'fileutils'

using Lambit::Common::StringHelper

module Lambit::Commands
  module Build
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

    class PackageTemplatesCommand < Lambit::Commands::Common::Base
      attr_reader :workspace
      attr_reader :project_path
      attr_reader :tmpl_name
      attr_reader :tmpl_config

      def initialize(opts, args)
        super
        @workspace = opts['workspace']
        @project_path = opts['project_path']
        @tmpl_name = args[0]
        @tmpl_config = args[1]
      end

      def command
        tmpl = JSON.parse(File.read("#{self.project_path}/templates/#{self.tmpl_name}"))
        tmpl.merge!(self.tmpl_config) unless self.tmpl_config.nil?

        begin
          File.open("#{self.workspace}/#{self.tmpl_name}",'w') do |f|
            f.write(tmpl.to_json)
          end
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

    register_handler_for :package_templates_command

    class Base < Lambit::Commands::Subcommands::Base
      attr_reader :workspace

      def initialize(opts, args)
        super
        @workspace = opts['workspace']
      end
    end

    class PackagePipCommand < Base
      attr_reader :pip

      def initialize(opts, args)
        super
        @pip = args[0]
      end

      def subcommand
        @subcommand = "pip install #{self.pip} -q -t #{workspace}/."
      end
    end

    register_handler_for :package_pip_command

    class PackageSourceCommand < Base
      attr_reader :project_path

      def initialize(opts, args)
        super
        @project_path = opts['project_path']
      end

      def subcommand
        @subcommand = "cp -r #{project_path}/function/* #{workspace}"
      end
    end

    register_handler_for :package_source_command

    class CompressPackageCommand < Base
      def subcommand
        @subcommand = "cd #{workspace} && zip -r package.zip *"
      end
    end

    register_handler_for :compress_package_command
  end
end
