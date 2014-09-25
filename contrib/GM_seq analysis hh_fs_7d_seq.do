/* 
giulio.mattioli@gmail.com

WHAT I WANT TO DO TO
is to use the basic sequence analysis tools in Stata (see Brzinsky-Fay et al.)
to investigate 7-days sequences for food shopping trips 
*/ 

* I have created the datasets I need with this do file 
* (unquote to use it) 

* do "C:\Users\s06gm3\Dropbox\Aberdeen\Job\Paper 2\Results\NTS\create hh_fs_7d_seq .do" 

* need to use the long file 

clear all 
use13 "C:\Users\Giulio\Dropbox\Aberdeen\Job\Paper 2\Data\hh_fs_7d_seq_long.dta", clear

* declare the data to be sequence (sqset) 

* I need a unique id variable for households

egen id=group(h96 psuid h88)
placevar id, first 

sqset fs_d id d1

** here follows the analysis 

sqtab

* cross it with carless 

merge m:1 h96 psuid h88 using "C:\Users\Giulio\Dropbox\Aberdeen\Job\Paper 2\Data\household.dta", keepusing(h55)
drop if _merge==2
drop _merge
tab h55, gen(car)

sqtab if car1==1, ranks(1/10)
sqtab if car1==0, ranks(1/10)

* or rather (if I want proper percentages) 

sqtab if car1==1
sqtab if car1==0

* sqdes

sqdes

* check if it changes if "no trips" sequences are excluded
preserve 
collapse (sum) fs_d, by(h96 psuid h88)
rename fs_d summa
save "C:\Users\Giulio\Dropbox\Aberdeen\Job\Paper 2\Results\hh_total.dta", replace
restore 
merge m:1 h96 psuid h88 using "C:\Users\Giulio\Dropbox\Aberdeen\Job\Paper 2\Results\hh_total.dta"

preserve 
drop if summa==0
sqdes
restore
drop summa

* by carless 

sqdes if car1==1
sqdes if car1==0

* by year 

foreach n of numlist 10/18 {
		di `1992+`n''
		sqdes if h96==`n'
}

** Sequence index plot 

sqindexplot

* I want them to be ordered randomly, need a random identifier for households 
preserve 
duplicates drop h96 psuid h88, force
gen x = uniform( )
save "C:\Users\s06gm3\Dropbox\Aberdeen\Job\Paper 2\Results\NTS\hh random.dta", replace
restore 
merge m:1 h96 psuid h88 using "C:\Users\s06gm3\Dropbox\Aberdeen\Job\Paper 2\Results\NTS\hh random.dta", keepusing(x)
drop _merge

sqindexplot, order(x)

** I've got bit overplotting issues with this command 

* I finally managed to obtain a more meaningful graph by generating distances with a rather random optimal matching 

sqom, subcost(rawdistance) indelcost(10) 

sqindexplot, order(_SQdist)
