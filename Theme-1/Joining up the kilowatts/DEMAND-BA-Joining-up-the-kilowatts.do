*******************************************
* Analysis for 'Joining up the kilowatts' paper

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
* location of time-use diary data
local dpath "`where'/Data/Social Science Datatsets/Time Use 2005/processed"

* use the ungrossed non-response weight
* this just corrects for survey/diary non-response - we don't need to gross up to the population
* as we're not interested in total minutes etc
local wt = "net_wgt"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"

* first analysis = basic 2005 time of day profiles
local rpath "`proot'/results/ONS TU 2005"

* version
local version = "v1.0"

capture log close

log using "`rpath'/DEMAND-BA-Joining-Up-The-Kilowatts-`version'.smcl", replace

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

* now merge in survey data, keeping a few variables we want 
merge m:1 serial using "`dpath'/timeusefinal_for_archive_survey_v1.0.dta", keepusing(gora respage respsex parent partod stat nsecac3 agex ecact)

* min age?
su age

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

local tvars "pact lact"
* create tables of % engaged in each activity or at given location by time of day
foreach v of local tvars {
	di "* Creating tables for `v'"
	qui: tabout s_faketime `v' using "`rpath'/ONS-TU-2005-tod-`v's-all.txt" [iw=`wt'], c(row) replace
	qui: tabout s_faketime `v' using "`rpath'/ONS-TU-2005-tod-`v's-mon-fri.txt" if s_dow > 0 & s_dow < 6 [iw=`wt'], c(row) replace
	qui: tabout s_faketime `v' using "`rpath'/ONS-TU-2005-tod-`v's-we.txt" if s_dow == 0 | s_dow == 6 [iw=`wt'], c(row) replace
	qui: tabout s_faketime `v' using "`rpath'/ONS-TU-2005-tod-`v's-sat.txt" if s_dow == 6 [iw=`wt'], c(row) replace
	qui: tabout s_faketime `v' using "`rpath'/ONS-TU-2005-tod-`v's-sun.txt" if s_dow == 0 [iw=`wt'], c(row) replace
}
di "* Done"

log close
