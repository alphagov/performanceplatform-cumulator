#performanceplatform-cumulator

This repo holds a simple script application for use with the [Performance Platform](https://www.gov.uk/performance).

The application:
* extracts data from a dataset using the platform 'Read API'
* calculates the cumulative sum of student finance started and completed applications 
* uploads the new data records to dataset using the platform  ['Write API'](http://performance-platform.readthedocs.org/en/latest/api/write-api.html)

NOTE: This application is an interim solution until the platform can support this type of transform 

##Purpose
The Platform has an automated feed of Student Finance application started and submitted volumes.  Each daily record contains information about:

* academic year
* full-time or part-time application
* province of applicant
* paper or digital application
* application state

e.g.
```
{
    _id: "9cfa5c1fc9f4286df31f54dd2f050d6f",
    _timestamp: "2014-05-18T00:00:00+00:00",
    academic_year: "2013/14",
    application_type: "full-time application",
    channel: "digital",
    count: 26,
    country: "england",
    new_or_continuing: "new",
    province: "england",
    stage: "started",
    sub_channel: "digital"
}
```

The online process has a 'save and return' facility allowing users to complete their application over a period of time.  
Completion rate for the service is calculated as:

ratio of 'total number of applications submitted online'/'total number of applications started online'

It is measured across the entirety of the application 'window' (approx. 18 months)

The application calculates the cumulative sum of application 'starts' and 'submits' for each category across the total application period.  The 'cumulative' sum is then appended to the record, un-required tags removed, and uploaded to the platform in an different dataset.

e.g.
```
{
    _id:     "MjAxNC0wMi0wM1QwMDowMDowMFoud2Vlay5lbmdsYW5kLmZ1bGwtdGltZSBhcHBsaWNhdGlvbi4yMDE0LzE1LnN0YXJ0ZWQ=",
    _timestamp: "2014-02-03T00:00:00+00:00",
    academic_year: "2014/15",
    application_type: "full-time application",
    count: 19250,
    cumulative: 62873,
    period: "week",
    province: "england",
    stage: "started"
}
```
 
##Running the application
To view the options for running the application:
```
$ ./bin/pp-cumulator -h
```

To see the application run options:
```
$ ./bin/pp-cumulator -h go
```

To run the application:
```
$ ./bin/pp-cumulator go --environment=<environment> --verbose=<verbose-flag> --recordperiod=<no. of weeks> --dryrun=<dryrun-flag> --upload=<upload>  --bearer=<bearer-token>
```

The main purpose of the application is to automate the extraction, transformation and upload of json data, but it can be configured to output a csv formatted file for manual upload to the platform.# performanceplatform-cumulator
