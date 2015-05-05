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

local version "1.0"
* version 1.0
* household level analysis

capture log close

log using "$logd/DDR-2.3.2-Data-Analysis-v`version'.smcl", replace

set more off


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
		qui: tabout ba_sampyear `byv' using "$logd/`v'_by_year_`byv'.txt", ///
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
			qui: tabout ba_sampyear `byv' if p389_quart == `l' using "$logd/`v'_by_year_`byv'_p389_quart.txt", `filemethod' ///
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
		qui: tabout ba_sampyear `byv' using "$logd/`v'_pr_mean_by_year_`byv'.txt", ///
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
			qui: tabout ba_sampyear `byv' if p389_quart == `l' using "$logd/`v'_pr_mean_by_year_`byv'_p389_quart.txt", `filemethod' ///
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

log close
