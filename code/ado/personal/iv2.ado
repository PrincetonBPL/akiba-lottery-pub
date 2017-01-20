*! version 1.0.1 , 18 Oct 1999
program define iv2, rclass
version 6.0

syntax varlist(min=2 max=5)  [if] , inst(string)/*
*/ AT(string) [ niv(integer 0) IVG(string) CONtinuous/* 
*/ W1(real 0.0) W2(real 0.0) W3(real 0.0) W4(real 0.0)/*
*/ BIweight EPan GAUss RECtangle  /*
*/ TRIangle *]

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
	local iv`i' ``i''
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
		local m`i'=``i''
		local i=`i'+1
	}

	tokenize `ivg'
	local ivgnum : word count `ivg'
	local i 1
	while `i'<=`ivgnum' {
		local ivg`i'="``i''"
		local i=`i'+1
	}

local gn=`niv'

if `ivgnum'>=1 {
	qui count if `ivg1'!=.
	local gn=r(N)
}

if `niv'<=0 & `ivgnum'==0 {
	di in red "No grid variable or number of grid points were given"
	exit 198
}

if `niv'>0 & `ivgnum'>0 {
	di in red "Only one of Niv and IVG options should be specified"
	exit 198
}

local LLB0 0
local LLB1 0
local UUB0 1
local UUB1 1
local TLB 0
local TUB 0

tempvar mm1 mm2 mm3 mm4 mmt mmt0 mmt1 miv mmtiv mmtiv1 mmtiv0
qui gen long `mm1'=0
qui gen long `mm2'=0
qui gen long `mm3'=0
qui gen long `mm4'=0
qui gen long `mmt'=0
qui gen long `mmt0'=0
qui gen long `mmt1'=0
qui gen long `miv'=0
qui gen long `mmtiv'=0
qui gen long `mmtiv1'=0
qui gen long `mmtiv0'=0

qui replace `mm1'=1 if `ix1'==`m1'
qui replace `mmt'=`mm1'

if `atnum'>1 {
		qui replace `mm2'=1 if `ix2'==`m2'
		qui replace `mmt'=`mmt'*`mm2'
		}
if `atnum'>2 {
		qui replace `mm3'=1 if `ix2'==`m3'
		qui replace `mmt'=`mmt'*`mm3'
		}
if `atnum'>3 {
		di in red `"too many covariate (maximum 3)"'
		exit 198
		}

qui replace `mmt1'=1 if `iz'==1
qui replace `mmt1'=`mmt1'*`mmt'
qui replace `mmt0'=1 if `iz'==0
qui replace `mmt0'=`mmt0'*`mmt'


qui sum `iv1'
	local ivmin=r(min)
	local ivmax=r(max)

local i 0
while `i'<=`gn'-1 {
	if `ivgnum'>=1 {
	local ivv=`ivg1'[`i']
	}
	else {
	local ivv=`ivmin'+`i'*(`ivmax'-`ivmin')/(`niv'-1)
	}
	if `"`continuous'"' !=`""' {
		qui kern2 `iz' `ix1' `ix2' `ix3' `iv1' , at(`m1' `m2' `m3' `ivv' ) /*
			*/ `epan' `biweigh' `triangl' `gauss' `rectang' /*
			*/ w1(`w1') w2(`w2') w3(`w3') w4(`w4')
		local p1=r(expect)
		local p0=1-`p1'
		qui kern2 `iy' `ix1' `ix2' `ix3' `iv1' if `iz'==1, at(`m1' `m2' `m3' `ivv') /*
			*/  `epan' `biweigh' `triangl' `gauss' `rectang' /*
			*/ w1(`w1') w2(`w2') w3(`w3') w4(`w4')
		local yh1=r(expect)
		qui kern2 `iy' `ix1' `ix2' `ix3' `iv1' if `iz'==0, at(`m1' `m2' `m3' `ivv') /*
			*/ `epan' `biweigh' `triangl' `gauss' `rectang' /*
			*/ w1(`w1') w2(`w2') w3(`w3') w4(`w4')
		local yh0=r(expect)
	}
	else {
		qui replace `miv'=1 if `iv1'==`ivv'
		qui replace `mmtiv'=`mmt'*`miv'
		qui replace `mmtiv1'=`mmt1'*`miv'
		qui replace `mmtiv0'=`mmt0'*`miv'
		qui sum `iz' [w=`mmtiv']
		local p1=r(mean)
		local p0=1-`p1'
		qui sum `iy' [w=`mmtiv1']
		local yh1=r(mean)
		qui sum `iy' [w=`mmtiv0']
		local yh0=r(mean)
		local method= "discrete"
		local kernel="none"
	}
	local zz=`yh1'*`p1'
	local LLB1=max(`LLB1',`zz')
	local zz=`yh0'*`p0'
	local LLB0=max(`LLB0',`zz')
	local zz=`yh1'*`p1'+`p0'
	local UUB1=min(`UUB1',`zz')
	local zz=`yh0'*`p0'+`p1'
	local UUB0=min(`UUB0',`zz')
	local method= "continuous"
local i=`i'+1
}
local TLB=`LLB1'-`UUB0'
local TUB=`UUB1'-`LLB0'

qui count
local n = r(N)
ret clear
ret scalar LB0 = `LLB0'
ret scalar UB0 = `UUB0'
ret scalar LB1 = `LLB1'
ret scalar UB1 = `UUB1'
ret scalar treatL = `TLB'
ret scalar treatU = `TUB'
ret scalar n = `n'
ret scalar xnum=`xnum'
ret local kernel `"`kernel'"'
ret local method `"`method'"'

global S_1=`LLB0'
global S_2=`UUB0'
global S_3=`LLB1'
global S_4=`UUB1'
global S_5=`TLB'
global S_6=`TUB'


end

