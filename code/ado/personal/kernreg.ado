*! version 1.0.0   20Mar2000 
program define kernreg, rclass
* Arie Beresteanu and Charles Manski
* Northwestern University
version 6.0

	syntax varlist(min=2 max=5 ) [if] [in] [fw aw] , /*
		*/ Generate(string)  AT(string) [/*
		*/ W1(real 0.0) W2(real 0.0) W3(real 0.0) W4(real 0.0) /*
		*/ BIweight COSine EPan GAUss RECtangle PARzen /*
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
			*/ (`"`triangl'"' != `""') + (`"`gauss'"' != `""') + /*
			*/ (`"`rectang'"' != `""')  + (`"`parzen'"' != `""'))
	if `kflag' > 1 {
		di in red `"only one kernel may be specified"'
		exit 198
	}

	if `"`biweigh'"'       != `""' { local kernel=`"Biweight"'     }
	else if `"`cosine'"'   != `""' { local kernel=`"Cosine"'       }
	else if `"`triangl'"'  != `""' { local kernel=`"Triangle"'     }
	else if `"`gauss'"'    != `""' { local kernel=`"Gaussian"'     }
	else if `"`rectang'"'  != `""' { local kernel=`"Rectangular"'  }
	else if `"`parzen'"'   != `""' { local kernel=`"Parzen"'       }
	else                       { local kernel=`"Epanechnikov"' }

	marksample use
	qui count if `use'
	local nnobs = r(N)
	if r(N)==0 { error 2000 } 

	tokenize `gen'
	local wc : word count `gen'
	if `wc' { 
		if `wc' == 1  {
			capture confirm new var ``1''
			local yl  "`1'"
		}
		else {
			 error 198
		}
	}
	else {
		
			di in bl /*
*/ `"did not request results be saved; no action taken"'
			exit
	}
		
	tempvar d dd m1 m2 m3 m4  z f r h point
	qui gen long  `d'=.
	qui gen long  `dd'=.
	qui gen double `f'=.
	qui gen double `r'=.
	qui gen double `z'=.
	qui gen double `point'=0
	qui gen double `m1'=.
	qui gen double `m2'=.
	qui gen double `m3'=.
	qui gen double `m4'=.
	qui gen double `h'=.

		
	tokenize `at'
	local atnum : word count `at'
	local i 1
	while `i'<=`atnum' {
	qui replace `m`i''=``i''
	local i=`i'+1
	}	
	qui count if `m1'!=. 
	local n = r(N)
		

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
		while `i'<=`n' {
			local j 1
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j''[`i'])/`wwidth`j'')^2  /*
				*/ in 1/`n'
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
			qui replace `d'=(r(mean)*r(N))
			qui summ `r' if `r'!=.
			qui replace `dd'=(r(mean)*r(N)) 
			qui replace `h'=`dd'/`d' in `i' 
			qui replace `f'=.
			qui replace `r'=.
			qui replace `point'=0
			local i = `i'+1
		}
		qui replace `h'=0 if `h'==. in 1/`n'
	}
	else if `"`cosine'"' != `""' {
		while `i'<=`n' {
			local j 1
			qui replace `point'=0
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j''[`i'])/`wwidth`j'')^2  
			local j=`j'+1
			}
			qui replace `point'=`point'^0.5 if `point'!=0  & `point'!=.
			qui replace `z'=`point' /*
				*/ if `use' & `use'
			qui replace `f'= (1+cos(2*_pi*`z')) /*
				*/ if abs(round(`z',1e-8))<0.5
			qui summ `f' if `f'!=.
			qui replace `d'=(r(mean)*r(N))/`wid' in `i'
			qui replace `f'=.
			local i = `i'+1
		}
		qui replace `d'=0 if `d'==. in 1/`n'
	}
	else if `"`triangl'"' != `""' {
		while `i'<=`n' {
			local j 1
			qui replace `point'=0
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j''[`i'])/`wwidth`j'')^2 in 
			local j=`j'+1
			}
			qui replace `point'=`point'^0.5 if `point'!=0  & `point'!=.
			qui replace `z'=`point'  if `use'
			qui replace `f'= (1-abs(`z')) /*
				*/ if abs(round(`z',1e-8))<1
			qui replace `r'=`iy'*(1-abs(`z')) /*
				*/ if abs(round(`z',1e-8))<1
			qui summ `f' if `f'!=.
			qui replace `d'=(r(mean)*r(N))
			qui summ `r' if `r'!=.
			qui replace `dd'=(r(mean)*r(N))
			qui replace `h'=`dd'/`d' in `i'
			qui replace `f'=.
			qui replace `r'=.
			local i = `i'+1
		}
		qui replace `h'=0 if `h'==. in 1/`n'
	}
	else if `"`parzen'"' != `""' {
		local con1 = 4/3
		local con2 = 2*`con1'
		while `i'<=`n' {
			local j 1
			qui replace `point'=0
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j''[`i'])/`wwidth`j'')^2  
			local j=`j'+1
			}
			qui replace `point'=`point'^0.5 if `point'!=0  & `point'!=.
			qui replace `z'=`point'  if `use'
			qui replace `f'= `con1'-8*(`z')^2+8*abs(`z')^3 /*
				*/ if abs(round(`z',1e-8))<=.5
			qui replace `f'= `con2'*(1-abs(`z'))^3       /*
				*/ if abs(round(`z',1e-8))>.5 & /*
				*/ abs(round(`z',1e-8))<1
			qui summ `f' if `f'!=.
			qui replace `d'=(r(mean)*r(N)) in `i'
			qui replace `f'=.
			local i = `i'+1
		}
		qui replace `d'=0 if `d'==. in 1/`n'
	}
	else if `"`gauss'"' != `""' {
		local con1 = sqrt(2*_pi)
		while `i'<=`n' {
			local j 1
			qui replace `point'=0
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j''[`i'])/`wwidth`j'')^2  
			local j=`j'+1
			}
			qui replace `point'=`point'^0.5 if `point'!=0  & `point'!=.
			qui replace `z'=`point' if `use'
			qui replace `f'= exp(-0.5*((`z')^2))/`con1'
			qui replace `r'= `iy'*exp(-0.5*((`z')^2))/`con1'
			qui summ `f' 
			qui replace `d'=(r(mean)*r(N)) in `i'
			qui summ `r' 
			qui replace `dd'=(r(mean)*r(N)) in `i'
			qui replace `h'=`dd'/`d' in `i'
			qui replace `f'=.
			qui replace `r'=.
			local i = `i'+1
		}
		qui replace `d'=0 if `d'==. in 1/`n'
	}
	else if `"`rectang'"' != `""' {
		while `i'<=`n' {
			local j 1
			qui replace `point'=0
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j''[`i'])/`wwidth`j'')^2  
			local j=`j'+1
			}
			qui replace `point'=`point'^0.5 if `point'!=0  & `point'!=.
			qui replace `z'=`point'  if `use'
			qui replace `f'= 0.5 if abs(round(`z',1e-8))<1
			qui replace `r'=`iy'*0.5 if abs(round(`z',1e-8))<1
			qui summ `f' if `f'!=.
			qui replace `d'=(r(mean)*r(N)) in `i'
			qui summ `r' if `r'!=.
			qui replace `dd'=(r(mean)*r(N)) in `i'
			qui replace `h'=`dd'/`d' in `i'
			qui replace `f'=.
			qui replace `r'=.
			local i = `i'+1
		}
		qui replace `d'=0 if `d'==. in 1/`n'
	}
	else {
		local con1 = 3/4
		local con2 = sqrt(5)
		while `i'<=`n' {
			local j 1
			qui replace `point'=0
			while `j'<=`xnum' {
			qui replace `point'=`point'+((`ix`j''-`m`j''[`i'])/`wwidth`j'')^2  
			local j=`j'+1
			}
			qui replace `point'=`point'^0.5 if `point'!=0  & `point'!=.
			qui replace `z'=`point'  if `use'
			qui replace `f'= `con1'*(1-((`z')^2)) /* 
				*/  if abs(round(`z',1e-8))<=1
			qui replace `r'= `iy'*`con1'*(1-((`z')^2)) /* 
				*/  if abs(round(`z',1e-8))<=1
			qui summ `f' if `f'!=.
			qui replace `d'=(r(mean)*r(N))
			qui summ `r' if `r'!=.
			qui replace `dd'=(r(mean)*r(N))
			qui replace `h'=`dd'/`d' in `i'
			qui replace `f'=.
			qui replace `r'=.
			local i = `i'+1
		}
		qui replace `h'=0 if `h'==. in 1/`n'
	}

	
	
	qui summ `h' in 1/`n'
	local scale = 1/(`n'*r(mean))

	/* double save in S_# and r() */
	ret clear
	ret local kernel `"`kernel'"'
	ret scalar width1 = `wwidth1'
	ret scalar n = `n'           /* (sic) */
	ret scalar xnum = `xnum'
	global S_1   `"`kernel'"'
	global S_3 = `wwidth1'
	global S_2 = `n'
	global S_4 = `xnum'
	global S_5 = `h'
	label var `h' `"Expectation "' 
capture confirm new variable `yl'
if _rc==110 {
	qui replace `yl'=`h'
}
else {
	qui gen `yl'=`h'
}
end	
