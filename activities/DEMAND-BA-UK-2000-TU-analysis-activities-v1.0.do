* Exploratory analysis for DEMAND
* Uses ONS Time Use 2000/1 survey to look at activities of respondents over time of day and day of week
* creates a summary data file for each activity code over time of day and day of week
* generates a line chart for each activity code with 7 lines (days of week) across hour of day
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
log using "`rpath'/BA-UK-2000-TU-analysis-activities-v`v'.smcl", replace

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

* list all activity possibilities
lab li act1_001
* this gives us a massive list
/*
of interest here:

	210 eating
	
	3100 unspecified food management 
	3110 food preparation
	3120 baking
	3130 dish washing
	3320 ironing
	3310 laundry

    3720 unspecified household management using the internet
    3721 shping for&ordring unspec gds&srvs via internet
    3722 shping for&ordring food via the internet
    3723 shping for&ordring clothing via the internet
    3724 shping for&ordring gds&srv related to acc via internet
    3725 shping for&ordring mass media via the internet
    3726 shping for&ordring entertainment via the internet
    3727 banking and bill paying via the internet
    3729 other specified household management using the internet

7231 information searching on the internet
7241 communication on the internet
7251 unspecified internet use

        8000 unspecified mass media
        8100 unspecified reading
        8110 reading periodicals
        8120 reading books
        8190 other specified reading
        8210 unspecified tv watching
        8211 watching a film on tv
        8212 watching sport on tv 
        8219 other specified tv watching
        8220 unspecified video watching
        8221 watching a film on video
        8222 watching sport on video
        8229 other specified video watching

	9950 filling in the time use diary

 */

local act210 "eating"
local act3100 "unsp_food_mgt"
local act3110 "food_prep"

local act3120 "baking"
local act3130 "dishwashing"
local act3310 "laundry"
local act3320 "ironing"


local act9950 "diary_completion"

local activities "210 3110 3120 3130 3310 3320"

* if and foreach loop to collapse the diary data to a table of proportions per location per day per time of day
* also generates graphs (could be seperated out)
* as a control mechanism, only do this if local do_collapse == 1
if `do_collapse' == 1 {
	
	* now loop over the activities of interest and create a count of how many times the given activity is reported
	* at a given time of day (i.e. time slot 1 to slot 144)
	
	
	foreach a of local activities {
		di "Processing activity `a': `act`a''"
		
		* preserve data here 
		* 1. so activity vars are not kept at each iteration (too many vars by the time = 32!)
		* 2. as we are going to collapse it to get means and we then need the data back for the next loop
		
		preserve
		
		* quietly count number of times location is reported at each time of day (t = 1-144) for this location (l)
		di "* time slot 1-9"
		foreach t of numlist 1/9 {
			qui: egen act_`t's_act1`a' = anycount(act1_00`t'), values(`a')
		}
		di "* time slot 10-99"
		foreach t of numlist 10/99 {
			qui: egen act_`t's_act1`a' = anycount(act1_0`t'), values(`a')
		}
		di "* time slot 100-144"
		foreach t of numlist 100/144 {	
			qui: egen act_`t's_act1`a' = anycount(act1_`t'), values(`a')
		}
		
		* uncomment these lines to get descriptives
		*di "* test ranges"
		*su wher_*s_loc`l'
		
		* collapse to calculate a mean for each time slot for a given location (l) for each day of week
		* this can then be transposed & used for line graphs
		* use non-grossing weight to correct for non response

		* XX must be a better way to do this with all locations in same table?
		
		collapse (mean) act_*s_act1`a' [iw= `wt'], by(ddayofwk)
		
		* the mean will be the proportion reporting this activity (a) at this time of day
		* change to %
		
		foreach v of varlist act_*s_act1`a' {
			qui: replace `v' = `v' * 100
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
			*di "* Changing slot `ts' for activity `l': `loc`l''"
			* remember to add 4 as 0 = 04:00
			* create real number format
			qui: replace time_slot_i = ((`ts'*10)/60)+4 if _varname == "act_`ts's_act1`a'"
			
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
			*di "timeslot `ts' = `hour':`mins'"
			qui: replace time_slot_f = "`hour':`mins'" if _varname == "act_`ts's_act1`a'"
		}
		*tab time_slot_f
		
		* rename & label the variables to be meaningful
		rename v1 monday_act`a'
		lab var monday_act`a' "Monday `act`a''"
		rename v2 tuesday_act`a'
		lab var tuesday_act`a' "Tuesday `act`a''"
		rename v3 wednesday_act`a'
		lab var wednesday_act`a' "Wednesday `act`a''"
		rename v4 thursday_act`a'
		lab var thursday_act`a' "Thursday `act`a''"
		rename v5 friday_act`a'
		lab var friday_act`a' "Friday `act`a''"
		rename v6 saturday_act`a'
		lab var saturday_act`a' "Saturday `act`a''"
		rename v7 sunday_act`a'
		lab var sunday_act`a' "Sunday `act`a''"

		
		di "* Summary for activity `a': `act`a''"

		su *_act`a'
		
				
		* create formated time variable 
		qui: gen time_slot_dt = clock(time_slot_f, "hm")
		* use the format to force the graph to display only hours of the day as
		* stata graph label options don't have a way to specifiy hours from an hours:minutes variable
		format time_slot_dt %tcHH
		* tell stata this is a time series with a delta of 10 minutes
		tsset time_slot_dt, delta(10 minutes)
		* draw time series line chart
		tsline *_act`a', name(tsl_`act`a'') title("`act`a''") ///
			ytitle("% of sample (weighted)") xtitle("Hour of Day") tlabel(#23) ///
			lcolor(gs12 gs9 gs6 gs3 gs0 orange red)
		
		* di "* saving graph to file"
		graph export "`rpath'/graphs/activities/tsline_activity_`a'_`act1`a''_by_hour_day_`wt'.png", replace
		
		* save summary data table
		save "`rpath'/data_temp/act1_`a'_`wt'.dta", replace
		
		*graph matrix *_act`a', half name(matr_`act`a'') title("`act`a''")
		*graph export "`rpath'/graphs/activities/matrix_activity_`a'_`act1`a''_by_hour_day_`wt'.png", replace
		
		di "* restoring data so can loop to next location"
		restore
	}
}

* should now be able to merge them using time_slot
* always start with 201
use "`rpath'/data_temp/act1_3100_`wt'.dta", clear
foreach a of local activities {
	merge 1:1 time_slot_i using "`rpath'/data_temp/act1_`a'_`wt'.dta"
	drop _merge
	*erase "`rpath'/data_temp/act1_`a'_`wt'.dta"
}

* create entropy based SSI
* probably needs to run on all categories to calculate correctly?
/*
local activities "3110 3120 3130 3310 3320 9950"
local days "monday tuesday wednesday thursday"
foreach a of local activities {
	foreach d of local days {
		qui: gen act`a'entropy_`d' = (`d'_act`a' * ln(`d'_act`a'))
	}
	egen act`a'entropy = rowtotal(act`a'entropy_*)
	drop act`a'entropy_*
	tsset time_slot_dt, delta(10 minutes)
	* draw time series line chart
	tsline act`a'entropy, name(tsl_`act`a''entropy) title("`act`a''") ///
			ytitle("entropy value") xtitle("Hour of Day") tlabel(#23)
}
*/
* synchronised activities charts

*210 eating

*3100 unspecified food management 
*3110 food preparation
*3120 baking
*3130 dish washing
*3320 ironing
*3310 laundry

tsset time_slot_dt, delta(10 minutes)
* feed prep, eating, washing up on Sundays
tsline sunday_act3110 sunday_act210 sunday_act3130, ytitle("% of sample")

save "`rpath'/ONS-TU-2000-activity-by-hour-dow-`wt'.dta", replace


log close


