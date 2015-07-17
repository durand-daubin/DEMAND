* Exploratory analysis for DEMAND Research Centre Theme 1

* Uses ONS Time Use 2005 survey

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

clear all

* change these to run this script on different PC
local where "~/Documents/Work"
local projroot "`where'/Projects/RCUK-DEMAND"
local rpath "`projroot'/Theme 1/results/ONS TU 2005"

* location of time-use diary data
local dpath "`where'/Data/Social Science Datatsets/Time Use 2005/processed"

* use the ungrossed non-response weight
* this just corrects for survey/diary non-response - we don;t need to gorss up to the population
* as we're not interested in total minutes etc
local wt = "net_wgt"

* version
* 1.0 = no regional analysis

* 2.0 use long format data as a time series
* 2leg keep legends
* 2noleg drop legends 
* added non-overlays
local version = "2leg"

* control flow
local do_overlays = 1
local do_ind_lines = 1

capture log close

* save log file (with version)
log using "`rpath'/BA-UK-2005-TU-analysis-activities-v`version'.smcl", replace

* make script run without waiting for user input
set more off

* get diary data in long form - i.e. already coverted from original so that
*  id = panel variable and time of day converted to 'real time'
*  most survey variables kept out to keep file size small (will merge in later)
use "`dpath'/timeusefinal_for_archive_diary_long_v1.0.dta", clear

* labels
lab def t_month 2 "February" 6 "June" 9 "September" 11 "November"
lab val t_month t_month

* check unweighted & weighted n per weekday
* NB - remember this includes all respondents and that respondents (should have) completed
* 1 diary for a weekday and 1 diary for a weekend day

* unweighted
tab s_dow, mi
* so c 2,000 diaries on each weekday but nearly 5,000 on each weekend day (why?)

* weighted
tab s_dow [iw= `wt'], mi

* so c 2,900 (weighted) diaries per day

* How many respondents per day/month?
tab s_dow t_month, mi

gen weekday_flag = 0
replace weekday_flag = 1 if s_dow > 0 & s_dow < 6

* Set some locals to contain the variable labels - helps a lot later on
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

* ignore 0
* 0(1)32 

* we're interested in:
* (at home for now)
* lact = -1 (missing)
* lact = 1 : home
* lact = 2 : elsewhere

* put labels into a local so can re-use after collapse
* sleep
gen any_sleep = 0
replace any_sleep = 1 if pact == 1 | pact == 2 | sact == 2
local any_sleepl "Sleep or resting (incl as secondary)"
lab var any_sleep "`any_sleepl'"

* work
gen any_work = 0
replace any_work = 1 if pact == 5 | sact == 5
local any_workl "Paid work (incl as secondary)"
lab var any_work "`any_sleepl'"

* study
gen any_study = 0
replace any_study = 1 if pact == 6 | sact == 6
local any_studyl "Study (incl as secondary)"
lab var any_study "`any_studyl'"


* personal care (washing etc) - pact4
gen any_pcare = 0
* not elsewhere
replace any_pcare = 1 if (pact == 4 | sact == 4) & lact != 2
local any_pcarel "Personal care (wash/dress incl as 2nd act) not 'elsewhere'"
lab var any_pcare "`any_pcarel'"
* food prep - pact3
gen any_fdprp = 0
* not elsewhere
replace any_fdprp = 1 if (pact == 3 | sact == 3) & lact != 2
local any_fdprpl "Eating & drinking (incl as 2nd act) not 'elsewhere'"
lab var any_fdprp "`any_fdprpl'"

* but also internet etc was mostly coded as a secondary activity with it's purpose (e.g. shopping) coded as primary so need to match up codes for given time-points
gen any_net = 0
* not elsewhere
replace any_net = 1 if (pact == 17 | pact == 18 | sact == 17 | sact == 18) & lact != 2
local any_netl "Any internet use (incl as 2nd act) not 'elsewhere'"
lab var any_net "`any_netl'"

gen any_netshp = 0
* not elsewhere
replace any_netshp = 1 if (pact == 17 | (pact == 7 & sact == 17) | sact == 17) & lact != 2
local any_netshpl "Any internet shopping (incl as 2nd act) not 'elsewhere'"
lab var any_netshp "`any_netshpl'"

gen any_comp = 0
* not elsewhere
replace any_comp = 1 if (pact == 17 | pact == 18 | pact == 19 | pact == 20 | pact == 22 | ///
	sact == 17 | sact == 18 | sact == 19 | sact == 20 | sact == 22) & lact != 2
local any_compl "Any computing at all (incl games & as 2nd act) not 'elsewhere'"
lab var any_comp "`any_compl'"

gen any_online_media = 0
replace any_online_media = 1 if (pact == 15 & sact == 18) & lact != 2

* in-home media use - pact15 ; computer games - pact20
gen any_media = 0
* not elsewhere
replace any_media = 1 if (pact == 15 | sact == 15 | any_comp == 1 ) & lact != 2
local any_medial "TV/video, radio & computing incl games & as 2nd act) not 'elsewhere'"
lab var any_media "`any_medial'"

* travel
gen any_travel = 0
replace any_travel = 1 if pact == 16 | sact == 16
local any_travell "Any travel"
lab var any_travel "`any_travell'"
* requirements for ÔheatÕ in winter months (hours of active occupancy?)
gen at_home = 0
replace at_home = 1 if lact == 1
local at_homel "Reported as 'at home'"
lab var at_home "`at_homel'"

* try inverse - i.e. any time not 'elsewhere'
gen at_homeimp = 0
replace at_homeimp = 1 if lact != 2
local at_homeimpl "Reported as not 'elsewhere' (incl. unkown)"
lab var at_homeimp "`at_homeimpl'"

* actively not 'elsewhere'
gen at_homeact = 0
* -> not elsewhere & not asleep
replace at_homeact = 1 if lact != 2 
replace at_homeact = 0 if pact == 1 | sact == 1

local at_homeact "Not 'elsewhere' & not asleep"
lab var at_homeact "`at_homeact'"

local missing_locl "Missing location"

* now merge in survey data, keeping a few variables we want
merge m:1 serial using "`dpath'/timeusefinal_for_archive_survey_v1.0.dta", keepusing(gora respsex parent partod stat nsecac3 agex ecact)

local goral "Region"
local respsexl "Gender"
local parentl "Parent of child < 16 in hhld"
label def parent 1 "Has child < 16" 2 "No child under 16", replace
label val parent parent
local partodl "Parent of child < 4 in hhld"
lab def partod  1 "Has child aged < 4" 2 "No child aged < 4", replace
lab val partod partod
local statl "Work status"
rename nsecac3 nssec3
local nssec3l "NSSEC-3"
local agexl "Age group"
local ecactl "Economic activity"

* drop the 1 refusal on working status etc
drop if stat == 8
drop if ecact == 0

local weekdays "0 1"
local wt0 "Weekends"
local wt1 "Weekdays"

* set up the axis scales etc for the combined graph below
local tscale1 "tscale(alt)"
local ttitle1 "ttitle("")"
local tlabel0 "tlabel(#12, angle(vertical))"
local tlabel1 "tlabel(#12, angle(vertical))" 

if "`version'" == "2leg" {
	local legend1 = "legend(pos(3) col(1) orient(vertical))"
	local legend0 = "legend(pos(3) col(1) orient(vertical))"
}
else if "`version'" == "2noleg" {
	local legend1 "legend(off)"
	local legend0 "legend(off)"
}
else if "`version'" == "2bnoleg" {
	local legend1 "legend(off)"
	local legend0 "legend(off)"
}

* partod nssec3 stat ecact
local cutvars "agex parent ecact"
local tvars "any_sleep any_work any_study any_pcare any_fdprp any_comp any_media any_travel at_homeact"

* this code will construct the 'combined' xtline charts as overlays 
* - this means it can be quie difficult to see the different shapes of the
* 'cutvars'

if `do_overlays' {
	foreach v of local tvars {
		di "* Graphing `v'"
		foreach cv of local cutvars {
			di "* Graphing `v' by `cv'" 
			foreach w of local weekdays {
				preserve
					di "* Graphing `v' by `cv' on `wt`w''"
					* switch between weekdays and weekends
					keep if weekday_flag == `w'
					* collapse by the cutvar of interest and faketime which is the half hour of the day as a stata time
					collapse (mean) `v' [iw= `wt'], by(s_faketime `cv')
						gen pc_`v' = 100*`v'
						lab var pc_`v' "`v'l'"
						qui: su pc_`v'
						local y_max = `r(max)'
						di "* -> y_max for pc_`v' = `y_max'"
						local yscale0 "yscale(range(0 `y_max') reverse)"
						local yscale1 "yscale(range(0 `y_max'))"
						* set xtset to use cutvar as the id - tricks stata into thinking it can run xtline
						xtset `cv' s_faketime, delta(10 minutes)
						* make the single xt line chart for the weekday or weekend
						xtline pc_`v', overlay name(xtl_`v'_`w'_`cv') ytitle("% reporting") ///
							subtitle("`wt`w''", pos(9) orient(vertical)) scale(0.75) ///
							`legend`w'' `yscale`w'' `tscale`w'' `tlabel`w''
						*graph export "`rpath'/graphs/pc_`v'_by_`cv'_`wt`w''_v`version'.png", replace
				restore
			}
			di "* Combining graphs for `v' by `cv' "
			capture {
				* make the combined graph with weekday on top
				graph combine xtl_`v'_1_`cv' xtl_`v'_0_`cv', ycommon cols(1) name(xtl_`v'_`cv'_comb) ///
					imargin(1 1 0 0) subtitle("``v'l'", pos(9) orient(vertical)) 
				graph export "`rpath'/graphs/pc_`v'_by_`cv'_combined_overlay_v`version'.png", replace
			}
			* just keep combined graphs in memory
			graph drop xtl_`v'_1_`cv' xtl_`v'_0_`cv'
		}
	}
}

* this code constructs the same graphs but does so by combining tslines to make seperate shapes for each category of cutvar
* requires 2 levels of combining:
* wd + we for each category
* then combine all categories
* takes ages!!!

local xscale1 "tscale(alt)"
local xtitle1 "ttitle("")"
local xlabel0 "tlabel(#12, angle(vertical))"
local xlabel1 "tlabel(#12, angle(vertical))" 

* only do ones of interest:
local cutvars "agex ecact"
local tvars "any_sleep any_pcare any_fdprp any_comp any_media any_travel at_homeact"

if `do_ind_lines' {
	foreach cv of local cutvars {
		foreach v of local tvars {
			preserve
				di "* Graphing `v' by `cv' (`wt`w'')"
				* keep if weekday_flag == `w'
				di "* collapse by the cutvar of interest: `cv'"
				collapse (mean) `v' [iw= `wt'], by(s_faketime `cv' weekday_flag)
					gen pc_`v' = 100*`v'
					lab var pc_`v' "`v'l'"
					* need to work out how to get nice labels back
					
					* set max y so all graphs for each time use have the same height
					* looks weird when each graph is being drawn but looks OK when combined!
					qui: su pc_`v'
					local y_max = `r(max)'
					di "* -> y_max for pc_`v' = `y_max'"
					local yscale0 "yscale(range(0 `y_max') reverse)"
					local yscale1 "yscale(range(0 `y_max'))"
 
					levelsof `cv', local(levels)
					local graphs ""
					foreach l of local levels {
						line pc_`v' s_faketime if weekday_flag == 1 & `cv' == `l', name(l`v'wd`cv'`l') ytitle("% reporting") ///
							subtitle("`wt1'", pos(9) orient(vertical)) scale(0.75) ///
							`legend1' `yscale1' `xscale1' `xlabel1'
						
						line pc_`v' s_faketime if weekday_flag == 0 & `cv' == `l', name(l`v'we`cv'`l') ytitle("% reporting") ///
							subtitle("`wt0'", pos(9) orient(vertical)) scale(0.75) ///
							`legend0' `yscale0' `xscale0' `xlabel0'
						* combine weekend & weekday charts for level of cutvar
						graph combine l`v'wd`cv'`l' l`v'we`cv'`l', ycommon cols(1) name(l`v'`cv'com`l') imargin(1 1 0 0) subtitle("`cv' - `l'", pos(9) orient(vertical))
						* use the local 'graphs' to incrementally collect the names of the graphs to combine
						local graphs "`graphs' l`v'`cv'com`l'"
						* drop the single levels graphs
						graph drop l`v'wd`cv'`l' l`v'we`cv'`l'
					}
					* combine all the levels
					capture {
						graph combine `graphs', ycommon name(l_`v'_`cv'_comb) colfirst subtitle("``v'l'", pos(9) orient(vertical)) 
						graph export "`rpath'/graphs/pc_`v'_by_`cv'_combined_sep_v`version'.png", replace
					}
					* just keep combined graphs in memory
					graph drop `graphs'
			restore
		}
	}
}

log close


