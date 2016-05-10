# encoding: UTF-8

require 'logger'
require 'singleton'

$stdout.sync = true

module Lambit
  module Common
    class SimpleLogger < ::Logger
      include Singleton

      def initialize(logdev=nil, shift_age=nil, shift_size=nil)
        super
        @logdev = ::Logger::LogDevice.new(STDOUT)
        @level  = INFO
      end
    end
  end

  def self.logger
    return Lambit::Common::SimpleLogger.instance
  end
end
