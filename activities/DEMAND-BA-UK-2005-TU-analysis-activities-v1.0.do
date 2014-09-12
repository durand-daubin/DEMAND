* Exploratory analysis for DEMAND
* Uses ONS Time Use 2000/1 survey to look at a moment in time

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
* 1a : no seasonal or regional analysis
* 1b : changed diary day
local v = "1b"

capture log close

* save log file (with version)
log using "`rpath'/BA-UK-2005-TU-analysis-activities-moments-v`v'.smcl", replace

* use this to switch on/off the summarising below
local do_collapse 1

* make script run without waiting for user input
set more off

* get diary data
use "`dpath'/timeusefinal_for_archive.dta", clear

* this is clearly wrong (see graph series 1a)
* gen ba_dow = diaryday

* according to the userguide code DiaryDay 1 might be Sunday!
recode diaryday (1=7) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6), gen(ba_dow)

lab def ba_dow  1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday" 7 "Sunday"
lab val ba_dow ba_dow
lab var ba_dow "Day of week (from diaryday)"

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

keep serial ba_dow month agex pact* net_wgt

save "`rpath'/timeusefinal_for_archive_wf.dta", replace

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

* we're interested in:

* personal care (washing etc) - pact4
* food prep - pact3
* in-home media use - pact15 ; computer games - pact20
* but also internet etc was mostly coded as a secondary activity with it's purpose (e.g. shopping) coded as primary so need to match up codes for given time-points
* requirements for ÔheatÕ in winter months (hours of active occupancy?) 
* ?

* include sleep, work & study as 'controls' - we know what shape they should be!
local acts "1 3 4 5 6 15 20"

foreach a of local acts {
	di "Processing primary activity `a': `pact`a't' (no account taken of location)"
	
	* reload data here 
	* 1. so activity vars are not kept at each iteration (too many vars by the time = 32!)
	* 2. as we are going to collapse it to get means and we then need the data back for the next loop
	
	use "`rpath'/timeusefinal_for_archive_wf.dta", clear
	
	* quietly count number of times activity is reported at each time of day (t = 1-144)
	foreach t of numlist 1/144 {
		* time slot 1-144
		* fix names for later collapse
		qui: egen pr_actn_`a'_s`t' = anycount(pact`t'), values(`a')
	}
	
	* uncomment these lines to get descriptives
	*di "* test ranges"
	*su wher_*s_loc`l'

	* local months "february june september november"
	local m1 "Feb"
	local m2 "June"
	local m3 "Sept"
	local m4 "Nov"
					
	* su pr_actn_`a'_s*
	* days of the week
	collapse (mean) pr_actn_`a'_s* (count) n_obs = serial ///
		[iw= `wt'], by(ba_dow month)
		
		tabstat n_obs, by(ba_dow) s(sum n min max)
		
		reshape long pr_actn_`a'_s, i(ba_dow month)
		rename _j t_slot
		gen pc_actn_`a'_s = 100 * pr_actn_`a'_s
		lab var pc_actn_`a'_s "% reporting"
		gen min = mod(t_slot,6)
		gen t_min = 0 if min == 0
		replace t_min = 10 if min == 1
		replace t_min = 20 if min == 2
		replace t_min = 30 if min == 3
		replace t_min = 40 if min == 4
		replace t_min = 50 if min == 5
		
		gen t_hour = ceil(t_slot/6)
		* diary starts at 04:00
		* NB this puts > 00:00 to the start of the day before!
		replace t_hour = t_hour + 3
		* fix the 'following hour' problem
		replace t_hour = t_hour + 1 if t_min == 0
		
		* fix dates
		* Feb: we are going to assume this was the first full week of feb where Monday was the 7th
		gen t_day = ba_dow + 6 if month == 1
		
		* June: we are going to assume this was the first full week of june where Monday was the 6th
		replace t_day = ba_dow + 5 if month == 2

		* Sept: we are going to assume this was the first full week of sept where Monday was the 5th
		replace t_day = ba_dow + 4 if month == 3

		* Nov: we are going to assume this was the first full week of nov where Monday was the 7th
		replace t_day = ba_dow + 6 if month == 4

		* fix the '> 24' problem
		* make it tomorrow
		replace t_day = t_day + 1 if t_hour >= 24
		* make it in the morning (tomorrow)
		replace t_hour = t_hour - 24 if t_hour >= 24
				
		gen t_month = 2 if month == 1
		replace t_month = 6 if month == 2
		replace t_month = 9 if month == 3
		replace t_month = 11 if month == 4
		
		gen t_year = 2005
		gen t_sec = 0
		gen double s_datetime=  mdyhms(t_month,t_day,t_year,t_hour, t_min, t_sec)
		format s_datetime %tc
		gen s_dow = dow(dofc(s_datetime))
		lab def s_dow 0 "Sunday" 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday"
		lab val s_dow s_dow
		tab s_dow ba_dow
		* NB: s_dow is the ACTUAL day, ba_dow is the day the diary started!
		lab var s_datetime "Time of day (end of slot)"
		
		egen t_time = concat(t_hour t_min), punct(":")
		lab var t_time "Time of day (half hours)"
		
		* create stata time - NB this sets date to 1/1/1960!
		gen double s_time = clock(t_time,"hm")
		format s_time %tcHH:MM
		lab var s_time "Time of day"

		
		*li *time *dow in 1/144
		* get max & min for graphs
		qui: su pc_actn_`a'_s
		local pc_max = r(max)
		local pc_min = r(min)
		local ticks = `pc_max'/6
					
		* loop over months
		foreach m of numlist 1/4 {
			preserve
				keep if month == `m'
				* set this to s_datetime to get a 'forced' weekly cycle :-)
				xtset ba_dow s_time, delta(10 minutes)
				xtline pc_actn_`a'_s, overlay name(pc_pact`a'_`m`m'') note("`m`m'' 2005: % reporting `pact`a't'") ///
					yscale(range(0 `pc_max')) ylabel(0(`ticks')`pc_max',format(%9.0fdd) angle(horizontal))
				graph export "`rpath'/graphs/pc_`a'_by_days_`m`m''_v`v'.png", replace
			restore
		}
		*graph combine pc_pact`a'_m1 pc_pact`a'_m2 pc_pact`a'_m3 pc_pact`a'_m4, ycommon name(pc_pact`a'_combined) title("`pact`a't' by age and month")
		*graph export "`rpath'/graphs/pc_`a'_weekdays_combined-v`v'.png", replace
		*xtline sd_actn_`a'_s, overlay name(sd_`a') note("Weekdays: SD of proportion reporting `pact`a't'")
}

log close


