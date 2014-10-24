* Use MTUS World 6 time-use data (UK subset) to examine:
* - distributions of laundry in 1975 & 2005
* - changing laundry practices

* data already in long format (but episodes)

* b.anderson@soton.ac.uk
* (c) University of Southampton

* This work was funded by RCUK through the End User Energy Demand Centres Programme via the
* "DEMAND: Dynamics of Energy, Mobility and Demand" Centre (www.demand.ac.uk, gow.epsrc.ac.uk/NGBOViewGrant.aspx?GrantRef=EP/K011723/1)


* Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) license applies
* http://creativecommons.org/licenses/by-nc/4.0/

clear all

* change these to run this script on different PC
local where "/Users/ben/Documents/Work"
local droot "`where'/Data/Social Science Datatsets/MTUS/World 6"
* location of time-use diary data
local dpath "`droot'/processed"
local dfile "MTUS-adult-episode-UK-only"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/MTUS"

* version
local version = "v1.2-all-hhs"
local filter "_all"
* weights the final counts

*local version "v1.1-singles"
*local filter "if hhtype == 1"
* single person hhs only

*local version "v1.1-all-hhs-sanity-check"
*local filter "_all"
* counts if 1 or more acts (sanity check)

*local version = "v1.1-all-hhs"
* local filter "_all"
* adds in secondary acts
 
* local version = "v1.0-main"
* counts main acts only

capture log close

log using "`rpath'/DEMAND-BA-MTUS-W6-Laundry-Change-Over-Time-`version'-adult.smcl", replace

local do_halfhour_episodes = 0
local do_halfhour_samples = 0
local do_sequences = 1

* make script run without waiting for user input
set more off

**********************************
* codes of interest
* 1974:	Main/Sec21 Laundry, ironing, clothing repair <- 50 Other essential domestic work (i.e. NOT preparing meals or routine housework)
* 	so laundry in 1974 may be over-estimated
* BUT 1975 is partly a 7 day diary - so more likely to detect laundry?

* 2005:	Main/Sec21 Laundry, ironing, clothing repair <- Pact=7 (washing clothes)

* start with processing the aggregate (survey) data
use "`dpath'/MTUS-adult-aggregate-UK-only-wf.dta", clear

* drop all bad cases
keep if badcase == 0

* set as survey data for descriptives
svyset [iw=propwt]

* keep only 1974 & 2005 for simplicity
* keep if survey == 1974 | survey == 2005
* no, let's keep them all for birth cohort analysis!

* this is minutes per day not episodes
* check 18 (Cooking) & 20 (Cleaning) & 22 (maintain home/vehicle) against laundry
* seems to under-report laundry in 1974, esp for women?
svy: mean main18 main20 main21 main22, over(survey sex)

* keep whatever sample we define above
keep `filter'

* number of diary days by hh type
* svy: tab hhtype survey, col count

* number of diary days by number of days covered
* 1974 = 7 day dairy
svy: tab id survey, col count

* hh size recode & test
recode hhldsize (1=1) (2=2) (3=3) (4=4) (5/max=5), gen(ba_hhsize)
lab var ba_hhsize "Recoded household size"
lab def ba_hhsize 1 "1" 2 "2" 3 "3" 4 "4" 5 "5+"
lab var ba_hhsize ba_hhsize
* svy: tab ba_hhsize survey, col count

* main7 & main8 = paid work
gen ba_4hrspaidwork = 0
* mark those who worked more than 4 hours that day
replace ba_4hrspaidwork = 1 if main7 > 240

* set up n child & n people variables
recode nchild (0=0) (1=1) (2=2) (3/max=3), gen(ba_nchild)
lab var ba_nchild "Recoded nchild"
lab def ba_nchild 0 "0" 1 "1" 2 "2" 3 "3+"
lab val ba_nchild ba_nchild
recode hhldsize (0=0) (1=1) (2=2) (3=3) (4=4) (5/max=5), gen(ba_npeople)
lab def ba_npeople 0 "0" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5+"
lab val ba_npeople ba_npeople

* age categories
egen ba_age_r = cut(age), at(16,24,34,44,54,64,74,84)
lab var ba_age_r "Recoded age -> decades"
tab ba_age_r

* age cohorts
gen ba_birthyear = year - age
egen ba_birth_cohort = cut(ba_birthyear), at(1890,1900,1910,1920,1930,1940,1950,1960,1970,1980)
tab ba_birth_cohort survey
* NB - max age = 80 so older cohorts missing from 2005

* weekday variable
gen ba_weekday = 0
replace ba_weekday = 1 if day > 1 & day < 7



* keep only the vars we want to keep memory required low
keep sex age main7 main21 hhtype empstat emp unemp student retired propwt survey day month year ///
	hhldsize famstat nchild *pid ba*

* number of diary-days
svy: tab survey, obs

preserve

if `do_halfhour_episodes' {
	*************************
	* merge in the episode data
	* egen diarypid = group(countrya survey swave msamp hldid persid day)
	* egen pid = group(countrya survey swave msamp hldid persid)
	merge 1:m diarypid using "`dpath'/MTUS-adult-episode-UK-only-wf.dta", ///
		gen(m_aggvars)
	
	* won't match the dropped years	& badcases
	tab m_aggvars survey
	
	* keep the matched cases
	keep if m_aggvars == 3
	
	* number of episodes per day
	svy: tab day survey, obs col
	
	* overall durations
	gen duration = s_endtime - s_starttime
	format duration %tcHH:MM
	tab duration survey [iw=propwt]

	***************
	* Laundry
	
	* define laundry
	gen laundry_p = 0
	lab var laundry_p "Main act = laundry (21)"
	replace laundry_p = 1 if main == 21
	
	gen laundry_s = 0
	lab var laundry_s "Secondary act = laundry (21)"
	replace laundry_s = 1 if sec == 21
	
	gen laundry_all = 0
	replace laundry_all = 1 if laundry_p == 1 | laundry_s == 1
	
	* check % episodes which are laundry
	* NB reporting frame shorter in 2005 (10 mins) so may be higher frequency (e.g. interruption in 10-20 mins coded)
	* row %
	tab survey laundry_p [iw=propwt]
	tab survey laundry_s [iw=propwt]
	* all
	tab survey laundry_all [iw=propwt]
	
	* check duration of laundry
	* before we do this mere together episodes that are contiguous (e.g. laundry (s) then laundry(p) -> 1 episode)
	* same approach as for dinner
	* calculate duration
	gen laundry_duration = duration if laundry_all == 1
	format laundry_duration %tcHH:MM
	* count back & forward maxcount episodes within the same diary day to check if they are also laundry 
	* indicates something changed - primary/secondary act or location or who with etc
	* add on duration if previous and subsequent episodes are also laundry and location is unchanged
	* NB: if you make maxcount > 1 then you could have episodes of eating separated by a long episode of something else
	local maxcount = 1
	
	* This is vital - we have to have the episodes in diary & time order!
	sort diarypid start

	foreach n of numlist 1/`maxcount' {
		local prev = `n' - 1
		di "* Now = `n', previous = `prev'"
		di "* Before"
		su laundry_duration
		bysort survey diarypid: replace laundry_duration = laundry_duration + duration[_n-`n'] if laundry_all == 1 & ///
			laundry_all[_n-`n'] == 1 & eloc == eloc[_n-`n']
		bysort survey diarypid: replace laundry_duration = laundry_duration + duration[_n+`n'] if laundry_all == 1 & ///
			laundry_all[_n+`n'] == 1 & eloc == eloc[_n+`n']
		di "* After"
		su laundry_duration
	}
	
	
	* Means are probably not going to tell us much given the differences in recording frames
	* Use table instead as durations are so 'rounded'
	* even so have to allow for differences in recording frames
	table laundry_duration sex survey [iw=propwt]
	
	* age cohort differences in incidence of laundry
	table ba_birth_cohort laundry_all survey [iw=propwt]
	
	
	* leave this empty to skip the (time consuming) aggregations & table outputs
	local vars "21"
	local l5 "meals_work"
	local l6 "meals_oth"
	local l18 "food_prep"
	local l21 "laundry"
	local l59 "tv_video"
	local l60 "computer_games"
	local l61 "computer_internet"
	
	*************************
	* Aggregation to half hours
	* logic: the time use diaries rarely have the same duration of recorded time slot, 1974 = 30 mins, 2005 = 10 mins for example
	* To make comparison easier we need to use the lowest common multiple - in this case 30 minutes
	* We have already set up a variable (s_halfhour) which is the stata episode start-time converted into a stata half hour
	* i.e. if s_starttime = 21:24 s_halfhour =  21:00, if s_starttime = 21:44 s_halfhour =  21:30 etc
	
	* Note that where the diary has episodes shorter than 30 minutes we may get more than 1 episode of laundry 
	* reported per half hour
	* Check
	duplicates tag s_halfhour diarypid laundry_all, gen(laundry_dup_flag)
	table laundry_dup_flag laundry_all survey
	
	* We'd expect them all to occur in 2005 but they don't suggesting the 1974 -> MTUS conversion process has creates
	* some episodes shorter than 30 minutes
	* In any case we do need to watch out for situations where we sum the number of episodes per halfhour as 
	* we may have more episodes in 2005 due to the smaller recording time frame.
	
	* Note that where the diary has episodes shorter than 30 minutes we may get more than 1 episode reported per half hour
	* We will also miss longer episodes that started this half-hour and are continuing in the next half hour
	
	* This will record all episodes that started within the half hour but it won't catch episodes that started before and
	* are long-lasting. So it is good for looking at the distribution of episodes that are short, like laundry (mostly)
	* It does NOT work for longer-lasting episodes like sleep or paid work
	di "* Tables for all days"
	* All years, all days
	table s_halfhour survey laundry_all [iw=propwt]
	
	* Separate days
	table survey day [iw=propwt], by(laundry_all)
	
	* days by half hour
	table s_halfhour survey day [iw=propwt], by(laundry_all)	
}

restore

preserve
*************************
* sampled data for comparison
if `do_halfhour_samples' {
	* merge in the sampled data
	merge 1:m diarypid using "`dpath'/MTUS-adult-episode-UK-only-wf-10min-samples-long.dta", ///
		gen(m_aggvars)
	
	* define laundry
	gen laundry_p = 0
	lab var laundry_p "Main act = laundry (21)"
	replace laundry_p = 1 if main == 21
	
	gen laundry_s = 0
	lab var laundry_s "Secondary act = laundry (21)"
	replace laundry_s = 1 if sec == 21
	
	gen laundry_all = 0
	replace laundry_all = 1 if laundry_p == 1 | laundry_s == 1
	
	* check % samples which are laundry
	* NB reporting frame longer in 1974 (30 mins) so may be higher frequency (e.g. interruption in 10-20 mins coded)
	di "* main"
	tab survey laundry_p [iw=propwt]
	di "* secondary"
	tab survey laundry_s [iw=propwt]
	di "* all"
	tab survey laundry_all [iw=propwt]
	
	* collapse to add up the sampled laundry by half hour
	* use the byvars we're interested in (or could re-merge with aggregated file)
	collapse (sum) laundry_* (mean) propwt, by(diarypid survey day month year s_halfhour ba_birth_cohort ba_age_r sex)
	* because the different surveys have different reporting periods we need to just count at least 1 laundry in the half hour
	local acts "p s all"
	foreach a of local acts {
		gen any_laundry_`a' = 0
		replace any_laundry_`a' = 1 if laundry_`a' > 0
	}
	* by year
	tab survey any_laundry_all [iw=propwt]
	
	* Separate days
	table survey day [iw=propwt], by(any_laundry_all)

	table survey day sex [iw=propwt], by(any_laundry_all)
	
	di "* Tables for all days"
	* All years, all days
	table s_halfhour survey any_laundry_all [iw=propwt]
	
	* days by half hour
	table s_halfhour survey day [iw=propwt], by(any_laundry_all)	

	* seasons
	recode month (3 4 5 = 1 "Spring") (6 7 8 = 2 "Summer") (9 10 11 = 3 "Autumn") (12 1 2 = 4 "Winter"), gen(season)
	* check
	* tab month season
	table s_halfhour survey season [iw=propwt], by(any_laundry_all)
} 
restore
*************************
* sequences
if `do_sequences' {
	* back to the episodes
	merge 1:m diarypid using "`dpath'/MTUS-adult-episode-UK-only-wf.dta", ///
		gen(m_aggvars)
	* this won't have matched the dropped years	& badcases
	* tab m_aggvars survey
	
	* keep the matched cases
	keep if m_aggvars == 3
	
	* define laundry
	gen laundry_p = 0
	lab var laundry_p "Main act = laundry (21)"
	replace laundry_p = 1 if main == 21
	
	gen laundry_s = 0
	lab var laundry_s "Secondary act = laundry (21)"
	replace laundry_s = 1 if sec == 21
	
	gen laundry_all = 0
	replace laundry_all = 1 if laundry_p == 1 | laundry_s == 1

	* we can't use the lag notation and xtset as there are various time periods represented in the data
	* and we would need to set up some fake (or real!) dates to attach the start times to.
	* we could do this but we don't really need to.
	
	* we want to use episodes not time slots (as we are ignoring duration here)

	* This is vital - we have to have the episodes in diary & time order!
	sort diarypid start
	
	* we are NOT going to worry about sequential episodes which are both laundry_all as this will indicate
	* that something changed - most likely a switch of laundry from primary to secondary activity (or vice versa)
	* this may be of interest in itself

	local acts "all"
	foreach a of local acts {
		* make sure we do this within diaries otherwise we might get a 'before' or 'after' belonging to a previous day (for multi day diaries)
		* or to someone else (for 1 day diaries or the first day)!
		
		qui: by diarypid: gen before_laundry_`a' = main[_n-1] if laundry_`a' == 1
		qui: by diarypid: gen after_laundry_`a' = main[_n+1] if laundry_`a' == 1
		
		lab val before_laundry_`a' after_laundry_`a' MAIN
		 
		qui: tabout before_laundry_`a' survey [iw=propwt] using "`rpath'/before-laundry-by-survey.txt", replace
		qui: tabout after_laundry_`a' survey [iw=propwt] using "`rpath'/after-laundry-by-survey.txt", replace
	}
	tab laundry_all
	* create a sequence variable (horrible kludge but hey, it works :-)
	egen laundry_seq = concat(before_laundry_all laundry_all after_laundry_all) if laundry_all == 1 , punct("_") 
	
	* get frequencies of sequencies (this will be a very big table)
	* the few which have missing (.) before laundry indicate nothing recorded before hand which seems a bit odd?
	
	tab laundry_seq
	
	preserve
		* contract doesn't like iw - only allows fw (which need to be integers)
		* so these will be unweighted
		contract laundry_seq survey, nomiss
		qui: tab laundry_seq
		
		qui: return li
		di "For laundry_seq after contract : N = " r(N) ", r = " r(r)

		* reshape it to get the frequencies per survey into columns
		qui: reshape wide _freq, i(laundry_seq) j(survey)
		qui: return li
		
		li in 1/5
		outsheet using "`rpath'/laundry-sequences-by-survey-wide.txt", replace
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
		
		
	restore
	
	/*
		* try using the sqset commands
		
		* tell it to look at sequences
		sqset main diarypid s_starttime
			
		* top 20 sequences
		sqtab survey if before_laundry ! = 1 | after_laundry ! = 1, ranks(1/20) 
	*/	
} 




log close
