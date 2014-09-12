* Exploratory analysis for DEMAND
* Uses ONS Time Use 2000/1 survey to look at location of respondents over time of day and day of week
* creates a summary data file for each location code over time of day and day of week
* generates a line chart for each location code with 7 lines (days of week) across hour of day
* merges the summary data into 1 file for future use

clear all

* change these to run this script on different PC
local where "/Users/ben/Documents/Work"
local projroot "`where'/Projects/RCUK-DEMAND"
local rpath "`projroot'/Theme 1/results/ONS TU 2000"

* location of time-use diary data
local dpath "`where'/Data/Social Science Datatsets/Time Use 2000/stata/2003 release/stata8_se/"

* use the ungrossed non-response weight
* this just corrects for survey/diary non-response - we don;t need to gorss up to the population
* as we're not interested in total minutes etc
local wt = "wtdry_ug"

* version
* 1.0 = no seasonal or regional analysis
local v = "1.0"

capture log close

* save log file (with version)
log using "`rpath'/BA-UK-2000-TU-analysis-location-v`v'-$S_DATE.smcl", replace

* use this to switch on/off the summarising below
local do_collapse 0

* make script run without waiting for user input
set more off

* get diary data
use "`dpath'/diary_data_8.dta", clear

* keep the ones deemed fit for analysis by the ONS (see user guide)
tab dry_ind

drop if dry_ind != 1

* check age distributions
tab dagegrp
* so is all sample - including children

* check unweighted & weighted n per weekday
* NB - remember this includes all respondents and that respondents (should have) completed
* 1 diary for a weekday and 1 diary for a weekend day

* unweighted
tab ddayofwk
* so c 2,000 diaries on each weekday but nearly 5,000 on each weekend day (why?)

* weighted
tab ddayofwk [iw= `wt']

* so c 2,900 (weighted) diaries per day

* keep xmas 2000
* keep if dday == 25 & dmonth == 12
* only 7 respondents!

* set up seasons variable
gen ba_season = "unallocated"
replace ba_season =  "Winter" if dmonth == 12 | dmonth == 1 | dmonth == 2
replace ba_season =  "Spring" if dmonth == 3 | dmonth == 4 | dmonth == 5
replace ba_season =  "Summer" if dmonth == 6 | dmonth == 7 | dmonth == 8
replace ba_season =  "Autumn" if dmonth == 9 | dmonth == 10 | dmonth == 11

* keep only location & activity data to reduce dataset size
keep sn* dtype dday dmonth dyear dage dagegrp dsex ddayofwk gorpaf wtdry_gr wtdry_ug act1* act2* wher_* ba_*

* list location possibilities
lab li wher_001
* this gives us:
/*

          -9 main actvty = sleep/work/study - no code required
          -1  missing
           0  unspecified location 
           1  unspecified location (not travelling) 
           2  home 
           3  second home or weekend house 
           4  working place or school 
           5  other people's home 
           6  restaurant, café or pub 
           7  sports facility 
           8   arts or cultural centre 
           9  the country/ countryside, seaside, beach or coast 
          10  other specified location (not travelling) 
          11  unspecified private transport mode 
          12  travelling on foot 
          13  travelling by bicycle 
          14  travelling by moped, motorcycle or motorboat 
          15  travelling by passenger car as the driver 
          16  travelling by passenger car as a passenger 
          17  travelling by passenger car – driver status unspecified 
          18  travelling by lorry, or tractor 
          19  travelling by van 
          20  other specified private travelling mode 
          21  unspecified public transport mode 
          22  travelling by taxi 
          23  travelling by bus  
          24  travelling by tram or underground 
          25  travelling by train 
          26  travelling by aeroplane 
          27  travelling by boat or ship 
          28   travelling by coach 
          29  waiting for public transport 
          30  other specified public transport mode 
          31  unspecified transport mode 
          32  illegible location or transport mode 
*/


* set up labels for different locations

local loc0  "unspecified location"
local loc1  "unspecified location (not travelling)"
local loc2  "home - as coded (i.e. not sleeping)"
* this is the imputed sleep when location not specified (see user guide and -9 code above)
local loc201 "home - imputed (sleep)"
local loc3  "second home or weekend house"
local loc4  "working place or school - as coded (not working or in class)"
* this is the imputed work place or school when location not specified (see user guide and -9 code above)
local loc401 "working place or school - imputed (working or in class)"
local loc5  "other people's home"
local loc6  "restaurant, cafe or pub"
local loc7  "sports facility"
local loc8  "arts or cultural centre"
local loc9  "the country, countryside, seaside, beach or coast"
local loc10  "other specified location (not travelling)"
local loc11  "unspecified private transport mode"
local loc12  "travelling on foot"
local loc13  "travelling by bicycle" 
local loc14  "travelling by moped, motorcycle or motorboat"
local loc15  "travelling by passenger car as the driver"
local loc16  "travelling by passenger car as a passenger"
local loc17  "travelling by passenger car - driver status unspecified"
local loc18  "travelling by lorry, or tractor"
local loc19  "travelling by van"
local loc20  "other specified private travelling mode"
local loc21  "unspecified public transport mode"
local loc22  "travelling by taxi"
local loc23  "travelling by bus"
local loc24  "travelling by tram or underground"
local loc25  "travelling by train"
local loc26  "travelling by aeroplane"
local loc27  "travelling by boat or ship"
local loc28  "travelling by coach"
local loc29  "waiting for public transport"
local loc30  "other specified public transport mode"
local loc31  "unspecified transport mode"
local loc32  "illegible location or transport mode"

* if and foreach loop to collapse the diary data to a table of proportions per location per day per time of day
* also generates graphs (could be seperated out)
* as a control mechanism, only do this if local do_collapse == 1
if `do_collapse' == 1 {
	* ignore -1 (see location codes above) as seems not to be used. 
	
	* code imputed exceptions 201 and 401 to replace '-9' (see location codes above)
	* 201 = sleep (110) 
	*	[sick in bed = 120?]
	
	* 401 = working in main, second job (1110, 1210) + classes/lectures (2110)
	*	should we include [coffee & lunch breaks? 1120,1310]?;  
	*   and [homework? 2120; other study 2190, 2210?]
	
	* quietly loop over the location codes and set up the imputed 201 & 401 codes
	* this will replace missing data (".") with either 201 or 401 as appropriate
	
	* don't do this anymore - too confusing
	foreach v of numlist 1/9 {
		* time slot 1-9
		qui: replace wher_00`v' = 2 if act1_00`v' == 110
		qui: replace wher_00`v' = 4 if act1_00`v' == 1110 | act1_00`v' == 1210 | act1_00`v' == 2110
	}
	foreach v of numlist 10/99 {
		* time slot 10-99
		qui: replace wher_0`v' = 2 if act1_0`v' == 110
		qui: replace wher_0`v' = 4 if act1_0`v' == 1110 | act1_0`v' == 1210 | act1_0`v' == 2110
	}
	foreach v of numlist 100/144 {
		* time slot 100-144
		qui: replace wher_`v' = 2 if act1_`v' == 110
		qui: replace wher_`v' = 4 if act1_`v' == 1110 | act1_`v' == 1210 | act1_`v' == 2110
	}
	
	* now loop over all possible location codes and create a count of how many times the given location is reported
	* at a given time of day (i.e. time slot 1 to slot 144)
	
	* 201 401 = imputed
	* ignore 0
	* 0(1)32 
	
	foreach l of numlist 0(1)32 {
		di "Processing location `l': `loc`l''"
		
		* preserve data here 
		* 1. so location vars are not kept at each iteration (too many vars by the time = 32!)
		* 2. as we are going to collapse it to get means and we then need the data back for the next loop
		
		preserve
		
		* quietly count number of times location is reported at each time of day (t = 1-144) for this location (l)
		foreach t of numlist 1/9 {
			* time slot 1-9
			qui: egen wher_`t's_loc`l' = anycount(wher_00`t'), values(`l')
		}
		foreach t of numlist 10/99 {
			* time slot 10-99
			qui: egen wher_`t's_loc`l' = anycount(wher_0`t'), values(`l')
		}
		foreach t of numlist 100/144 {
			* time slot 100-144
			qui: egen wher_`t's_loc`l' = anycount(wher_`t'), values(`l')
		}
		
		* uncomment these lines to get descriptives
		*di "* test ranges"
		*su wher_*s_loc`l'
		
		* collapse to calculate a mean for each time slot for a given location (l) for each day of week
		* this can then be transposed & used for line graphs
		* use non-grossing weight to correct for non response

		* XX must be a better way to do this with all locations in same table?
		
		collapse (mean) wher_*s_loc`l' [iw= `wt'], by(ddayofwk)
		
		* the mean will be the proportion reporting this location (l) at this time of day
		* change to %
		
		foreach v of varlist wher_*s_loc`l' {
			replace `v' = `v' * 100
		}
			
		* NB - remember this includes all respondents and that respondents (should have) completed
		* 1 diary for a weekday and 1 diary for a weekend day
				
		* the dataset is the wrong way round to draw the graphs so
		* transpose it so day of the week is a variable and time slot is a value
		* make sure we keep original variable names in _varname
		xpose, clear varname
		
		* check data shape/format
		li in 1/4
				
		* the first row is now just the days of the week - not needed
		* drop dayofweek variable row
		drop in 1
		
		* attempt to make better labels for chart by calculating hour of day
		* really should turn this into a meaningful time format and then use a time series (ts) line chart
		* real number
		gen time_slot_i = 0
		* time format
		gen time_slot_f = "0:00"
		* each slot is 10 mins (here)
		foreach ts of numlist 1/144 {
			di "* Changing slot `ts' for location `l': `loc`l''"
			* remember to add 4 as 0 = 04:00
			* create real number format
			qui: replace time_slot_i = ((`ts'*10)/60)+4 if _varname == "wher_`ts's_loc`l'"
			
			* creat hour: min format
			* NB - this will code the time as the time at the END of the timeslot - so first one is '04:10'
			local hour = floor((`ts'*10)/60)+4
			* fix for when we go over midnight
			if `hour' >= 24 {
				local hour = `hour' - 24
			}
			local mins = mod((`ts'*10),60)
			* fix for on the hour
			if `mins' == 0 {
				local mins = "00"
			}
			di "timeslot `ts' = `hour':`mins'"
			qui: replace time_slot_f = "`hour':`mins'" if _varname == "wher_`ts's_loc`l'"
		}
		tab time_slot_f
		
		* rename & label the variables to be meaningful
		rename v1 monday_loc`l'
		lab var monday_loc`l' "Monday `loc`l''"
		rename v2 tuesday_loc`l'
		lab var tuesday_loc`l' "Tuesday `loc`l''"
		rename v3 wednesday_loc`l'
		lab var wednesday_loc`l' "Wednesday `loc`l''"
		rename v4 thursday_loc`l'
		lab var thursday_loc`l' "Thursday `loc`l''"
		rename v5 friday_loc`l'
		lab var friday_loc`l' "Friday `loc`l''"
		rename v6 saturday_loc`l'
		lab var saturday_loc`l' "Saturday `loc`l''"
		rename v7 sunday_loc`l'
		lab var sunday_loc`l' "Sunday `loc`l''"

		
		di "* Summary for location `l': `loc`l''"

		su *_loc`l'
		
		
		* check descriptives if you wish
		* tabstat *_loc`l', by(time_slot_i)
		
		* create formated time variable 
		gen time_slot_dt = clock(time_slot_f, "hm")
		* use the format to force the graph to display only hours of the day as
		* stata graph label options don't have a way to specifiy hours from an hours:minuutes variable
		format time_slot_dt %tcHH
		* tell stata this is a time series with a delta of 10 minutes
		tsset time_slot_dt, delta(10 minutes)
		* draw time series line chart
		tsline *_loc`l', name(loc`l'ts) title("`loc`l''") ///
			ytitle("% of sample (weighted)") xtitle("Hour of Day") tlabel(#23) ///
			lcolor(gs12 gs9 gs6 gs3 gs0 orange red)
		
		* di "* saving graph to file"
		graph export "`rpath'/graphs/location/tsline_location_`l'_`loc`l''_by_hour_day_`wt'.png", replace
		
		* save summary data table
		save "`rpath'/data_temp/wher_`l'_`wt'.dta", replace
		
		di "* restoring data so can loop to next location"
		restore
	}
}

* should now be able to merge them using time_slot
* start with 0
use "`rpath'/data_temp/wher_0_`wt'.dta", clear
foreach loc of numlist 1(1)32 {
	merge 1:1 time_slot_i using "`rpath'/data_temp/wher_`loc'_`wt'.dta"
	drop _merge
}

keep time_slot_f wednesday* friday* saturday*
order time_slot_f wed* fri*

* dump datafile for excel
outsheet using "`rpath'/ONS-TU-2000-location-by-hour-dow-weds-fri-sat-`wt'.txt", replace
export excel using "`rpath'/ONS-TU-2000-location-by-hour-dow-weds-fri-sat-wtdry_ug.xls", firstrow(varlabels) replace


save "`rpath'/ONS-TU-2000-location-by-hour-dow-`wt'.dta", replace

log close


