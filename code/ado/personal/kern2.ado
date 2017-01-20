*! version 1.0.0   20Mar2000 
program define kern2, rclass
* Arie Beresteanu and Charles Manski
* Northwestern University
version 6.0

	syntax varlist(min=2 max=5 ) [if] [in] [fw aw] , /*
		*/ AT(string) [/*
		*/ W1(real 0.0) W2(real 0.0) W3(real 0.0) W4(real 0.0) W5(real 0.0) /*
		*/ BIweight  EPan GAUss RECtangle UNIform /*
		*/ TRIangle  * ]
	
	tokenize `varlist'
	local xnum : word count `varlist'
	local xnum=`xnum'-1
	local iy `1'
	local i 1
	while `i'<=`xnum' {
		local j=`i'+1
		local ix`i' ``j''
		local i=`i'+1
	}	
	
	local gen `"`generate'"'

	local kflag = ( (`"`epan'"' != `""') + (`"`biweigh'"' != `""') + /*
			*/ (`"`triangle'"' != `""') + (`"`gauss'"' != `""') + /*
			*/ (`"`uniform'"' != `""')) 
	if `kflag' > 1 {
		di in red `"only one kernel may be specified"'
		exit 198
	}

	if `"`biweigh'"'       != `""' { local kernel=`"Biweight"'     }
	else if `"`triangle'"'  != `""' { local kernel=`"Triangle"'     }
	else if `"`gauss'"'    != `""' { local kernel=`"Gaussian"'     }
	else if `"`rectang'"'  != `""' { local kernel=`"Rectangular"'  }
	else if `"`uniform'"'  != `""' { local kernel=`"Uniform"'  }
	else                       { local kernel=`"Epanechnikov"' }

	marksample use
	qui count if `use'
	local nnobs = r(N)
	if r(N)==0 { error 2000 } 

		
	tempvar d dd z f r h point
	qui gen double `f'=.
	qui gen double `r'=.
	qui gen double `z'=.
	qui gen double `point'=0
	

local h=.
local d=.
local dd=.
local m=.

	tokenize `at'
	local atnum : word count `at'
	local i 1
	while `i'<=`atnum' {
	local m`i'=``i''
	local i=`i'+1
	}	

	if `atnum'!=`xnum' {
			di in red `"number of covariates don't match length of grid point"'
			exit 198
				}

			

	local i 1
	while `i'<=`xnum' {
		quietly summ `ix`i''  if `use', detail
		local nmean`i' = r(mean)
		local nsig`i' = r(Var)
		tempname wwidth`i'
		scalar `wwidth`i'' = `w`i''
		if `wwidth`i'' <= 0.0 { 
			scalar `wwidth`i'' = min( sqrt(r(Var)), (r(p75)-r(p25))/1.349)
			scalar `wwidth`i'' = 0.9*`wwidth`i''/(r(N)^.20)
		}
	
		tempname delta`i' wid`i'
		scalar `delta`i'' = (r(max)-r(min)+2*`wwidth`i'')/(`n'-1)
		scalar `wid`i''   = r(N) * `wwidth`i''
		local i=`i'+1
	}

	local i 1
	if `"`biweigh'"' != `""' {
		local con1 = .9375
		
			local j 1
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j'')/`wwidth`j'')^2  
			local j=`j'+1
			}
			qui replace `point'=`point'^0.5 if `point'!=0 & `point'!=.
			qui replace `z'=`point' /*
				*/ if `use' & `use'
			qui replace `f'=`con1'*(1-(`z')^2)^2 /* 
				*/ if abs(round(`z',1e-8))<1
			qui replace `r'=`iy'*`con1'*(1-(`z')^2)^2 /*
				*/ if abs(round(`z',1e-8))<1
			qui summ `f' if `f'!=.
			local d=(r(mean)*r(N))
			qui summ `r' if `r'!=.
			local dd=(r(mean)*r(N)) 
			local h=`dd'/`d'  
		
	}
	
	else if `"`triangle'"' != `""' {
			local j 1
			qui replace `point'=0
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j'')/`wwidth`j'')^2 
			local j=`j'+1
			}
			qui replace `point'=`point'^0.5 if `point'!=0  & `point'!=.
			qui replace `z'=`point'  if `use'
			qui replace `f'= (1-abs(`z')) /*
				*/ if abs(round(`z',1e-8))<1
			qui replace `r'=`iy'*(1-abs(`z')) /*
				*/ if abs(round(`z',1e-8))<1
			qui summ `f' if `f'!=.
			local d=(r(mean)*r(N))
			qui summ `r' if `r'!=.
			local dd=(r(mean)*r(N))
			local h=`dd'/`d' in `i'
		
	}
	else if `"`gauss'"' != `""' {
		local con1 = sqrt(2*_pi)
			local j 1
			qui replace `point'=0
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j'')/`wwidth`j'')^2  
			local j=`j'+1
			}
			qui replace `point'=`point'^0.5 if `point'!=0  & `point'!=.
			qui replace `z'=`point' if `use'
			qui replace `f'= exp(-0.5*((`z')^2))/`con1'
			qui replace `r'= `iy'*exp(-0.5*((`z')^2))/`con1'
			qui summ `f' 
			local d=(r(mean)*r(N)) in `i'
			qui summ `r' 
			local dd=(r(mean)*r(N)) in `i'
			local h=`dd'/`d' in `i'
	}
	else if `"`rectang'"' != `""' {
			local j 1
			qui replace `point'=0
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j'')/`wwidth`j'')^2  
			local j=`j'+1
			}
			qui replace `point'=`point'^0.5 if `point'!=0  & `point'!=.
			qui replace `z'=`point'  if `use'
			qui replace `f'= 0.5 if abs(round(`z',1e-8))<1
			qui replace `r'=`iy'*0.5 if abs(round(`z',1e-8))<1
			qui summ `f' if `f'!=.
			local d=r(mean)
			qui summ `r' if `r'!=.
			local dd=r(mean)
			local h=`dd'/`d' in `i'
	}
	else {
		local con1 = 3/4
		local con2 = sqrt(5)
			local j 1
			qui replace `point'=0
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j'')/`wwidth`j'')^2  
			local j=`j'+1
			}
			qui replace `point'=`point'^0.5 if `point'!=0  & `point'!=.
			qui replace `z'=`point'  if `use'
			qui replace `f'= `con1'*(1-((`z')^2)) /* 
				*/  if abs(round(`z',1e-8))<=1
			qui replace `r'= `iy'*`con1'*(1-((`z')^2)) /* 
				*/  if abs(round(`z',1e-8))<=1
			qui summ `f' if `f'!=.
			local d=r(mean)
			qui summ `r' if `r'!=.
			local dd=r(mean)
			local h=`dd'/`d' in `i'
	}

	/* double save in S_# and r() */
	ret clear
	ret local kernel `"`kernel'"'
	ret scalar xnum = `xnum'
	ret scalar expect = `h'
	ret scalar xdens = `d'/`nnobs'
	global S_1 = `h'
	global S_2 = `d'
	global S_3   `"`kernel'"'
	global S_4 = `xnum'
	
end	
