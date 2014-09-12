foreach v of varlist act1_* {
	gen l`v' = 0
	* no location check, no secondary act check
	replace l`v' = 1 if `v' == 3310
	}
