* Exploratory analysis for DEMAND
* Uses ONS Time Use 2000/1 survey to look at a moment in time

* This work was funded by RCUK through the End User Energy Demand Centres Programme via the
* "DEMAND: Dynamics of Energy, Mobility and Demand" Centre (www.demand.ac.uk, gow.epsrc.ac.uk/NGBOViewGrant.aspx?GrantRef=EP/K011723/1)

/*   

Copyright (C) 2014  University of Southampton

Author: Ben Anderson (b.anderson@soton.ac.uk, @dataknut, https://github.com/dataknut) 
	[Energy & Climate Change, Faculty of Engineering & Environment, University of Southampton]

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License 
(http://choosealicense.com/licenses/gpl-2.0/), or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

#YMMV - http://en.wiktionary.org/wiki/YMMV

*/

* Saturday morning at 11:00

clear all

* change these to run this script on different PC
local where "/Users/ben/Documents/Work"
local projroot "`where'/Projects/RCUK-DEMAND"
local rpath "`projroot'/Theme 1/results/ONS TU 2005"

* location of time-use diary data
local dpath "`where'/Data/Social Science Datatsets/Time Use 2005/UKDA-5592-stata8/stata8/"

* use the ungrossed non-response weight
* this just corrects for survey/diary non-response - we don;t need to gorss up to the population
* as we're not interested in total minutes etc
local wt = "net_wgt"

* version
* 1.0 = no seasonal or regional analysis
local v = "1.0"

capture log close

* save log file (with version)
log using "`rpath'/BA-UK-2005-TU-analysis-activities-moments-v`v'.smcl", replace

* use this to switch on/off the summarising below
local do_collapse 1

* make script run without waiting for user input
set more off

* get diary data
use "`dpath'/timeusefinal_for_archive.dta", clear

* assume this is right
gen ba_dow = diaryday
lab def ba_dow  1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday" 7 "Sunday"
lab val ba_dow ba_dow
lab var ba_dow "Day of week (from date)"

* check unweighted & weighted n per weekday
* NB - remember this includes all respondents and that respondents (should have) completed
* 1 diary for a weekday and 1 diary for a weekend day

* unweighted
tab ba_dow, mi
* so c 2,000 diaries on each weekday but nearly 5,000 on each weekend day (why?)

* weighted
tab ba_dow [iw= `wt'], mi

* so c 2,900 (weighted) diaries per day


* How many respondents per day/month?
tab ba_dow month, mi

gen weekday_flag = 0
replace weekday_flag = 1 if ba_dow < 6

* Saturday @ 11:00 = slot 43
* collapse to each Saturday
* contract ba_ddate_stata act1_043, percent(_pc)

preserve
	* keep Saturday morning at 11:00 
	keep if ba_dow == 6
	keep ba_* month diaryday *t43

	* collapse to all saturdays per month
	contract month pact43, freq(pact)
	
	drop if pact43 == -1
	reshape wide pact, i(month) j(pact43)
	
	*tsset ba_ddate_stata
	
	*keep if tin(01jul2000, 01jul2001)
	
	lab var pact1 "sleep"                           
	lab var pact2 "resting"                      
	lab var pact3 "eating & drinking"               
	lab var pact4 "personal care ie wash/dress"     
	lab var pact5 "employment"                      
	lab var pact6 "study"                           
	lab var pact7 "housework excl childcare"        
	lab var pact8 "childcare (of household members)"
	lab var pact9 "voluntary work & meetings"       
	lab var pact10 "social life (but not resting)"   
	lab var pact11 "entertainment & culture"         
	lab var pact12 "sport & outdoor activities"      
	lab var pact13 "hobbies & games"                 
	lab var pact14 "reading"                
	lab var pact15 "tv & video, radio, music"        
	lab var pact16 "travel"                         
	lab var pact17 "internet shopping"               
	*lab var pact18 "other internet"                  
	lab var pact19 "other computing"                 
	lab var pact20 "computer games"                  
	lab var pact21 "other specified/ not specified"  
	*lab var pact22 "computing"           
	
	graph bar pact*, over(month) title("11:00 Saturday") ytitle("N") stack
	
	*export excel using "`rpath'/ONS-TU-2005-activity-saturdays.xls", firstrow(varlabels) replace

restore

*stop
local pact1t "sleep"                           
local pact2t "resting"                      
local pact3t "eating & drinking"               
local pact4t "personal care ie wash/dress"     
local pact5t "employment"                      
local pact6t "study"                           
local pact7t "housework excl childcare"        
local pact8t "childcare (of household members)"
local pact9t "voluntary work & meetings"       
local pact10t "social life (but not resting)"   
local pact11t "entertainment & culture"         
local pact12t "sport & outdoor activities"      
local pact13t "hobbies & games"                 
local pact14t "reading"                
local pact15t "tv & video, radio, music"        
local pact16t "travel"                         
local pact17t "internet shopping"               
local pact18t "other internet"                  
local pact19t "other computing"                 
local pact20t "computer games"                  
local pact21t "other specified/ not specified"  
local pact22t "computing"           

* now loop over all possible activity codes and create a count of how many times the given location is reported
* at a given time of day (i.e. time slot 1 to slot 144)

* ignore 0
* 0(1)32 

foreach a of numlist 1(1)22 {
	di "Processing activity `a': `pact`a't'"
	
	* preserve data here 
	* 1. so activity vars are not kept at each iteration (too many vars by the time = 32!)
	* 2. as we are going to collapse it to get means and we then need the data back for the next loop
	*preserve
	
		* quietly count number of times activity is reported at each time of day (t = 1-144)
		foreach t of numlist 1/144 {
			* time slot 1-144
			* fix names for later collapse
			qui: egen pr_actn_`a'_s`t' = anycount(pact`t'), values(`a')
			gen sd_actn_`a'_s`t' = pr_actn_`a'_s`t'
		}
		
		* uncomment these lines to get descriptives
		*di "* test ranges"
		*su wher_*s_loc`l'

		* local months "february june september november"
		local m1 "Feb"
		local m2 "June"
		local m3 "Sept"
		local m4 "Nov"
						
		*su pr_actn_`a'_s*
		
		collapse (mean) pr_actn_`a'_s* (sd) sd_actn_`a'_s* ///
			if weekday_flag == 1 & month == 1, by(agex)
			
			reshape long pr_actn_`a'_s sd_actn_`a'_s, i(agex)
			rename _j t_time
			
			gen min = mod(t_time,6)
			gen s_min = 0 if min == 0
			replace s_min = 10 if min == 1
			replace s_min = 20 if min == 2
			replace s_min = 30 if min == 3
			replace s_min = 40 if min == 4
			replace s_min = 50 if min == 5
			
			gen s_hour = ceil(t_time/6)
			gen s_month = 2
			gen s_day = 1
			gen s_year = 2005
			gen s_sec = 0
			gen double s_time=  mdyhms(s_month,s_day,s_year,s_hour, s_min, s_sec)
			format s_time %tcHH:MM
			lab var s_time "Time of day"
			
			xtset agex s_time
			
			xtline pr_actn_`a'_s, overlay name(pr_`a') note("Weekdays: Proportion reporting `pact`a't'")
			
			xtline sd_actn_`a'_s, overlay name(sd_`a') note("Weekdays: SD of proportion reporting `pact`a't'")
	
	restore
}

log close


