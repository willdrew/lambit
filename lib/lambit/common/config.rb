# encoding: UTF-8

require 'yaml'
require 'singleton'

module Lambit
  module Common
    class Config
      include Singleton

      attr_reader :global_options
      attr_reader :config

      def init_config(options)
        @global_options = options
        project_path    = options['project-path']
        config_filename = options['config-filename'] || 'lambit.yml'

        config_path = ::File.join(project_path, config_filename)
        exit_now!("#{config_filename} file not found!") unless File.exist?(config_path)
        @config = YAML.load_file(config_path)
      end
    end
  end

  def self.config
    return Lambit::Common::Config.instance.config
  end

  def self.global_options
    return Lambit::Common::Config.instance.global_options
  end

  def self.is_verbose?
    return Lambit::Common::Config.instance.global_options[:verbose]
  end

  def self.is_dry_run?
    return Lambit::Common::Config.instance.global_options['dry-run']
  end

  def self.is_debug?
    return Lambit::Common::Config.instance.global_options[:debug]
  end
end
