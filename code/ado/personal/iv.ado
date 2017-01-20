*! version 1.0.1 , 20Mar2000
program define iv, rclass
* Arie Beresteanu and Charles Manski
* Northwestern University
version 6.0

syntax varlist(min=2 max=5)  [if] , Inst(string)/*
*/ AT(string) [ Niv(integer 20) IVG(string) CONtinuous/* 
*/ W1(real 0.0) W2(real 0.0) W3(real 0.0) W4(real 0.0)/*
*/ BIweight EPan GAUss RECtangle  /*
*/ TRIangle Boot(integer 0) Level(real 95)*]

tokenize `varlist'
local xnum : word count `varlist'
local xnum=`xnum'-2
local iy `1'
local iz `2'
local i 1
while `i'<=`xnum' {
	local j=`i'+2
	local ix`i'  ``j''
	local i=`i'+1
}


tokenize `inst'
local ivnum : word count `inst'
local i 1
while `i'<=`ivnum' {
	local iv`i'= "``i''"
	local i=`i'+1
}


	local kflag = ( (`"`epan'"' != `""') + (`"`biweigh'"' != `""') + /*
			*/ (`"`triangl'"' != `""') + (`"`gauss'"' != `""') + /*
			*/ (`"`rectang'"' != `""'))
	if `kflag' > 1 {
		di in red `"only one kernel may be specified"'
		exit 198
	}

	if `"`biweigh'"'       != `""' { local kernel=`"Biweight"'     }
	else if `"`triangl'"'  != `""' { local kernel=`"Triangle"'     }
	else if `"`gauss'"'    != `""' { local kernel=`"Gaussian"'     }
	else if `"`rectang'"'  != `""' { local kernel=`"Rectangular"'  }
	else                       { local kernel=`"Epanechnikov"' }

	tokenize `at'
	local atnum : word count `at'
	if `atnum' != `xnum' {
		di in red `"insufficient parameters in at() option"'
		exit 198
	}
	local i 1
while `i'<=`atnum' {
	local m`i'="``i''"
	local i=`i'+1
}
qui count if `m1'!=.
local n=r(N)

	tokenize `ivg'
	local ivgnum : word count `ivg'
	local i 1
	while `i'<=`ivgnum' {
		local ivg`i'="``i''"
		local i=`i'+1
	}

if `niv'<=0 & `ivgnum'==0 {
	di in red "No grid variable or number of grid points were given"
	exit 198
}

if `niv'>0 & `ivgnum'>0 {
	di in red "Only one of Niv and IVG options should be specified"
	exit 198
}


tempvar lb0 ub0 lb1 ub1 trl tru
qui gen long `lb0'=.
qui gen long `ub0'=.
qui gen long `lb1'=.
qui gen long `ub1'=.
qui gen long `trl'=.
qui gen long `tru'=.

local i 1
while `i'<=`n' {
	local j 1
	local z=""
	while `j'<=`xnum' {
		local zz=string(`m`j''[`i'])
		local z="`z' `zz'"
		local j=`j'+1
	}
	local j 1
	local w=""
	while `j'<=`ivnum' {
		local ww=string(`iv`j''[`i'])
		local w="`w' `ww'"
		local j=`j'+1
	}
	iv2 `iy' `iz' `ix1' `ix2' `ix3', at(`z') inst(`iv1' `iv2' `iv3') niv(`niv')/*
	*/ ivg(`ivg') `continuous' w1(`w1') w2(`w2') w3(`w3') w4(`w4') /*
	*/ `epan' `biweigh' `triangl' `gauss' `rectang'
	qui replace `lb0'=r(LB0) in `i'
	qui replace `ub0'=r(UB0) in `i'
	qui replace `lb1'=r(LB1) in `i'
	qui replace `ub1'=r(UB1) in `i'
	qui replace `trl'=r(treatL) in `i'
	qui replace `tru'=r(treatU) in `i'
	local i=`i'+1
}

local LB0 "LB0"
local UB0 "UB0"
local LB1 "LB1"
local UB1 "UB1"
local treatL "treatL"
local treatU "treatU"

*! Outputing the results
capture confirm new variable LB0
if _rc==110 {
	qui replace `LB0'=`lb0'
}
else {
	qui gen `LB0'=`lb0'
}
capture confirm new variable UB0
if _rc==110 {
	qui replace `UB0'=`ub0'
}
else {
	qui gen `UB0'=`ub0'
}
capture confirm new variable LB1
if _rc==110 {
	qui replace `LB1'=`lb1'
}
else {
	qui gen `LB1'=`lb1'
}
capture confirm new variable UB1
if _rc==110 {
	qui replace `UB1'=`ub1'
}
else {
	qui gen `UB1'=`ub1'
}
capture confirm new variable treatL
if _rc==110 {
	qui replace `treatL'=`trl'
}
else {
	qui gen `treatL'=`trl'
}
capture confirm new variable treatU
if _rc==110 {
	qui replace `treatU'=`tru'
}
else {
	qui gen `treatU'=`tru'
}
if `boot'>0 {
	local LB0_lb "LB0_lb"
	local LB0_ub "LB0_ub"
	local LB1_lb "LB1_lb"
	local LB1_ub "LB1_ub"
	local UB0_lb "UB0_lb"
	local UB0_ub "UB0_ub"
	local UB1_lb "UB1_lb"
	local UB1_ub "UB1_ub"
	local trtL_lb "trtL_lb"
	local trtL_ub "trtL_ub"
	local trtU_lb "trtU_lb"
	local trtU_ub "trtU_ub"
	tempvar lb0_lb lb0_ub lb1_lb lb1_ub ub0_lb ub0_ub ub1_lb ub1_ub trl_lb trl_ub tru_lb tru_ub
	qui gen `lb0_lb'=.
	qui gen `lb0_ub'=.
	qui gen `lb1_lb'=.
	qui gen `lb1_ub'=.
	qui gen `ub0_lb'=.
	qui gen `ub0_ub'=.
	qui gen `ub1_lb'=.
	qui gen `ub1_ub'=.
	qui gen `trl_lb'=.
	qui gen `trl_ub'=.
	qui gen `tru_lb'=.
	qui gen `tru_ub'=.
	di "Running `boot' bootstrap simulation for each grid point - please wait"
	local i 1
	while `i'<=`n' {
		local j 1
		local z=""
		while `j'<=`xnum' {
			local zz=string(`m`j''[`i'])
			local z="`z' `zz'"
			local j=`j'+1
		}
	di "grid point #`i'"	
	qui bs "iv2 `iy' `iz' `ix1' `ix2' `ix3', at(`z') inst(`iv1' `iv2' `iv3') niv(`niv') `continuous' w1(`w1') w2(`w2') w3(`w3') w4(`w4') `epan' `biweigh' `triangl' `gauss' `rectang'" "r(LB0) r(UB0) r(LB1) r(UB1) r(treatL) r(treatU)" , reps(`boot') l(`level') saving(treatbs) replace
	merge using treatbs
	qui sum bs1,detail
	qui replace `lb0_lb' =r(p5) in `i'
	qui replace `lb0_ub'=r(p95) in `i'
	qui sum bs2,detail
	qui replace `ub0_lb' =r(p5) in `i'
	qui replace `ub0_ub'=r(p95) in `i'
	qui sum bs3,detail
	qui replace `lb1_lb' =r(p5) in `i'
	qui replace `lb1_ub'=r(p95) in `i'
	qui sum bs4,detail
	qui replace `ub1_lb' =r(p5) in `i'
	qui replace `ub1_ub'=r(p95) in `i'
	qui sum bs5,detail
	qui replace `trl_lb' =r(p5) in `i'
	qui replace `trl_ub'=r(p95) in `i'
	qui sum bs6,detail
	qui replace `tru_lb' =r(p5) in `i'
	qui replace `tru_ub'=r(p95) in `i'
	drop _merge bs1 bs2 bs3 bs4 bs5 bs6
	local i=`i'+1
	}
	capture confirm new variable LB0_lb
	if _rc==110 {
		qui replace `LB0_lb'=`lb0_lb'
	}
	else {
		qui gen `LB0_lb'=`lb0_lb'
	}
	capture confirm new variable LB0_ub
	if _rc==110 {
		qui replace `LB0_ub'=`lb0_ub'
	}
	else {
		qui gen `LB0_ub'=`lb0_ub'
	}
	capture confirm new variable LB1_lb
	if _rc==110 {
		qui replace `LB1_lb'=`lb1_lb'
	}
	else {
		qui gen `LB1_lb'=`lb1_lb'
	}
	capture confirm new variable LB1_ub
	if _rc==110 {
		qui replace `LB1_ub'=`lb1_ub'
	}
	else {
		qui gen `LB1_ub'=`lb1_ub'
	}
	capture confirm new variable UB0_lb
	if _rc==110 {
		qui replace `UB0_lb'=`ub0_lb'
	}
	else {
		qui gen `UB0_lb'=`ub0_lb'
	}
	capture confirm new variable UB0_ub
	if _rc==110 {
		qui replace `UB0_ub'=`ub0_ub'
	}
	else {
		qui gen `UB0_ub'=`ub0_ub'
	}
	capture confirm new variable UB1_lb
	if _rc==110 {
		qui replace `UB1_lb'=`ub1_lb'
	}
	else {
		qui gen `UB1_lb'=`ub1_lb'
	}
	capture confirm new variable UB1_ub
	if _rc==110 {
		qui replace `UB1_ub'=`ub1_ub'
	}
	else {
		qui gen `UB1_ub'=`ub1_ub'
	}
	capture confirm new variable trtL_lb
	if _rc==110 {
		qui replace `trtL_lb'=`trl_lb'
	}
	else {
		qui gen `trtL_lb'=`trl_lb'
	}
	capture confirm new variable trtL_ub
	if _rc==110 {
		qui replace `trtL_ub'=`trl_ub'
	}
	else {
		qui gen `trtL_ub'=`trl_ub'
	}
	capture confirm new variable trtU_lb
	if _rc==110 {
		qui replace `trtU_lb'=`tru_lb'
	}
	else {
		qui gen `trtU_lb'=`tru_lb'
	}
	capture confirm new variable trtU_ub
	if _rc==110 {
		qui replace `trtU_ub'=`tru_ub'
	}
	else {
		qui gen `trtU_ub'=`tru_ub'
	}

}
ret clear
ret scalar n = `n'
ret scalar xnum=`xnum'
ret local kernel `"`kernel'"'
ret local method `"`method'"'


end

