require 'logger'

module Logging

  # to mix in to classes
  def logger
    Logging.logger
  end

  # global lazy initialized instance of a logger
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

end
