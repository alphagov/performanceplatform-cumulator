require 'logging'
require 'json'
require 'net/http'
require 'openssl'
require 'uri'

class JsonWriter

  include Logging

  def initialize(verbose) 
    @verbose = verbose
    @verbose ? logger.level=Logger::INFO : logger.level=Logger::ERROR
    @success = false
  end
  
  def go(data, url, bearer_token, dryrun=false)
    logger.info "JsonWriter::go"
    
    @out_arr = data
    @url = url
    @bearer_token = bearer_token
    
    dryrun ? output_to_console : output_to_repo

  end

  def success?
    @success
  end

  def status?
    @status
  end

  private

  def output_to_console
    logger.info "JsonWriter::output_to_console"
    puts JSON.pretty_generate(@out_arr)
    @success = true
  end

  def output_to_repo
    logger.info "JsonWriter::output_to_repo"
    begin
      json_data = @out_arr.to_json
      uri = URI.parse(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = @out_arr.to_json
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{@bearer_token}"
      
      response = http.request(request)
      logger.info "JsonWriter::go:Status code: #{response.code}"
      logger.info "JsonWriter::go:Status message: #{response.message}"
      
      @status = response.code

      set_results
    rescue => ex
      logger.error "JsonWriter::output_to_repo:failed to POST: " + url + " : Exception: #{ex.class}:#{ex}"
      @success = false
    end
  end

  def set_results
    if status_ok?
      logger.info "JsonWriter::go:success"
      @success = true
    else
      logger.info "JsonWriter::go:fail"
      @success = false
    end
  end

  def status_ok?
    return true if @status =="200"
    logger.error "JsonWriter::status_ok?:unexpected response code: #{@status}"
    return false
  end

end
