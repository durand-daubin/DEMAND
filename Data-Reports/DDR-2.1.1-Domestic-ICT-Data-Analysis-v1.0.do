**************************************************************
* Data Analysis for DEMAND Theme 2.1 - Domestic ICT
* - http://www.demand.ac.uk/research-themes/theme-2-how-end-use-practices-change/2-1-domestic-it-use/
* - focus on use of ICT in and around the home
* - see https://docs.google.com/document/d/19yElRZp27oFhyT6vDT2vO4OJ2BwOKauk8vTstchceqc/edit

* This work was funded by RCUK through the End User Energy Demand Centres Programme via the
* "DEMAND: Dynamics of Energy, Mobility and Demand" Centre (www.demand.ac.uk, http://gtr.rcuk.ac.uk/project/0B657D54-247D-4AD6-9858-64E411D3D06C)

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

* these will be true across all scripts so globals = OK
global where "~/Documents/Work"
global droot "$where/Data/Social Science Datatsets"


* these will be true only of this script so use locals
global proot "$where/Projects/RCUK-DEMAND"
global logd "$proot/Data Reports/Project 2.1 Domestic ICT/results"

local version "1.0"
* version 1.0

capture log close

log using "$logd/DDR-2.3.1-Data-Analysis-v`version'.smcl", replace

local do_lcfs 0 // ICT & media tech ownership in 2013
local do_traj 0 // 2011 time use survey from Trajectory
local do_mtus 0 // MTUS change over time analysis
local do_hes 1 // HES electricity consumption analysis

set more off

if `do_lcfs' {
	********************************************************
	* ICT & Media ownership 2013 
	* LCFS 2013
	* https://www.esds.ac.uk/findingData/snDescription.asp?sn=7472
	use "$droot/Expenditure and Food Survey/processed/EFS-2013-extract-BA.dta", clear

	* summarise ICT ownership

	** all UK
	tab region
	/*
	a101            byte   %8.0g       a101       telephone and\or mobile in household
	a170            byte   %8.0g       a170       compact disc player in household
	a171            byte   %8.0g       a171       tv set in household (not after 2009)
	a172            byte   %8.0g       a172       internet connection in household
	a190            byte   %8.0g       a190       internet access via home computer
	a191            byte   %8.0g       a191       internet access via digital tv
	a192            byte   %8.0g       a192       internet access via mobile phone
	a193            byte   %8.0g       a193       internet access via games console
	a194            byte   %8.0g       a194       internet access via other method
	a195            byte   %8.0g       a195       www access via home computer (not after 2002-2003)
	a1641           byte   %8.0g       a1641      satellite receiver in household
	a1642           byte   %8.0g       a1642      cable receiver in household
	a1643           byte   %8.0g       a1643      satellite receiver in household
	a1644           byte   %10.0g                 TV connection by Broadband (from 2003-2004)
	a1645           byte   %10.0g                 TV received by Aerial (from 2003-2004)
	a1661           byte   %8.0g       a1661      home computer in household
	a1701           byte   %8.0g       a1701      dvd player in household (from 2002-2003)
	a1711           byte   %8.0g       LABA       Television in household (replaces a171)
	*/
	gen computer_sum = 0
	gen access_sum = 0
	forvalues n = 1/6 {
		replace computer_sum = `n' if computer1 == `n' | computer2 == `n' | computer3 == `n' | computer4 == `n'
		lab val computer_sum Computer1
		replace access_sum = `n' if access1 == `n' | access2 == `n' | access3 == `n' | access4 == `n'
		lab val access_sum Access1
	}

	local rawvars "telephon mobile computer1 computer2 computer3 computer4 computer_sum inter access1 access2 access3 access4 access_sum"
	local dvvars "a1641 a1642 a1645 a1661"

	svyset [iw=weighta]

	di "******************************"
	foreach r of local rawvars {
		di "* Testing raw hh var: `r'"
		svy: tab `r' , missing col se format(%8.0g)
	}

	foreach r of varlist computer_sum access_sum {
		di "* Testing raw hh var: `r' by age & employment"
		svy: tab `r' c_age, missing col se format(%8.0g)
		svy: tab `r' c_empl, missing col se format(%8.0g)
		svy: tab `r' c_nchild, missing col se format(%8.0g)
	}

	di "******************************"
	foreach v of local dvvars {
		di "* Testing dvvar: `v'"
		svy: tab `v' , missing col se format(%8.0g)
		svy: tab `v' c_age, missing col se format(%8.0g)
		svy: tab `v' c_empl, missing col se format(%8.0g)
		svy: tab `v' c_nchild, missing col se format(%8.0g)
	}

}
********************************************************
* ICT & Media ownership 1970 - 2010
* see https://github.com/dataknut/DEMAND/blob/master/Data-Reports/DDR-3.1.2-Adaptive-Infrastructures-Data-Analysis-v1.0.do


if `do_traj' {
	********************************************************
	* ICT & Media time use 2011
	* uses the sample of the Trajectory dataset purchased by DEMAND
	use "$proot/Theme 1/data/Time Use/Trajectory-Oxford/Trajectory data 650, Feb 2014-purchased-labelled-long.dta", clear

	preserve
		duplicates drop diarypid, force
		tab dtskwd // how many diary days are weeksdays?
		
		* drop to pid level
		duplicates drop pid, force
		tab dscity
		tab C1 // social grade
		tab C2 C4, col // gender by age band
		tab C20 // employment
		tab C17 // income

	restore

	*           27 Watching TV and videos/DVDs, listening to radio or music
	*           37 Using a computer or accessing the internet:
	local labt_27 "Watching TV and videos/DVDs, listening to radio or music"
	local labt_37 "Using a computer or accessing the internet"


	local acts "27 37"
	foreach p of local acts {
		gen pact_`p' = 0
		replace pact_`p' = 1 if pact == `p'
		tabstat pact_`p', by(dtskwd)
		tabstat pact_`p', by(C4)
		preserve
			di "* collapsing for `labt_`p'' by(s_halfhour dtskwd C4)"
			local coll "s_halfhour dtskwd C4"
			collapse (mean) m_pact_`p' = pact_`p', by(`coll')
				gen m_pact_`p'_pc = 100 * m_pact_`p'
				lab var m_pact_`p'_pc "% of acts"
				li in 1/5
				* force contour to display legend
				twoway contour m_pact_`p'_pc dtskwd s_halfhour , name(cont_`p'age) ///
					by(C4, note("Trajectory 2011 data: reported `labt_`p''") scale(0.75) clegend(on)) ///
					zlabel(#9, format(%9.0f)) ///
					ylabel(1 2 3 4 5 6 7, valuelabel angle(horizontal))  
				graph export "$logd/trajectory_cont_mean_`p'_by_age.png", replace
				twoway contour m_pact_`p'_pc dtskwd s_halfhour if C4 > 1 & C4 < 6, name(cont_`p'ager) ///
					by(C4, note("Trajectory 2011 data: reported `labt_`p''") scale(0.75) clegend(on)) ///
					zlabel(#9, format(%9.0f)) ///
					ylabel(1 2 3 4 5 6 7, valuelabel angle(horizontal))  
				graph export "$logd/trajectory_cont_mean_`p'_by_age_reduced.png", replace
		restore
		preserve
			di "* collapsing for `labt_`p''"
			local coll "s_halfhour dtskwd"
			collapse (mean) m_pact_`p' = pact_`p' (sem) sem_pact_`p' = pact_`p', by(`coll')
				gen m_pact_`p'_pc = 100 * m_pact_`p'
				* create upper 95% CI
				gen m_pact_`p'_pc_u = m_pact_`p'_pc+(100*(1.96*sem_pact_`p'))
				lab var m_pact_`p'_pc_u "95% CI (upper)"
				* create lower 95% CI
				gen m_pact_`p'_pc_l = m_pact_`p'_pc-(100*(1.96*sem_pact_`p'))
				lab var m_pact_`p'_pc_l "95% CI (lower)"
				lab var m_pact_`p'_pc "% of acts"
				twoway rarea m_pact_`p'_pc_u m_pact_`p'_pc_l s_halfhour, by(dtskwd) color(gs14) || ///
					line m_pact_`p'_pc s_halfhour, ///
					by(dtskwd, note("Trajectory 2011 data: reported `labt_`p''")) name(line_`p') 
				graph export "$logd/trajectory_rarea_mean_`p'.png", replace
		restore
	}
}

if `do_mtus' {
	********************************************************
	* ICT & Media time use 1974-2005
	* uses the MTUS

	use "$droot/MTUS/World 6/processed/MTUS-adult-aggregate-UK-only-wf.dta", clear

	tab mtus_year // n diary days per Survey
	
	* office work at home (presumes uses ICT)
	* borrows from Project 3.2.2 definition
	* code 'office work' - plenty of room for mis-categorisation here!
	tab occup
	recode occup (-9 -7=.) (1/9 = 1) (else=0), gen(office_worker)

	lab def office_worker 0 "Not an office worker" 1 "Office worker"
	lab val office_worker office_worker

	keep diarypid office_worker propwt

	merge 1:m diarypid using "$droot/MTUS/World 6/processed/MTUS-adult-episode-UK-only-wf-10min-samples-long-v1.0.dta"
	
	* pool surveys
	recode survey (1974=1974 "1974") (1983/1987=1985 "1985") (1995 = 1995 "1995") ///
		(2000=2000 "2000") (2005=2005 "2005"), gen(ba_survey)
	
	recode pact (7 8 9 11 12 13 = 1) (else = 0), gen(work_m)
	recode sact (7 8 9 11 12 13 = 1) (else = 0), gen(work_s)

	egen work = rowtotal(work_*)

	* this will have a value of 0 if no work, 1 if work as main or sec and 2 if work as main AND sec
	* recode slightly
	recode work (2=1)

	gen ba_hourt = hh(s_starttime)
	gen ba_minst = mm(s_starttime)

	gen ba_hh = 0 if ba_minst < 30
	replace ba_hh = 30 if ba_minst > 29
	gen ba_sec = 0
	* sets date to 1969!
	gen s_halfhour = hms(ba_hourt, ba_hh, ba_sec)
	lab var s_halfhour "Episode starts during the half hour following"
	format s_halfhour %tcHH:MM

	drop ba_hourt ba_minst ba_hh ba_sec
	gen work_pc = 100 * work
	* all work at home
	tabstat work_pc if eloc == 1, by(ba_survey) s(mean semean)
	* office workers
	tabstat work_pc if eloc == 1 & office_worker == 1, by(ba_survey) s(mean semean)
	
	preserve
		collapse (mean) work_pc [iw=propwt] if eloc == 1 & office_worker == 1, by(s_halfhour s_dow ba_survey)
		tabstat work_pc, by(ba_survey) s(mean semean)
		lab var work_pc "% of acts"
		* force contour to display legend
		twoway contour work_pc s_dow s_halfhour , name(cont_work_pc) ///
			by(ba_survey, note("MTUS 1974-2005: reported 'office work' at home") scale(0.75) clegend(on)) ///
			zlabel(#9, format(%9.0f)) ///
			ylabel(0 1 2 3 4 5 6, valuelabel angle(horizontal))  
		graph export "$logd/MTUS_cont_mean_office_work_by_survey.png", replace

	restore


	local act_103l "TV, video, DVD, computer games at home"
	local act_104l "Computer, Internet at home"
	
	* 103: TV/video/DVD/computer games at home
	gen act_103 = 0
	replace act_103 = 1 if (pact == 59 | pact == 60) & eloc == 1
	replace act_103 = 1 if (sact == 59 | sact == 60) & eloc == 1


	* 104: Computer/Internet at home
	gen act_104 = 0
	replace act_104 = 1 if (pact == 61 | pact == 61) & eloc == 1	
	

	local acts "103 104"
	foreach a of local acts {
		di "Processing `a': `act_`a'l'"
		tab ba_survey act_`a'
		gen act_`a'_pc = 100 * act_`a'
		preserve
			collapse (mean) act_`a'_pc [iw=propwt], by(s_halfhour s_dow ba_survey)
			tabstat act_`a'_pc, by(ba_survey) s(mean semean n)
			lab var act_`a'_pc "% of acts"
			* force contour to display legend
			twoway contour act_`a'_pc s_dow s_halfhour , name(cont_act_`a'_pc) ///
				by(ba_survey, note("MTUS 1974-2005: `act_`a'l'") scale(0.75) clegend(on)) ///
				zlabel(#9, format(%9.1f)) ///
				ylabel(0 1 2 3 4 5 6, valuelabel angle(horizontal))  
			graph export "$logd/MTUS_cont_mean_act_`a'_pc_by_survey.png", replace

		restore
	}
}

if `do_hes' {
	********************************************************
	* Household electricity consumption using HES data 
	* https://www.gov.uk/government/collections/household-electricity-survey

	* this code expects  
	* https://github.com/dataknut/HES/blob/master/HES-process-files.do
	* to have been run first to create:
	use "$droot/HES/data/processed/appliance_group_data-3_no_zeros.dta", clear

	* and also to create:
	* attach appliance info from wide file
	merge m:1 id appliance using "$droot/HES/data/processed/appliance_data_wide.dta", ///
		keepusing(is_uniq room1 appliancetext1 category1) gen(app_id_match)
	
	* mis-matches form master indicate unknown appliance records
	tab app_id_match is_uniq, mi

	* how many unique matches do we have?
	tab appliancetext1 is_uniq, mi
	tab appliancetext1 is_uniq , mi row nofreq

	* keep uniq & matches only for now
	keep if is_uniq == 1 & app_id_match == 3

	keep if category == "Entertainment" | category == "ICT"

	* want to keep TVs, Desktop PCs, 
	* Fax/Printers, Hard drives, Laptops, Modems, Monitors, 
	* Multifunction printers, Printers, Router and Scanners
	
	* set up half-hour variable
	gen ba_hourt = hh(s_datetime)
	gen ba_minst = mm(s_datetime)

	gen ba_hh = 0 if ba_minst < 30
	replace ba_hh = 30 if ba_minst > 29
	gen ba_sec = 0
	* sets date to 1969!
	gen s_halfhour = hms(ba_hourt, ba_hh, ba_sec)
	lab var s_halfhour "Half hour (start)"
	format s_halfhour %tcHH:MM

	* dow
	gen s_dow = dow(dofc(s_datetime))
	* set re-usable label
	lab var s_dow "Day of week"
	lab def s_dow 0 "Sunday" 1 "Monday" 2 "Tuesdays" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday"
	lab val s_dow s_dow

	* weekend
	gen weekend = 0
	replace weekend = 1 if s_dow == 0 | s_dow == 6
	lab var weekend "Weekend"
	lab def weekend 0 "Weekday" 1 "Weekend"
	lab val weekend weekend

	gen month = month(dofc(s_datetime))
	* seasons
	recode month (3 4 5 = 1 "Spring") (6 7 8 = 2 "Summer") (9 10 11 = 3 "Autumn") (12 1 2 = 4 "Winter"), gen(season)
	* check
	tab month season
	tab appliancetext1

	/*
		 ComputersDesktop |    596,283       12.22       13.30
  ComputersHomeTheatreBox |          2        0.00       13.30
          ComputersLaptop |    253,460        5.20       18.50
         ComputersMonitor |    349,030        7.16       25.65
        ComputersSpeakers |    148,512        3.04       28.70
                Facsimile |          2        0.00       38.31
             GamesConsole |    182,353        3.74       42.04
        HomeTheatreSystem |     67,741        1.39       47.99
                    Modem |         11        0.00       47.99
            PrinterInkjet |    118,799        2.44       50.43
             PrinterLaser |     52,509        1.08       51.51
  PrinterScannerCopierMFD |     66,205        1.36       52.86
                    Radio |      9,706        0.20       53.06
                   Router |    310,059        6.36       59.42
                SetTopBox |    550,321       11.28       70.70
                SettopBox |     52,329        1.07       71.77
                    TVCRT |    193,984        3.98       76.11
                    TVLCD |    682,567       13.99       90.10
                 TVPlasma |     98,300        2.02       92.12
                   TV_DVD |     50,979        1.05       93.17
               TV_Monitor |     51,604        1.06       94.22
                   TV_VCR |    121,912        2.50       96.72
               TV_VCR_DVD |        180        0.00       96.73
                      VCR |     89,493        1.83       98.56
                   router |         34        0.00       98.59
             gamesconsole |          8        0.00       98.59

*/
	gen ba_ict = "Desktop" if appliancetext1 == "ComputersDesktop"
	replace ba_ict = "Laptop" if appliancetext1 == "ComputersLaptop"
	replace ba_ict = "PC monitor" if appliancetext1 == "ComputersMonitor"
	replace ba_ict = "Printers" if regexm(appliancetext1, "Printer") 
	replace ba_ict = "Router" if appliancetext1 == "Router" | appliancetext1 == "router"
	replace ba_ict = "Modem" if appliancetext1 == "Modem"
	replace ba_ict = "Set top box, VCR or DVD" if appliancetext1 == "SetTopBox" | ///
		appliancetext1 == "SettopBox" | /// 
		appliancetext1 == "VCR"
	replace ba_ict = "TV etc" if regexm(appliancetext1, "TV")
	replace ba_ict = "Home Theatre System" if appliancetext1 == "HomeTheatreSystem"
	replace ba_ict = "Games console" if regexm(appliancetext1, "onsole") // picks up lower case

	tab ba_ict is_uniq

	* check how many households responsible for each code
	preserve
		duplicates drop id ba_ict, force
		tab id ba_ict, mi
		tab ba_ict, mi
	restore

	preserve
		collapse (mean) watts, by(s_halfhour s_dow ba_ict category season)
		
		lab val s_dow s_dow // in case
		* creates 2 charts
		levelsof category, local(categories)
		foreach c of local categories {
			di "****************"
			di "* Watts: `c' by time of day (half hours)"
			su watts if category == "`c'"
			* force contour to display legend
			twoway contour watts s_dow s_halfhour if category == "`c'", name(`c') ///
				by(season, note("Category = `c' (HES Data: Annual (10 minutes) dataset)") scale(0.75) clegend(on)) ///
				zlabel(#9, format(%9.0f)) ///
				ylabel(0 1 2 3 4 5 6, valuelabel angle(horizontal))  
			graph export "$logd/HES_`c'_cont_mean_watts_by_season.png", replace
		}

		* creates quite a few
		levelsof ba_ict, local(apps)
		foreach app of local apps {
			di "****************"
			di "* Watts: `app' by time of day (half hours)"
			su watts if ba_ict == "`app'"
			* force contour to display legend
			* no name to preserve working memory
			* use capture to avoid crash wehere no data
			capture noisily {
				twoway contour watts s_dow s_halfhour if ba_ict == "`app'", ///
					by(season, note("Appliance = `app' (HES Data: Annual (10 minutes) dataset)") scale(0.75) clegend(on)) ///
					zlabel(#9, format(%9.0f)) ///
					ylabel(0 1 2 3 4 5 6, valuelabel angle(horizontal))  
				graph export "$logd/HES_`app'_cont_mean_watts_by_season.png", replace
			}
		}
		

	restore
}


di "* Done!"
log close
