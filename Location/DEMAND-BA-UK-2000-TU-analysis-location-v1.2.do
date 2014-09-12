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
* 1.1
*	seasonal
*	set imputed locations to 'real' (so remove 201 & 401 location codes)
* 1.2
* calculates experimental SSI-L
local vers = "v1_2"

capture log close

* save log file (with version)
log using "`rpath'/BA-UK-2000-TU-analysis-location-v-`vers'.smcl", replace

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
replace ba_season =  1 if dmonth == 12 | dmonth == 1 | dmonth == 2 // Winter
replace ba_season =  2 if dmonth == 3 | dmonth == 4 | dmonth == 5 // Spring
replace ba_season =  3 if dmonth == 6 | dmonth == 7 | dmonth == 8 // Summer
replace ba_season =  4 if dmonth == 9 | dmonth == 10 | dmonth == 11 // Autumn
lab define ba_season 1 "Winter" 2 "Spring" 3 "Summer" 4 "Autumn"
lab val ba_season ba_season

* check n for season by region
tab gorpaf ba_season

local s1 "Winter"
local s2 "Spring"
local s3 "Summer"
local s4 "Autumn"

* days
lab def ba_dayofweek 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday" 7 "Sunday"
local d1 "Monday"
local d2 "Tuesday"
local d3 "Wednesday"
local d4 "Thursday"
local d5 "Friday"
local d6 "Saturday"
local d7 "Sunday"

* define geo-spatial 'regions' and keep London distinct
gen ba_geo = -99
replace ba_geo = 1 if gorpaf == 7 // London
replace ba_geo = 2 if gorpaf == 8 | gorpaf == 9 // South East & South West
replace ba_geo = 3 if gorpaf == 10 | gorpaf == 6 | gorpaf == 5 | gorpaf == 4 // Wales, East , E & W Midlands
replace ba_geo = 4 if gorpaf == 1 | gorpaf == 2  | gorpaf == 3 // Northern England
replace ba_geo = 5 if gorpaf == 11 | gorpaf == 12 // Scotland & NI
lab def ba_geo 1 "London" 2 "South East & South West" 3 "Wales, East , E & W Midlands" 4 "Northern England" 5 "Scotland & NI"
lab val ba_geo ba_geo
* missed any?
tab gorpaf ba_geo, mi

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
local loc2  "home"
* this is the imputed sleep when location not specified (see user guide and -9 code above)
* local loc201 "home - imputed (sleep)"
local loc3  "second home or weekend house"
local loc4  "working place or school"
* this is the imputed work place or school when location not specified (see user guide and -9 code above)
* local loc401 "working place or school - imputed (working or in class)"
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
	
	* set locations to actual
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
	
	* quietly get rid of the leading 0s
    foreach t of numlist 1/9 {
	    * time slot 1-9
        qui: rename wher_00`t' whern_`t' 
    }
    foreach t of numlist 10/99 {
        * time slot 10-99
        qui: rename wher_0`t' whern_`t' 
    }
    foreach t of numlist 100/144 {
        * time slot 100-144
        qui: rename wher_`t' whern_`t'
    }

	keep sn1 sn2 sn3 ddayofwk whern_* wtdry_ug ba_*
	order sn1 sn2 sn3 ddayofwk wtdry_ug whern_*

	* now loop over all possible location codes and create a count of how many times the given location is reported
	* at a given time of day (i.e. time slot 1 to slot 144)
	
	* ignore 0
	* 0(1)32 
	
	foreach l of numlist 0(1)32 {
		di "Processing location `l': `loc`l''"
					
		* quietly count number of times location is reported at each time of day (t = 1-144) for this location (l)
		foreach t of numlist 1/144 {
			* time slot 1-144
			qui: egen whern_`t's_loc`l' = anycount(whern_`t'), values(`l')
		}
		
		* uncomment these lines to get descriptives
		*di "* test ranges"
		*su wher_*s_loc`l'
		

		* XX must be a better way to do this with all locations in same table?
		
		* loop over seasons
		
		foreach s of numlist 1/4 {
			* loop over days
			foreach d of numlist 1/7 {
							
				* preserve data here 
				* 1. so location vars are not kept at each iteration (too many vars by the time = 32!)
				* 2. as we are going to collapse it to get means and we then need the data back for the next loop
				preserve
				
				* filter out season & day we want in this loop
				di "Keeping season `s' (`s`s'') and day `d' (`d`d'')"
				keep if ba_season == `s' & ddayofwk == `d'
				
				* collapse to calculate a mean for each time slot for a given location (l) for each day of week
				* this can then be transposed & used for graphs
				* use non-grossing weight to correct for non response

				
				
				collapse (mean) whern_*s_loc`l' [iw= `wt']
			
				* the mean will be the proportion reporting this location (l) at this time of day in this season for this day of the week
				* change to %
				
				foreach v of varlist whern_*s_loc`l' {
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
				
				* attempt to make better labels for chart by calculating hour of day
				* really should turn this into a meaningful time format and then use a time series (ts) line chart
				* real number
				gen time_slot_i = 0
				* time format
				gen time_slot_f = "0:00"
				* each slot is 10 mins (here)
				foreach ts of numlist 1/144 {
					* di "* Changing slot `ts' for location `l': `loc`l''"
					* remember to add 4 as 0 = 04:00
					* create real number format
					qui: replace time_slot_i = ((`ts'*10)/60)+4 if _varname == "whern_`ts's_loc`l'"
					
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
					* di "timeslot `ts' = `hour':`mins'"
					qui: replace time_slot_f = "`hour':`mins'" if _varname == "whern_`ts's_loc`l'"
				}
				*tab time_slot_f
				
				* rename & label the variables to be meaningful
				rename v1 loc`l'
				lab var loc`l' "% respondents reporting `loc`l''"
				format loc`l' %9.2f
				su loc`l'
				
				* set up season & day variables
				gen ba_season = `s'
				lab var ba_season "Season"
				lab val ba_season ba_season
								
				gen ba_dayofweek = `d'
				lab var ba_dayofweek "Day of week"
				lab val ba_dayofweek ba_dayofweek
				
				*di "* Summary for location `l': `loc`l''"
				*su *_loc`l'
				save "`rpath'/data_temp/location_`l'_s`s'_d`d'_`vers'.dta", replace
				
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
				qui: append using "`rpath'/data_temp/location_`l'_s`s'_d`d'_`vers'.dta"
				erase "`rpath'/data_temp/location_`l'_s`s'_d`d'_`vers'.dta"
			}
		}
		
		* check descriptives if you wish
		*tabstat *_loc`l', by(time_slot_i)
		
		* create formated time variable 
		gen time_slot_dt = clock(time_slot_f, "hm")
		lab var time_slot_dt "Time of Day"
		* use the format to force the graph to display only hours of the day as
		* stata graph label options don't have a way to specifiy hours from an hours:minuutes variable
		format time_slot_dt %tcHH

		lab val ba_dayofweek ba_dayofweek
		* draw contour chart by day & season
		* use zlabel to control display of legend etc
		twoway contour loc`l' ba_dayofweek time_slot_dt, by(ba_season, clegend(on pos(9))) range(1/7) levels(11) zlabel(#9, format(%9.1f)) name(contour_loc`l')
		
		* di "* saving graph to file"
		graph export "`rpath'/graphs/location_by_season/contour_`l'_`loc`l''_by_hour_`wt'_`vers'.png", replace
		
		save "`rpath'/data_temp/location_`l'_`wt'.dta", replace
		
		di "* restoring data so can loop to next location"
		restore
		
		di "* -> drop location vars to save space"
		drop whern_*loc`l'
	}
}

* should now be able to merge them using time_slot
* start with 201
use "`rpath'/data_temp/location_0_`wt'.dta", clear
foreach loc of numlist 0(1)32 {
	merge 1:1 time_slot_i ba_season ba_dayofweek using "`rpath'/data_temp/location_`loc'_`wt'.dta"
	drop _merge
	*erase "`rpath'/data_temp/location_`loc'_`wt'.dta"
}

save "`rpath'/ONS-TU-2000-location-by-season-hour-dow-`wt'.dta", replace

log close


