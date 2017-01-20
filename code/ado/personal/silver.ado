*! version 1.0.0   20Mar2000 
program define silver, rclass
* Arie Beresteanu and Charles Manski
* Northwestern University
version 6.0

	syntax varlist(min=1)
	
	tokenize `varlist'
	local vnum : word count `varlist'
	local i 1

	while `i'<=`vnum' {
		local x`i' ``i''
		local i=`i'+1
	}	


	local i 1
	while `i'<=`vnum' {
		qui sum `x`i'',detail
		local k=(r(p75)-r(p25))/1.349
		local s`i'=0.9*min(sqrt(r(Var)),`k')*r(N)^(-0.2)
		if `s`i''==0 {
			local s`i'=0.9*sqrt(r(Var))*r(N)^(-0.2)
		}
		di "Silverman rule of thumb for `x`i'' is `s`i''"
		local i=`i'+1
	}

	/* double save in S_# and r() */
	ret clear
	local i 1
	while `i'<=`vnum' {
		ret scalar w`i' = `s`i''
		global S_`i' = `s`i''
		local i=`i'+1
	}
	
end	
