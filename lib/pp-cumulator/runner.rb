require 'pp-cumulator'
require "logging"
require 'base64'
require 'jsongetter'
require 'csvwriter'
require 'jsonwriter'

module PPCumulator

	class Runner

    include Logging

    def initialize(verbose) 
      @verbose = verbose
      @verbose ? logger.level=Logger::INFO : logger.level=Logger::ERROR
      @json_data = Hash.new()
      @query_data = Array.new()
      @grouped_records = Hash.new()
      @record_list = Array.new()
    end

    def go(config)
      logger.info "PPCumulator::Runner:go:environment: #{config[:environment]} record period: #{config[:recordperiod]}"

      # for write  api calls check bearer set or exit before wasting time
      if (config[:upload] == UPLOAD_AUTO) && (config[:bearer] == BLANK_BEARER)
        logger.error "PPCumulator::Runner:go:bearer token must be set to use the auto upload"
        return
      end

      # Get the data

      # build query string based on environment
      query_url = build_query_url config
      
      # query the dataset
      json_getter = JsonGetter.new @verbose
      @json_data = json_getter.go query_url
      return unless json_getter.success?
      
      #get dataset as single processed array of hash
      @query_data = @json_data[START_KEY]

      # run the specific transform
      process_data_records config[:recordperiod]

      # output the records
      config[:upload] == UPLOAD_MANUAL ? output_to_csv(config) : output_to_json(config)

    end

    def success?
      return @success
    end

    private

    # Generics
    
    def build_query_url(config)
      logger.info "PPCumulator::Runner:build_query_url"
      query_url = API_ENVIRONMENTS[config[:environment]] + QUERY_DATASET + FIXED_QUERY_PARAMETERS + QUERY_END_AT_TEXT + Date.today.to_s + QUERY_ISO_TIME_EXTENSION
    end
    
    def process_data_records(record_period)
      logger.info "PPCumulator::Runner:process_data_records"
      build_group_hash # populate @grouped_records
      add_cumulated_value_to_records # set culumative count for each record
      build_record_list record_period
    end

    # Transform specifics
    
    def build_group_hash
      logger.info "PPCumulator::build_group_hash"
      # create array for each filtered group of data
      @query_data.each do | record_group |
        application_type = record_group["application_type"]
        academic_year = record_group["academic_year"] 
        stage = record_group["stage"]
        # get specific weekly values
        record_group["values"].each do | record |
          timestamp = pp_reformat_timestamp(record["_start_at"])
          count = record["count:sum"]
          record_hash = build_record_hash timestamp, application_type, academic_year, stage, count
          add_record_to_group_array record_hash
        end
      end
    end
    
    def build_record_hash(timestamp, application_type, academic_year, stage, count)
      readable_id = timestamp + ID_SEPARATOR + AGGREGATE_PERIOD + ID_SEPARATOR + PROVINCE+ ID_SEPARATOR + application_type+ ID_SEPARATOR + academic_year+ ID_SEPARATOR + stage
      return {
        "_id" => Base64.urlsafe_encode64(readable_id),
        "timestamp" => timestamp, 
        "period" => AGGREGATE_PERIOD,
        "group_id" => PROVINCE + application_type + academic_year + stage,
        "province" => PROVINCE,
        "application_type" => application_type,
        "academic_year" => academic_year,
        "stage" => stage,
        "count" => (count ||= 0).to_i,
        "cumulative" => (0).to_i
      }
    end
    
    def add_record_to_group_array(record_hash)
      # create hash if it doesn't exist
      unless @grouped_records.has_key?(record_hash["group_id"]) # create record based on group_id - no content
        @grouped_records[record_hash["group_id"]] = Array.new()
      end
      
      # create record - overwrite if it alewdy exists
      @grouped_records[record_hash["group_id"]] << record_hash
    end
    
    def add_cumulated_value_to_records
      logger.info "PPCumulator::Runner:build_cumulated_hash"
      # force sort order on each group of records and calculated cumulative totals
      @grouped_records.each do |record_key, record_array|
        # ensure chronological sequence - jsut in case
        record_array.sort_by!{|record| record["timestamp"] }
        cumulative_total = 0
        record_array.each do |record|
          cumulative_total = cumulative_total + record["count"]
          record["cumulative"] = cumulative_total
        end
      end
    end
    
    def build_record_list(recordperiod)
      logger.info "PPCumulator::Runner:build_resultset"
      # set the date to generate records from
      startdate_match = get_startdate_match(recordperiod)
      # extract matching records
      @grouped_records.each do |record_key, record_array|
        record_array.each do |record|
          if record["timestamp"] >= startdate_match
            @record_list << record
          end
        end
      end
      # sort array by dimensions
      @record_list.sort_by!{|record| [record["timestamp"], record["application_type"], record["academic_year"], record["stage"]] }
    end
    
    def get_startdate_match(recordperiod)
      date_last_monday = Date.today - (Date.today.cwday - CALENDAR_WEEK_START_DAY)%WEEK_DAYS
      startdate = date_last_monday - (recordperiod * WEEK_DAYS)
      startdate_match = startdate.to_s + ISO_TIME_EXTENSION
    end
    
    def pp_reformat_timestamp(timestamp)
      date = Date.parse(timestamp)
      return date.to_s + ISO_TIME_EXTENSION
    end

    # Outputs

    def output_to_csv(config)
      logger.info "PPCumulator::Runner:output_to_csv"

      # build csv contents
      out_arr = Array.new()
      out_arr << DATASET_HEADER
      @record_list.each do | record |
        out_arr << [record["timestamp"],record["period"],record["province"],record["application_type"],record["academic_year"],record["stage"],record["count"], record["cumulative"]]
      end
      # generate filename
      filename = build_output_filename CSV_FILE_EXTENSION
      # write csv out
      csv_out = CsvWriter.new(@verbose)
      csv_out.go(out_arr,filename,config[:dryrun])
      @success = csv_out.success?

    end

    def output_to_json(config)
      logger.info "PPCumulator::Runner:output_to_json"
      # remove un-needed tags
      out_arr = Array.new()
      @record_list.each do | record |
        out_arr << {"_id" => record["encoded_record_id"],
                    "_timestamp" => record["timestamp"],
                    "period" => record["period"],
                    "province" => record["province"],
                    "application_type" => record["application_type"],
                    "academic_year" => record["academic_year"],
                    "stage" => record["stage"],
                    "count" => record["count"], 
                    "cumulative" => record["cumulative"]
                  }
      end
      # set write api endpoint
      write_endpoint = build_write_endpoint config[:environment]
      # write json out
      json_out = JsonWriter.new(@verbose)
      json_out.go(out_arr,write_endpoint,config[:bearer],config[:dryrun])
      @success = json_out.success?
    end

    def build_output_filename(extension)
      return DATA_DIRECTORY + WRITE_DATASET.gsub("/","-") + FILENAME_SEPARATOR + Time.now.utc.iso8601.gsub(/\W/, '') + extension
    end

    def build_write_endpoint(environment)
      return API_ENVIRONMENTS[environment] + WRITE_DATASET
    end

  end

end
