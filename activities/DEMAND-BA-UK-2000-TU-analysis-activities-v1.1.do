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
* 1.1 = seasonal
local v = "1.1"

capture log close

* save log file (with version)
log using "`rpath'/BA-UK-2000-TU-analysis-activities-v`v'.smcl", replace

* use this to switch on/off the summarising below
local do_collapse 1

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
gen ba_season = -99
replace ba_season =  1 if dmonth == 12 | dmonth == 1 | dmonth == 2
replace ba_season =  2 if dmonth == 3 | dmonth == 4 | dmonth == 5
replace ba_season =  3 if dmonth == 6 | dmonth == 7 | dmonth == 8
replace ba_season =  4 if dmonth == 9 | dmonth == 10 | dmonth == 11
lab def ba_season 1 "Winter" 2 "Spring" 3 "Summer" 4 "Autumn"
lab val ba_season ba_season

* keep only location & activity data to reduce dataset size
keep sn* dtype dday dmonth dyear dage dagegrp dsex ddayofwk gorpaf wtdry_gr wtdry_ug act1* act2* wher_* ba_*

* list all activity possibilities
lab li act1_001

* this gives us a massive list
/*
of interest here:

110 sleep (base category)

210 eating

3100 unspecified food management 
3110 food preparation
3120 baking
3130 dish washing
3320 ironing
3310 laundry

9950 filling in the time use diary

 */

local act110 "sleep"
local act210 "eating"
local act3100 "unsp_food_mgt"
local act3110 "food_prep"

local act3120 "baking"
local act3130 "dishwashing"
local act3310 "laundry"
local act3320 "ironing"


local act9950 "diary_completion"

local activities "110 210 3110 3120 3130 3310 3320"

* if and foreach loop to collapse the diary data to a table of proportions per location per day per time of day
* also generates graphs (could be seperated out)
* as a control mechanism, only do this if local do_collapse == 1
if `do_collapse' == 1 {
	
	* now loop over the activities of interest and create a count of how many times the given activity is reported
	* at a given time of day (i.e. time slot 1 to slot 144)
	
	
	foreach a of local activities {
		di "Processing activity `a': `act`a''"
		
		* quietly count number of times activity is reported at each time of day (t = 1-144) for this location (l)
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

				
		* loop over seasons
		
		foreach s of numlist 1/4 {
			* loop over days
			foreach d of numlist 1/7 {

				* preserve data here 
				* 1. so activity vars are not kept at each iteration (too many vars by the time = 32!)
				* 2. as we are going to collapse it to get means and we then need the data back for the next loop
				
				preserve
				
				* filter out season & day we want in this loop
				di "Keeping season `s' (`s`s'') and day `d' (`d`d'')"
				keep if ba_season == `s' & ddayofwk == `d'
		
				
				* uncomment these lines to get descriptives
				*di "* test ranges"
				*su wher_*s_loc`l'
				
				* collapse to calculate a mean for each time slot for a given location (l) for each day of week
				* this can then be transposed & used for line graphs
				* use non-grossing weight to correct for non response
		
				* XX must be a better way to do this with all locations in same table?
				
				collapse (mean) act_*s_act1`a' [iw= `wt'], by(ddayofwk ba_season)
				
				lab val ba_season ba_season
				lab val ddayofwk ddayofwk
				
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
				rename v1 act`a'
				lab var act`a' "% respondents reporting `act`a''"
				format act`a' %9.2f
				su act`a'
				
				* set up season & day variables
				gen ba_season = `s'
				lab var ba_season "Season"
				lab val ba_season ba_season
								
				gen ba_dayofweek = `d'
				lab var ba_dayofweek "Day of week"
				lab val ba_dayofweek ba_dayofweek
				
				save "`rpath'/data_temp/act_`a'_s`s'_d`d'_`vers'.dta", replace
				
				di "* -> restore so can loop to next location"
				restore
				
			}
		}
		
		preserve
		
		* start fresh
		clear
		* append the others
		foreach s of numlist 1/4 {
			foreach d of numlist 1/7 { 
				qui: append using "`rpath'/data_temp/act_`a'_s`s'_d`d'_`vers'.dta"
				*erase "`rpath'/data_temp/act_`a'_s`s'_d`d'_`vers'.dta"
			}
		}

				
		* create formated time variable 
		gen time_slot_dt = clock(time_slot_f, "hm")
		lab var time_slot_dt "Time of Day"
		* use the format to force the graph to display only hours of the day as
		* stata graph label options don't have a way to specifiy hours from an hours:minutes variable
		format time_slot_dt %tcHH
				lab val ba_dayofweek ba_dayofweek
		* draw contour chart by day & season
		* use zlabel to control display of legend etc
		twoway contour act`a' ba_dayofweek time_slot_dt, by(ba_season, clegend(on pos(9))) ///
			range(1/7) levels(11) zlabel(#9, format(%9.1f)) name(contour_act`a')
		
		* di "* saving graph to file"
		graph export "`rpath'/graphs/activity_by_season/contour_`a'_`act`a''_by_hour_`wt'_`vers'.png", replace
		
		save "`rpath'/data_temp/act`a'_season_`wt'.dta", replace
		
		di "* -> drop activity vars to save space"
		drop act`a'

		di "* restoring data so can loop to next location"
		restore
		
	}
}

* should now be able to merge them using time_slot
* start with 110 (sleep)
use "`rpath'/data_temp/act110_`wt'.dta", clear
foreach a of local activities {
	merge 1:1 time_slot_i ba_season ba_dayofweek using "`rpath'/data_temp/act`a'_season_`wt'.dta"
	drop _merge
	*erase "`rpath'/data_temp/location_`loc'_`wt'.dta"
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

* feed prep, eating, washing up on Sundays

save "`rpath'/ONS-TU-2000-activity-by-season-hour-dow-`wt'.dta", replace


log close


