require 'logging'
require 'net/http'
require 'openssl'
require 'uri'
require 'json'

class JsonGetter

  include Logging

  def initialize(verbose)      
    @verbose = verbose
    @verbose ? logger.level=Logger::INFO : logger.level=Logger::ERROR
    @success = false
  end

  def go(url)
    logger.info "JsonGetter::go"

    begin
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      logger.info "JsonGetter::go:Status code: #{response.code}"
      logger.info "JsonGetter::go:Status message: #{response.message}"

      @status =  response.code
      @body =  JSON.parse(response.body)
      @content_type = response["content-type"]

      set_results

    rescue => ex
      logger.error "JsonGetter::go:unable to GET: " + url + " : Exception: #{ex.class}:#{ex}"
      # absorb exceptions
      @success = false
      @record_data = nil
    end
    return @record_data
  end

  def success?
    return @success
  end

  def status?
    return @status
  end

  private

  def set_results
    if status_ok? and content_type_ok? and content_ok?
      logger.info "JsonGetter::go:success"
      @record_data = @body
      @success = true
    else
      logger.info "JsonGetter::go:fail"
      @record_data = nil
      @success = false
    end
  end

  def status_ok?
    return true if @status =="200"
    logger.error "JsonGetter::status_ok?:unexpected response code: #{@status}"
    return false
  end

  def content_type_ok?
    return true if @content_type == "application/json"
    logger.error "JsonGetter::content_type_ok?:unexpected content type: #{@content_type}"
    return false
  end

  def content_ok?
    if (@body.nil? || @body.empty?)
      logger.error "JsonGetter::content_ok?:no/empty message body"
      return false
    end
    return true
  end

end
