module PPCumulator
  
  # environment parameter constants
  API_ENVIRONMENTS = {"production" => "https://www.performance.service.gov.uk/data/","preview" => "https://www.preview.performance.service.gov.uk/data/"}
  PRODUCTION = "production"
  PREVIEW = "preview"

  # input parameter constants
  UPLOAD_MANUAL = "manual"
  UPLOAD_AUTO = "auto"

  # Query constants
  RECORD_PERIOD_DEFAULT = 7
  #DEFAULT_PERIOD = "day"

  QUERY_DATASET = "student-finance/transactions-by-channel"
  FIXED_QUERY_PARAMETERS = "?collect=count%3Asum&group_by=academic_year&group_by=stage&group_by=application_type&start_at=2012-12-31T00%3A00%3A00Z&period=week&filter_by=province%3Aengland&filter_by=channel%3Adigital"
  PERIOD_TEXT = "&period="
  DURATION_TEXT = "&duration="
  QUERY_END_AT_TEXT = "&end_at="
  QUERY_ISO_TIME_EXTENSION = "T00%3A00%3A00Z"

  # Data processing constants
  GROUPING_ID = ["province", "application_type", "academic_year", "stage"]
  RECORD_ID = ["_timestamp", "period", "province", "application_type", "academic_year", "stage"]
  DATASET_HEADER = ["_timestamp","period","province","application_type","academic_year","stage","count","cumulative"]
  AGGREGATE_PERIOD = "week"
  PROVINCE = "england"
  ID_SEPARATOR ="."
  CALENDAR_WEEK_START_DAY = 1 #assumes monday start date - 1
  WEEK_DAYS = 7
  ISO_TIME_EXTENSION = "T00:00:00Z"
  #ISO_TIME_EXTENSION = "T00:00:00+00:00"
  START_KEY = "data"

  # csv output constants
  APP_NAME_TEXT = "pp-cumulator"
  FILENAME_SEPARATOR = "-"
  DATA_DIRECTORY = "./data/"
  CUMULATOR_TEXT ="cumulative"
  CSV_FILE_EXTENSION = ".csv"

  #json output constants
  BEARER_ID = "foo"
  MEDIA_TYPE = "application/json"
  JSON_FILE_EXTENSION = ".json"

  WRITE_DATASET = "student-finance/slc-cumulative-completion-rate-source"
  BLANK_BEARER = "foo"

end
