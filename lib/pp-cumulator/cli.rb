require "pp-cumulator"
require "runner"
require "version"
require "thor"
require "logging"
require 'time'

module PPCumulator

  class CLI < Thor

    include Logging

    desc "go", "Reads identified dataset from <environment>, calculates the cumulative total of transactions and generates records to be uploaded to the performance platform"
    option :environment, :type => :string, :required => true, :desc => "sets the Performance Platform source instance: '#{PRODUCTION}' or '#{PREVIEW}'"
    option :verbose, :type => :boolean, :default => false, :desc => "logs user messages to the console: <false> - errors only, <true> - info and errors"
    option :upload, :type => :string, :default => UPLOAD_MANUAL, :desc => "identifies upload format: <#{UPLOAD_MANUAL}> - creates formatted csv file for manual upload, <#{UPLOAD_AUTO}> - uploads json records via wrtite api"
    option :bearer, :type => :string, :default => BLANK_BEARER, :desc => "mandatory bearer token for json write api uploads"
    option :dryrun, :type => :boolean, :default => false, :desc => "outputs data records to console only: <false> - executes based on :upload parameter, <true> - outputs data records to console only"
    option :recordperiod, :type => :numeric, :default => RECORD_PERIOD_DEFAULT, :desc => "the latest <recordperiod> number of weeks worth of data to generate (default = #{RECORD_PERIOD_DEFAULT})"
  
    def go()
      @verbose = options[:verbose] 
      @config = {:environment => options[:environment], :upload => options[:upload], :recordperiod => options[:recordperiod], :bearer => options[:bearer], :dryrun => options[:dryrun]}

      # set logging level
      @verbose ? logger.level=Logger::INFO : logger.level=Logger::ERROR

      logger.info "PPCumulator::CLI:go:start: #{Time.now.utc.iso8601}"
      log_configuration_setup if @verbose

      # do the 'thing'
      runner = Runner.new(@verbose)
      runner.go(@config)

      logger.info "PPCumulator::CLI:go:finish: #{Time.now.utc.iso8601}"

    end

    desc "version","Outputs the current version of the application"
    def version
      say "version: #{VERSION}"
    end

    private

    def log_configuration_setup
      @config.each do |k,v|
        logger.info "PPCumulator::CLI:config: #{k}: #{v}"
      end
    end

  end

end
