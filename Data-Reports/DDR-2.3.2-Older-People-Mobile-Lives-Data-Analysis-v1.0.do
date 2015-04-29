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

local logd = "$proot/results"

local version "1.0"
* version 1.0
* household level analysis

capture log close

log using "`logd'/DDR-2.3.2-Data-Analysis-v`version'.smcl", replace

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
tabstat *_non_uk_flights c73312t* , by(survey_year)



* look at % expenditure
foreach v of local zvars {
	di "* % expenditure analysis: `v'"
	* % of all expenditure
	gen `v'_pr = `v'/p630p
	table survey_year c_age [iw=weighta] , c(mean `v'_pr)
	tabout survey_year c_age [iw=weighta] using "`logd'/`v'_pr_mean.txt", cells(mean `v'_pr se) format(3) sum svy replace
} 


log close
