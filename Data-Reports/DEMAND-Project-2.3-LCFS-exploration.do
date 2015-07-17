**************************************************************
* Explore UK Expenditure & Food Survey/ Living Costs & Food Survey
* - http://discover.ukdataservice.ac.uk/series/?sn=2000028

*  - non-UK flights & holidays by older people (Project 2.3)

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

local where = "~/Documents/Work"
local efsd = "`where'/Data/Social Science Datatsets/Expenditure and Food Survey"

local proot "`where'/Projects/RCUK-DEMAND/Data Consultancy/Project 2.3 older people mobile lives"

local logd = "`proot'/results"

local version "1.0"
* version 1.0
* household level analysis

capture log close

log using "`logd'/DEMAND-Project-2.3-LCFS-exploration-v`version'.smcl", replace

set more off

use "`efsd'/processed/EFS-2001-2010-extract-BA.dta", clear


/*
* XXXc = child
* XXXw = internet
* XXXt = total

a325            byte   %8.0g       a325       purchase via internet - package holidays
a328            byte   %8.0g       a328       purchase via internet - flights from uk

b480            double %9.0g                  holiday package within united kingdom
b481            double %9.0g                  holiday package outside united kingdom

c96111c         byte   %8.0g                  package holidays in the uk, accommodation
c96111w         byte   %8.0g                  package holidays in the uk, accomodation - internet

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

c_age 
*/

local all_vars "a325 a328 b480 b481 c96111c c96111w c96112c c96112w cc5413 cc5413c cc5413t c73311 c73311c c73311t c73311w c73312 c73312c c73312t c73312w"

* check availability of variables over time
tabstat `all_vars', by(survey_year)

tab c_age

* survey responses
* package holidays
tabstat a325 /// purchase via internet - package holidays
	a328 /// purchase via internet - flights from uk
	b480 /// holiday package within united kingdom
	b481 /// holiday package outside united kingdom
	if c_age > 4, by(survey_year) 

* diary responses - holidays
tabstat c96111* /// package holidays in the uk, accommodation
	c96112* /// package holidays abroad, accommodation
	cc5413* /// non-package holiday, other travel insurance
	if c_age > 4, by(survey_year)

* diary responses - air fares
tabstat c73311* /// air fares (within uk)
	c73312* /// air fares (international)
	if c_age > 4, by(survey_year)

svyset [iw=weighta]

* look at mean expenditures
* this is problematic - does not control for prices and is prone to probems caused by no
* reported expenditure (zeros)
table survey_year c_age [iw=weighta], c(mean b481) // holiday package outside united kingdom
tabout survey_year c_age [iw=weighta] using "`logd'/b481_holiday_non_uk_mean.txt", ///
	cells(mean b481 se) format(3) sum svy replace
tabout survey_year c_age [iw=weighta] using "`logd'/c73312t_intl_air_fares_mean.txt", ///
	cells(mean c73312t se) format(3) sum svy replace // air fares (international)
tabout survey_year c_age [iw=weighta] using "`logd'/cc5413t_holiday_non_package_ins_mean.txt", ///
	cells(mean cc5413t se) format(3) sum svy replace //  non-package holiday, other travel insurance

* switch to looking at % who reported expenditure on these items (not value of expenditure)
local zvars "a325 a328 b480 b481 cc5413t c73311t c73312t "

foreach v of local zvars {
	di "* % zero analysis: `v'"
	* do it this way round then the mean = proportion who report
	gen `v'_z = 1
	replace `v'_z = 0 if `v' == 0
	table survey_year c_age [iw=weighta] , c(mean `v'_z)
	tabout survey_year c_age [iw=weighta] using "`logd'/`v'_z_mean.txt", cells(mean `v'_z se) format(3) sum svy replace
} 

* look at % expenditure
foreach v of local zvars {
	di "* % expenditure analysis: `v'"
	* % of all expenditure
	gen `v'_pr = `v'/p630p
	table survey_year c_age [iw=weighta] , c(mean `v'_pr)
	tabout survey_year c_age [iw=weighta] using "`logd'/`v'_pr_mean.txt", cells(mean `v'_pr se) format(3) sum svy replace
} 

log close
