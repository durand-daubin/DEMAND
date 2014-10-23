* iterate this and test why different results each time

* change these to run this script on different PC
local where "/Users/ben/Documents/Work"
local droot "`where'/Data/Social Science Datatsets/MTUS/World 6"
* location of time-use diary data
local dpath "`droot'/processed"
local dfile "MTUS-adult-episode-UK-only"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/MTUS"

capture log close

log using "`rpath'/iteration-test.smcl", replace

set more off

foreach i of numlist 1(1)10 {
	clear all
	di "Iteration `i'"
	* start with processing the aggregate (survey) data
	qui: use "`dpath'/MTUS-adult-aggregate-UK-only-wf.dta", clear
	qui: tab sex
	qui: return li
	di "Iteration `i': N diaries = " r(N)
	di "* Drop all bad cases"
	keep if badcase == 0
	
	* keep only the vars we want to keep memory required low
	qui: keep sex age main7 main21 hhtype empstat emp unemp student retired propwt survey day month year ///
		hhldsize famstat nchild *pid ba*
	
	* merge the episodes
	qui: merge 1:m diarypid using "`dpath'/MTUS-adult-episode-UK-only-wf.dta", ///
		gen(m_aggvars)
	* this won't have matched the dropped years	& badcases
	qui: tab day
	qui: return li
	local all_eps = r(N)
	
	* keep the matched cases
	qui: keep if m_aggvars == 3
	qui: tab m_aggvars
	qui: return li
	local matched_eps = r(N)
	local pc_matched = (100 * (`matched_eps'/`all_eps'))
	di "Iteration `i': Matched % = `pc_matched'"

	* define laundry
	qui: gen laundry_p = 0
	lab var laundry_p "Main act = laundry (21)"
	qui: replace laundry_p = 1 if main == 21
	
	gen laundry_s = 0
	lab var laundry_s "Secondary act = laundry (21)"
	replace laundry_s = 1 if sec == 21
	
	qui: gen laundry_all = 0
	replace laundry_all = 1 if laundry_p == 1 | laundry_s == 1

	* we can't use the lag notation and xtset as there are various time periods represented in the data
	* and we would need to set up some fake (or real!) dates to attach the start times to.
	* we could do this but we don't really need to.
	
	* we want to use episodes not time slots (as we are ignoring duration here)
	
	local acts "all"
	foreach a of local acts {
		* make sure we do this within diaries otherwise we might get a 'before' or 'after' belonging to someone else!
		
		****
		* This is the bit that causes the problem - it produces different results each time - why??
		qui: bysort diarypid: gen before_laundry_`a' = main[_n-1] if laundry_`a' == 1
		qui: bysort diarypid: gen after_laundry_`a' = main[_n+1] if laundry_`a' == 1
		****
		
		lab val before_laundry_`a' after_laundry_`a' MAIN
		 
		qui: tabout before_laundry_`a' survey [iw=propwt] using "`rpath'/before-laundry-by-survey.txt", replace
		qui: tabout after_laundry_`a' survey [iw=propwt] using "`rpath'/after-laundry-by-survey.txt", replace
	}
	tab laundry_all
	qui: tab before_laundry_all
	qui: return li
	di "Iteration `i' - for before_laundry_all = " r(N) "; r = " r(r)

	qui: tab after_laundry_all
	qui: return li
	di "Iteration `i' - for after_laundry_all = " r(N) "; r = " r(r)

	* create a sequence variable (horrible kludge but hey, it works :-)
	qui: egen laundry_seq = concat(before_laundry_all laundry_all after_laundry_all) if laundry_all == 1 , punct("_") 
	
	* get frequencies of sequencies (this will be a very big table)
	* the ones which have missing (.) before laundry indicate nothing recorded before hand which seems a bit odd?
	
	* why do I get different results every time I run this??
	qui: log on
	qui: tab laundry_seq
	qui: return li
	di "Iteration `i' - N for concatenated laundry_seq = " r(N) "; r = " r(r)
	

	* contract doesn't like iw - only allows fw (which need to be integers)
	* so these will be unweighted
	contract laundry_seq survey, nomiss
	qui: tab laundry_seq
	qui: return li
	*di "Iteration `i' - after contract N = " r(N) "; r = " r(r)

	* reshape it to get the frequencies per survey into columns
	qui: reshape wide _freq, i(laundry_seq) j(survey)
	qui: return li
	*di "Iteration `i' - after reshape width = " r(width) "; changed = " r(changed) "; k = " r(k) "; N = " r(N)
	* qui: log off
	
	*li in 1/5
	*outsheet using "`rpath'/laundry-sequences-by-survey-wide.txt", replace
/*
	* totals
	* the number of different sequences will probably vary by sample size - more potential variation
	su _freq*, sep(0)
	tabstat _freq*, s(n sum)
	* top in 1974?
	gsort - _freq1974
	li in 1/10, sep(0)
	* top in 2005?
	gsort - _freq2005
	li in 1/10, sep(0)
*/	
} 
