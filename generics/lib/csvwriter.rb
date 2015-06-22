require "logging"
require 'csv'

class CsvWriter

  include Logging

  def initialize(verbose) 
    @verbose = verbose
    @verbose ? logger.level=Logger::INFO : logger.level=Logger::ERROR
    @success = false
  end

  def go(data, filename, dryrun=false)
    logger.info "CsvWriter::go"
    @out_arr = data
    dryrun ? output_to_console : output_to_file(filename)
  end

  def success?
    return @success
  end

  private

  def output_to_console
    logger.info "CsvWriter::output_to_console"
    @out_arr.each do |row|
      puts row.join(',')
    end
    @success = true
  end

  def output_to_file(filename)
    logger.info "CsvWriter::output_to_file"
    begin
      out_file = CSV.open(filename, "wb")
      @out_arr.each do |row|
        out_file << row
      end
      logger.info "CsvWriter::output_to_file:file created: #{filename}"
      @success = true
    rescue => ex
      logger.error "CsvWriter::output_to_file:failed to create file: Exception: #{ex.class}:#{ex}"  
      @success = false    
    ensure 
      out_file.close unless out_file.nil?
    end
  end

end
