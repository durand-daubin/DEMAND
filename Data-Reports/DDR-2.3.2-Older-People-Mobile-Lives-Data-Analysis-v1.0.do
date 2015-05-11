**************************************************************
* Data Exploration for DEMAND Theme 2.3 - older people's mobile lives
* - http://www.demand.ac.uk/research-themes/theme-2-how-end-use-practices-change/2-3-older-people-and-mobile-lives/
* - focus on leisure and longer duration/special travel

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

global where = "/Users/ben/Documents/Work"global droot = "$where/Data/Social Science Datatsets/"

global proot "$where/Projects/RCUK-DEMAND/Data Reports/Project 2.3 older people mobile lives"

global logd = "$proot/results"

capture log close

log using "$logd/DDR-2.3.2-Data-Analysis-v`version'.smcl", replace

local version "1.0"
* version 1.0

* control flow
local do_lcfs 0
local do_ips 1
local do_bsa 0

set more off


if `do_lcfs' {
	di "*-> do_lcfs = `do_lcfs' so running LCFS analysis"
	****************************
	* EFS/LCFS
	* https://www.esds.ac.uk/findingData/snDescription.asp?sn=7472
	* use file pre-created using https://github.com/dataknut/LCFS/blob/master/ONS-UK-EFS-time-series-extract.do
	use "$droot/Expenditure and Food Survey/processed/EFS-2001-2012-extract-reduced-BA.dta", clear
	
	/*
	* XXXc = child
	* XXXw = internet
	* XXXt = total
	
	dvhh:
	
	a325            byte   %8.0g       a325       purchase via internet - package holidays // removed 2011
	a328            byte   %8.0g       a328       purchase via internet - flights from uk // removed 2011
	
	b481            double %9.0g                  holiday package outside united kingdom
	b485			double %10.0g                 Holiday self-catering outside United Kingdom
	
	c96112c         byte   %8.0g                  package holidays abroad, accommodation
	c96112w         byte   %8.0g                  package holidays abroad, accomodation - internet
	
	cc5413          double %9.0g                  non-package holiday, other travel insurance
	cc5413c         byte   %8.0g                  non-package holiday, other travel insurance
	cc5413t         double %9.0g                  non-package holiday, other travel insurance
	
	c73311          double %9.0g                  air fares (within uk)
	c73311c         byte   %8.0g                  air fares (within uk)
	c73311t         double %9.0g                  air fares (within uk)
	c73311w         double %10.0g                 air-fares (within uk) - internet
	
	c73312          double %9.0g                  air fares (international)
	c73312c         byte   %8.0g                  air fares (international)
	c73312t         double %9.0g                  air fares (international)
	c73312w         double %10.0g                 air-fares (international) - internet
	
	rawhh:
	flydest* = flights inside/outside UK - last 12 months
	hhotloc* = location of holiday inside/outside UK - last 3 months - coded differently in different surveys
	packloc* = location of package holiday inside/outside UK - last 3 months - coded differently in different surveys
	*/
	
	egen n_non_uk_flights = anycount(flydest*), values(1)
	egen any_non_uk_flights = anymatch(flydest*), values(1)
	
	* code those who spent anything
	local exp_vars "b481 b485 c73312t"
	foreach v of local exp_vars {
		di "* % zero analysis: `v'"
		* do it this way round then the mean = proportion who report
		gen `v'_z = 1
		replace `v'_z = 0 if `v' == 0
	} 
	
	svyset [iw = weighta]
	
	* check availability of variables over time
	* non UK flights
	tabstat *_non_uk_flights c73312t* , by(ba_sampyear)
	
	svy: mean *_non_uk_flights, over( ba_sampyear)
	
	local testvars "n_non_uk_flights any_non_uk_flights"
	local byvars "c_age ba_birth_cohort"
	
	lab def p389_quart 0 "Lowest 25%" 1 "25% - 49%" 2 "50% - 74%" 3 "Highest 25%"
	lab val p389_quart p389_quart
	
	foreach v of local testvars {
		di "* Tables for `v'"	
		foreach byv of local byvars {
			di "* -> Tables for `v' by `byv'"
			qui: tabout ba_sampyear `byv' using "$logd/LCFS-`v'_by_year_`byv'.txt", ///
				cells(mean `v' se) ///
				format(3) ///
				replace sum svy 
	
			di "* --> Tables for `v' by `byv' and p389_quart"
			* disposable income quartiles within age groups
			* tabout does not do 3 way tables but we can fool it into creating them using
			* http://www.ianwatson.com.au/stata/tabout_tutorial.pdf p35
	
			local qcount = 0
			local filemethod = "replace"
			levelsof p389_quart, local(qlevels)
			local qlabels: value label p389_quart
		
			foreach l of local qlevels {	
				if `qcount' > 0 {
					* we already made one pass so now append
					local filemethod = "append"	
					*local heading = "h1(nil) h2(nil)"
				}
				local vlabel : label `qlabels' `l'
				qui: tabout ba_sampyear `byv' if p389_quart == `l' using "$logd/LCFS-`v'_by_year_`byv'_p389_quart.txt", `filemethod' ///
					h3("Income quartile: `vlabel'") ///
					cells(mean `v' se) ///
					format(3) ///
					sum svy 
				local qcount = `qcount' + 1
			}
		}
	}
	
	* look at % expenditure
	foreach v of local exp_vars {
		di "* % expenditure analysis: `v'"
		* % of all expenditure
		gen `v'_pr = `v'/p630tp
		foreach byv of local byvars {
			*table survey_year c_age [iw=weighta] , c(mean `v'_pr)
			qui: tabout ba_sampyear `byv' using "$logd/LCFS-`v'_pr_mean_by_year_`byv'.txt", ///
				cells(mean `v'_pr se) ///
				format(3) sum svy replace
			
			di "* --> Tables for `v' by `byv' and p389_quart"
			* disposable income quartiles within age groups
			* tabout does not do 3 way tables but we can fool it into creating them using
			* http://www.ianwatson.com.au/stata/tabout_tutorial.pdf p35
	
			local qcount = 0
			local filemethod = "replace"
			levelsof p389_quart, local(qlevels)
			local qlabels: value label p389_quart
		
			foreach l of local qlevels {	
				if `qcount' > 0 {
					* we already made one pass so now append
					local filemethod = "append"	
					*local heading = "h1(nil) h2(nil)"
				}
				local vlabel : label `qlabels' `l'
				qui: tabout ba_sampyear `byv' if p389_quart == `l' using "$logd/LCFS-`v'_pr_mean_by_year_`byv'_p389_quart.txt", `filemethod' ///
					h3("Income quartile: `vlabel'") ///
					cells(mean `v'_pr se) ///
					format(3) ///
					sum svy 
				local qcount = `qcount' + 1
			}
		}
	} 
	
	* sample size tables
	tab ba_sampyear c_age
	tab ba_sampyear ba_birth_cohort
	* distribution of income quartiles
	tab c_age p389_quart, row nof
}
else {
	di "*-> do_lcfs = `do_lcfs' so skipping LCFS analysis"
}

if `do_ips' {
	di "*-> do_ips = `do_ips' so running IPS analysis"
	****************************
	* UK IPS International Passenger Survey: 
	* http://discover.ukdataservice.ac.uk/series/?sn=2000025
	* use data pre-created using https://github.com/dataknut/IPS/blob/master/UK-IPS-time-series-extract.do
	use "$droot/UK International Passenger Survey/processed/IPS-2001-2013-extract-BA.dta", clear
		
	* do NOT use the weight - this appears to be a grossing not a non-response weight
	* all analyses are unweighted so no CI etc
	* svyset [iw=fweight]
	
	/*
	There are eight ÔflowsÕ, as follows:	1. Overseas residents departing UK via air	2. UK residents departing UK via air	3. Overseas residents arriving in UK via air	4. UK residents arriving in UK via air	5. Overseas residents departing UK via sea or tunnel 
	6. UK residents departing UK via sea or tunnel	7. Overseas residents arriving in UK via sea or tunnel 
	8. UK residents arriving in UK via sea or tunnel
	The overseas travel and tourism estimates published by ONS use only flows 1,4,5,8, i.e. those on which the visit is being completed. 
	These cases contain a range of detail about the visit
	*/
	
	* we're interested in flows 4 & 8 and they have been pre-coded in the extraction script
	* keep them to save memory etc
	keep if ba_flight_ar == 1 | ba_sea_ar == 1
	
	* test for air & sea/tunnel arrivals seperately
	local testvars = "ba_flight_ar ba_sea_ar"
	* test by age g roup & age cohort seperately
	local byvars = "ba_age ba_birth_cohort"
	* loop over the two forms
	foreach v of local testvars {
		di "* Tables for `v' == Yes"	
		* basic table for purpose by age
		qui: tabout year ba_purp if `v' == 1 using "$logd/IPS-`v'_by_year_ba_purp_unw.txt", ///
			cells(row) ///
			format(3) ///
			replace 

		foreach byv of local byvars {
			di "* -> Tables for `v' by `byv'"

			qui: tabout year `byv' if `v' == 1 using "$logd/IPS-`v'_by_year_`byv'_unw.txt", ///
				cells(row) ///
				format(3) ///
				replace
				
			di "* -> Tables for `v' by `byv' but only if ba_purp != (4) other"
			qui: tabout year `byv' if `v' == 1 & (ba_purp >= 1 & ba_purp <= 3) using "$logd/IPS-`v'_by_year_leisure_purpose_`byv'_unw.txt", ///
				cells(row) ///
				format(3) ///
				replace 

			
			di "* --> Tables for `v' by `byv' and purpose"
			* tabout does not do 3 way tables but we can fool it into creating them using
			* http://www.ianwatson.com.au/stata/tabout_tutorial.pdf p35
	
			local qcount = 0
			local filemethod = "replace"
			levelsof `byv', local(ba_levels)
			local plabels: value label `byv'
		
			foreach l of local ba_levels {	
				if `qcount' > 0 {
					* we already made one pass so now append
					local filemethod = "append"	
					*local heading = "h1(nil) h2(nil)"
				}
				local vlabel : label `plabels' `l'
				* table by year & age & purpose for flights or sea arrivals
				* this should give the % of each age group who reported a given purpose in each year
				qui: tabout year ba_purp if `v' == 1 & `byv' == `l' using "$logd/IPS-`v'_by_year_ba_purp_`byv'_unw.txt",  ///
					h3("Age group: `vlabel'") ///
					cells(row) ///
					format(3) ///
					`filemethod' 
				local qcount = `qcount' + 1
			}
			
		}
	}
	* sample size tables
	tab year ba_age if ba_flight_ar == 1
	tab year ba_age if ba_sea_ar == 1
	* distribution of purpose
	tab year ba_purp if ba_flight_ar == 1
	tab year ba_purp if ba_sea_ar == 1
}

else {
	di "*-> do_ips = `do_ips' so skipping IPS analysis"
}

log close
