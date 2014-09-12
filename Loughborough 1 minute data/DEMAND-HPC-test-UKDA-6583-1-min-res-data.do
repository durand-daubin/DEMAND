* Process Loughbourough 1 minute resolution data
* Iridis 3 HPC test analysis
* b.anderson@soton.ac.uk
local where "/home/ba1e12"

local idpath "`where'/data/1minlboro"
local rpath "`where'/results/1minlboro"


* v1.0 = census day 2008
local vers "v1.0"

capture log close
set more off

log using "`rpath'/DEMAND-HPC-test-UKDA-6583-1-min-res-data-`vers'-$S_DATE.smcl", replace

* control what is run
local do_basics 0

************************
* start with survey data
use "`idpath'/survey-data-wf_v9.dta", clear

* keep useful variables
keep hh_id ba_*

* add energy data (filled, full)
merge 1:m hh_id using "`idpath'/power_perhh_perday_per30m_v9.dta"

/*
NB: User Guide states
DATETIME_GMT  - The time stamp of the meter reading as Greenwich Mean Time (GMT).DATETIME_LOCAL  - The time stamp of the reading taking British Summer Time (BST) into account.IMPORT_KW  The mean power demand during the one?minute period starting at the time stamp.The date time fields are formatted as <YEAR>/<MONTH>/<DAY> <HOUR>:<MINUTE>.Where data is not available for a given minute, no row exists in the file. 
Note that no data is available for two of the meters in 2009, and hence two of the files are empty.
*/

*****************
* Do some missing data checks

* this should alreay be set
* xtset hh_id timestamp_gmt, delta(1 minute)
* make sure

xtset hh_id ddate_gmt, delta(1 day)


log close
