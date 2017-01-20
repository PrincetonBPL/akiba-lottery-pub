*! version 1.0.0  20Mar2000 
program define gridgen, rclass
* Arie Beresteanu and Charles Manski
* Northwestern University
version 6.0

syntax newvarlist(min=1 max=4), START(string) FINISH(string) JUMP(string) 

	tokenize `varlist'
	local vnum : word count `varlist'
	local i 1
	while `i'<=`vnum' {
	local var`i'="``i''"
	local i=`i'+1
	}	

	tokenize `start'
	local snum : word count `start'
	local i 1
	while `i'<=`snum' {
	local s`i'=``i''
	local i=`i'+1
	}	

	tokenize `finish'
	local fnum : word count `finish'
	local i 1
	while `i'<=`fnum' {
	local f`i'=``i''
	local i=`i'+1
	}	

	tokenize `jump'
	local jnum : word count `jump'
	local i 1
	while `i'<=`jnum' {
	local j`i'=``i''
	local i=`i'+1
	}	

if `vnum'!=`snum' {
		di in red `"number of variables and start points should be the same"'
		exit 198
	}
if `snum'!=`fnum' {
		di in red `"number of start points and finish points should be the same"'
		exit 198
	}
if `fnum'!=`jnum' {
		di in red `"number of finish points and jump points should be the same"'
		exit 198
	}

local i 1
while `i'<=`snum' {
	if `s`i''>`f`i'' {
		di in red `"strat points should be smaller than finish points"'
		exit 198
	}
	if `j`i'' <=0 {
		di in red `"only positive jums are allowed"'
		exit 198
	}
	local i=`i'+1
}

local i 1
local Nmax 1
while `i'<=`vnum' {
	local l`i'=int((`f`i''-`s`i''+1)/`j`i'')
	local Nmax=`Nmax'*`l`i''
	local i=`i'+1
}


tempvar g1 g2 g3 g4 gg
	qui gen double `g1'=.
	qui gen double `g2'=.
	qui gen double `g3'=.
	qui gen double `g4'=.
	qui gen double `gg'=1


qui sum `gg'
local Num=r(N)

if `Num'<`Nmax' {
	di in red "The grid is too big"
	exit 198
}

local i 1
while `i'<=4 {
	if `i'<=`vnum' { 
		local x`i'=`s`i''
		local z`i'=`s`i''
	}
	if `i'>`vnum' {
		local x`i'=1
		local z`i'=1
		local s`i'=1
		local f`i'=1
		local j`i'=1
	}
	local i=`i'+1
}


local n 1

while `x1'<=`f1' {
	while `x2'<=`f2' {
		while `x3'<=`f3' {
			while `x4' <=`f4' {
				qui replace `g1'=`x1' in `n'
				qui replace `g2'=`x2' in `n'
				qui replace `g3'=`x3' in `n'
				qui replace `g4'=`x4' in `n'
				local x4=`x4'+`j4'
				local n=`n'+1
			}
			local x4=`s4'
			local x3=`x3'+`j3'
		}
		local x3=`s3'	
		local x2=`x2'+`j2'
	}
	local x2=`s2'
	local x1=`x1'+`j1'

}


local i 1
while `i'<=`vnum' {
	rename `g`i'' `var`i''
	local i=`i'+1
}
local n=`n'-1
di "created a grid with `vnum' variables and `n' observations"
end
