/***************************************************************
* Data Exploration for DEMAND Theme 3.1 - adaptive infrastructures
* - http://www.demand.ac.uk/research-themes/theme-3-managing-infrastructures-of-supply-and-demand/3-1-adapting-infrastructure-for-a-lower-carbon-society/
* - focus on Stocksbridge & Stevenage (case studies)
* - trends in take-up of gas & electricity appliances

* This work was funded by RCUK through the End User Energy Demand Centres Programme via the
* "DEMAND: Dynamics of Energy, Mobility and Demand" Centre (www.demand.ac.uk, http://gtr.rcuk.ac.uk/project/0B657D54-247D-4AD6-9858-64E411D3D06C)

Latest version can be found at:

https://github.com/dataknut/DEMAND/blob/master/Data-Reports/DDR-3.1.2-Adaptive-Infrastructures-Data-Analysis-v1.0.do

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

global where = "~/Documents/Work"
global proot "$where/Projects/RCUK-DEMAND/Data Reports/Project 3.1 Adapting Infrastructure"
global censusroot = "$where/Data/Social Science Datatsets/UK Census"
global deccroot = "$where/Data/Social Science Datatsets/DECC/LSOA Energy Data"
global fesroot = "$where/Data/Social Science Datatsets/Family Expenditure Survey"
global lcfsroot = "$where/Data/Social Science Datatsets/Expenditure and Food Survey"

global logd = "$proot/results"

local version "1.0"
* version 1.0
* household level analysis

local do_census = 1
local do_lcfs = 0

capture log close

log using "$logd/DDR-3.1.2-Adapting-Infrastructures-Data-Analysis-v`version'.smcl", replace

set more off

if `do_census' {
	****************************
	* Census Analysis
	* done in excel using bespoke download from Casweb & InFuse
	********************************************
	* except for Census 2011 central heating fuel type & DECC data

	* load LSOA level Census data on central heating (obtained from neighbourhood statistics)
	use "$censusroot/2011Data/EW/lsoa/processed/2011-EW_LSOA_cent_heating_fixed.dta", clear
	rename zonecode lsoacode_2011
	* load LSOA level case study definitions file created earlier
	merge 1:m lsoacode_2011 using "$proot/data/2011_LSOA_LUT.dta"
	* needs multiple as some LSOA codes are duplicates where the MSOA has not been subdivided
	
	* check matches
	tab case_studies _merge, mi
	
	tabstat no_cc gas_ch electric_ch oil_ch solidfuel_ch other_ch twomore_ch hh_spaces, by(case_studies) s(sum)	
	
	merge m:1 lsoacode_2011 using "$censusroot/2011Data/EW/lsoa/processed/2011-LSOA-internet-form-completion-imd-rural-merged.dta", ///
		gen(imd_m) keepusing(regionname morphologycode morphologyname contextcode contextname combinedcode combinedname ///
		imdscore incomescore employmentscore healthdeprivationanddisabilitysc educationskillsandtrainingscore ///
		barrierstohousingandservicesscor crimeanddisorderscore livingenvironmentscore indoorssubdomainscore ///
		outdoorssubdomainscore geographicalbarrierssubdomainsco widerbarrierssubdomainscore childrenyoungpeoplesubdomainscor skillssubdomainscore idaciscore idaopiscore)
	
	* check matches again 
	tab case_studies _merge, mi

	tabstat no_cc gas_ch electric_ch oil_ch solidfuel_ch other_ch twomore_ch hh_spaces, by(regionname) s(sum)	
	
	* now add in 2009 gas/electricity data using lsoacode 2011 which we have added to it already
	merge m:m lsoacode_2011 using "$deccroot/2009/2348-llsoa-domestic-gas-geo.dta", ///
		gen(merge_gas)
	merge m:m lsoacode_2011 using "$deccroot/2009/2347-llsoa-domestic-elec-geo.dta", ///
		gen(merge_elec)
	
	* lots of non-matches caused by LSOAs with too few MPANS (so no LSOA allocated)
	
	* check matches again 
	tab case_studies merge_gas, mi
	tab case_studies merge_elec, mi

	lab var case_studies "case study area"
	lab var av_consumption_dom "Mean domestic ordinary electricity consumption (KwH, 2009)"
	lab var av_consumption_e7 "Mean domestic economy 7 electricity consumption (KwH, 2009)"
	lab var av_consumption_g "Mean domestic gas consumption (KwH, 2009)"
	* test
	su av_*
	
	* convert to %
	replace pc_electric_ch = pc_electric_ch * 100
	replace pc_gas_ch = pc_gas_ch * 100
	
	* case study areas are OK
	scatter av_consumption_dom pc_electric_ch if case_studies > 0, by(case_studies) name(scatter_elec_dom)
	graph export "$logd/graphs/scatter_elec_dom_case_studies.png", replace
	
	scatter av_consumption_e7 pc_electric_ch if case_studies > 0, by(case_studies) name(scatter_elec_e7)
	graph export "$logd/graphs/scatter_elec_e7_case_studies.png", replace
	
	scatter av_consumption_g pc_electric_ch if case_studies > 0, by(case_studies) name(scatter_gas_elec_ch)
	graph export "$logd/graphs/scatter_gas_cons_elec_ch_case_studies.png", replace

	scatter av_consumption_g pc_gas_ch if case_studies > 0, by(case_studies) name(scatter_gas)
	graph export "$logd/graphs/scatter_gas_case_studies.png", replace
	
	* shorten labels
	lab var case_studies "Case study area"
	lab var av_consumption_dom "Ordinary electricity"
	lab var av_consumption_e7 "Economy 7 electricity"
	lab var av_consumption_g "Gas"
	

	graph matrix av_consumption_g av_consumption_e7 av_consumption_dom if case_studies > 0, half by(case_studies) name(scatter_all) scale(0.2)
	graph export "$logd/graphs/matrix_gas_elec_case_studies.png", replace

	* analyse predictors of gas for case study areas
	* drop overall score  & kids/OA score
	preserve
		drop imdscore ida*score
		regress av_consumption_g pc_gas_ch pc_electric_ch *score if case_studies > 0
		regress av_consumption_dom pc_gas_ch pc_electric_ch *score if case_studies > 0
	restore
	
	keep lsoacode_2001 lsoacode_2011 av_* pc_* case_studies
	
	outsheet using "$deccroot/2009/llsoa-domestic-gas-elec-geo.csv", comma replace
	
	* keep the case study areas only for mapping
	preserve
		keep if case_studies == 1 | case_studies == 2
		outsheet using "$proot/data/llsoa-domestic-gas-elec-geo-case-studies.csv", comma replace
	restore
	
}

if `do_lcfs' {
	********************************************
	* Trends in take-up of gas & electricity using appliances
	* Uses:
	* FES: http://discover.ukdataservice.ac.uk/series/?sn=200016 (1960, 1970, 1980, 1990)
	* EFS/LCFS: http://discover.ukdataservice.ac.uk/series/?sn=2000028 (2000/1, 2010)
	* You will need to download the relevant years and check filenames etc
	********************************************
	local vars "a101 a102 a103 a104 a105 a108 a110 a141 a150 a151 a152 a153 a154"
	local vars "`vars' a155 a156 a164 a1641 a1642 a1643 a1661 a167 a168 a169 a170 a171 a172 a190 a191 a192 a193 a194 a195"
	local vars "`vars' a1644 a1645 a1701 a1711"
	
	* remove old files
	foreach v of local vars {
		di "* Variable: `v'"
		capture erase "$logd/tables/`v'.txt"
	}
	
	* FES, EFS, LC&FS
	* 1960, 1970, 1980, 1990, 2000, 2010
	
	* 1960
	use "$fesroot/1961/stata/hcr.dta", clear
	
	* nothing useful available
	
	* 1970
	use "$fesroot/1970/stata/hcr.dta", clear
	
	* regions/countries?
	tab a096
	* all UK
	
	/*
	a102            byte   %8.0g                  telephone in h/h
	a103            byte   %8.0g       a103       gas and electricity analysis
	a104            byte   %8.0g                  bath/showr h/h analysis,not 1969,70
	a105            byte   %8.0g       a105       tv set in h/h
	a108            byte   %8.0g                  no of washing mach in h/h
	a110            byte   %8.0g       a110       central heating-1969 only
	a150            byte   %8.0g                  central heating by electricity
	a151            byte   %8.0g                  central heating by gas
	a152            byte   %8.0g                  central heating by oil
	a153            byte   %8.0g                  central heating by solid fuel
	a154            byte   %8.0g                  central heating by fuel not known
	*/
	
	foreach v of local vars {
		di "* Testing `v' for 1970"
		capture noisily desc `v'
		if !_rc {
			* var exists but 1970 is first year so replace
			qui: tabout `v' using "$logd/tables/`v'.txt", cells(col) replace h2(1970) f(3)
		}
	}
	
	* 1980
	use "$fesroot/1980/stata/hcr.dta", clear
	
	* regions/countries?
	tab a096
	* all UK
	
	/*
	a102            byte   %8.0g                  telephone in h/h
	a103            byte   %8.0g       a103       gas and electricity analysis
	a105            byte   %8.0g       a105       tv set in h/h
	a108            byte   %8.0g                  no of washing machines in h/h
	a150            byte   %8.0g       a150       central heating by electricity
	a151            byte   %8.0g       a151       central heating by gas
	a152            byte   %8.0g       a152       central heating by oil
	a153            byte   %8.0g       a153       central heating by solid fuel
	a154            byte   %8.0g       a154       central heating by fuel not known
	*/
	
	* no weights
	foreach v of local vars {
		di "* Testing `v' for 1980"
		capture noisily desc `v'
		
		if !_rc {
			* var exists
			capture confirm file "$logd/tables/`v'.txt"
			if !_rc {
				* file exists so append
				qui: tabout `v' using "$logd/tables/`v'.txt", cells(col) append h2(1980) f(3)
			}
			else {
				* didn't exist so we can't append - make a new one
				qui: tabout `v' using "$logd/tables/`v'.txt", cells(col) replace h2(1980) f(3)
			}
		}
	}
	
	* 1990
	use "$fesroot/1990/stata/hchars.dta", clear
	merge 1:1 case using "$fesroot/1990/stata/hfuel.dta", gen(m_hfuel)
	merge 1:1 case using "$fesroot/1990/stata/hhousing.dta", gen(m_hhousing)
	
	* regions?
	tab a098
	* all UK
	 
	* no weights
	foreach v of local vars {
		di "* Testing `v' for 1990"
		capture noisily desc `v'
		
		if !_rc {
			* var exists
			capture confirm file "$logd/tables/`v'.txt"
			if !_rc {
				* file exists so append
				qui: tabout `v' using "$logd/tables/`v'.txt", cells(col) append h2(1990) f(3)
			}
			else {
				* didn't exist so we can't append - make a new one
				qui: tabout `v' using "$logd/tables/`v'.txt", cells(col) replace h2(1990) f(3)
			}
		}
	}
	
	* 2000-2001
	use "$fesroot/2000-2001/stata/set1.dta", clear
	merge 1:1 case using "$fesroot/2000-2001/stata/set13.dta"
	
	* regions
	tab gor
	* all UK
	
	/*
	a101            double %10.0g                 Telephone and\or mobile in household
	a108            double %10.0g                 Washing machine in household
	a141            double %10.0g                 Possession of video recorder
	a150            double %10.0g                 Central heating by electricity
	a151            double %10.0g                 Central heating by gas
	a152            double %10.0g                 Central heating by oil
	a153            double %10.0g                 Central heating by solid fuel
	a154            double %10.0g                 Central heating by solid fuel and oil
	a155            double %10.0g                 Central heating by calor gas
	a156            double %10.0g                 Other gas central heating
	a164            double %10.0g                 Fridge-freezer or deep freezer in househ
	a1641           double %10.0g                 Satellite receiver in household
	a1642           double %10.0g                 Cable receiver in household
	a1643           double %10.0g                 Digital receiver in household
	a1661           double %10.0g                 Home computer in household
	a167            double %10.0g                 Tumble dryer in household
	a168            double %10.0g                 Microwave oven in household
	a169            double %10.0g                 Dishwasher in household
	a170            double %10.0g                 Compact disc player in household
	a171            double %10.0g                 Possession of television
	a172            double %10.0g                 Internet connection in household
	a190            double %10.0g                 Internet access via Home Computer
	a191            double %10.0g                 Internet access via Digital TV
	a192            double %10.0g                 Internet access via mobile phone
	a193            double %10.0g                 Internet access via games console
	a194            double %10.0g                 Internet access via other method
	a195            double %10.0g                 WWW access via home computer
	*/
	
	* use weights
	svyset [iw=weight]
	foreach v of local vars {
		di "* Testing `v' for 2000-2001"
		capture noisily desc `v'
		
		if !_rc {
			* var exists
			capture confirm file "$logd/tables/`v'.txt"
			if !_rc {
				* file exists so append
				qui: tabout `v' using "$logd/tables/`v'.txt", svy cells(col se) append h2(2000-2001) f(3)
			}
			else {
				* didn't exist so we can't append - make a new one
				qui: tabout `v' using "$logd/tables/`v'.txt", svy cells(col se) replace h2(2000-2001) f(3)
			}
		}
	}
	
	* 2010
	use "$lcfsroot/2010/stata/dvhh.dta", clear
	
	rename *, lower	
	
	* regions
	tab gor
	* all UK
	
	/*
	a101            byte   %8.0g       a101       telephone and\or mobile in household
	a103            byte   %8.0g       a103       gas electric supplied to accomodation
	a108            byte   %8.0g       a108       washing machine in household
	a150            byte   %8.0g       a150       central heating by electricity
	a151            byte   %8.0g       a151       central heating by gas
	a152            byte   %8.0g       a152       central heating by oil
	a153            byte   %8.0g       a153       central heating by solid fuel
	a154            byte   %8.0g       a154       central heating by solid fuel and oil
	a155            byte   %8.0g       a155       central heating by calor gas
	a156            byte   %8.0g       a156       other gas central heating
	a164            byte   %8.0g       a164       fridge-freezer or deep freezer in hhold
	a167            byte   %8.0g       a167       tumble dryer in household
	a168            byte   %8.0g       a168       microwave oven in household
	a169            byte   %8.0g       a169       dishwasher in household
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
	
	svyset [iw=weighta]
	foreach v of local vars {
		di "* Testing `v' for 2010"
		capture noisily desc `v'
		
		if !_rc {
			* var exists
			capture confirm file "$logd/tables/`v'.txt"
			if !_rc {
				* file exists so append
				qui: tabout `v' using "$logd/tables/`v'.txt", svy cells(col se) append h2(2010) f(3)
			}
			else {
				* didn't exist so we can't append - make a new one
				qui: tabout `v' using "$logd/tables/`v'.txt", svy cells(col se) replace h2(2010) f(3)
			}
		}
	}
	* test multifuels
*	C45411t         double %10.0g                 Coal and coke
*	C45412t         double %10.0g                 Wood and peat
	gen buy_coal = 0
	replace buy_coal = 1 if c45411t > 0
	gen buy_wood = 0
	replace buy_wood = 1 if c45412t > 0
	gen buy_ch_oil = 0
	replace buy_ch_oil = 1 if b017 > 0
	gen buy_ch_gas = 0
	replace buy_ch_gas = 1 if b018 > 0
	
	table buy_ch_oil buy_coal buy_wood [iw=weighta]
	table a150 buy_coal buy_wood [iw=weighta]
	table a151 buy_coal buy_wood [iw=weighta]
	table a152 buy_coal buy_wood [iw=weighta]
	table a153 buy_coal buy_wood [iw=weighta]
	table a154 buy_coal buy_wood [iw=weighta]
	table a155 buy_coal buy_wood [iw=weighta]
	
}

log close
