program define normdiff, rclass
syntax varlist(min = 1) [if] [in], treat(varname)

tempvar touse tag
mark `touse' `if' `in'

qui ta `treat' if `touse', gen(`tag')
assert `r(r)' == 2

qui replace `tag'1 = 0 if `touse' == 0
qui replace `tag'2 = 0 if `touse' == 0

mata {

	varlist = st_local("varlist")
	Ac = st_data(., (varlist), "`tag'1")
	At = st_data(., (varlist), "`tag'2")

	num = mean(At) :- mean(Ac)
	den = ((diagonal(variance(At)) :+ diagonal(variance(Ac))) :/ 2):^(0.5)

	ND = num :/ den'
	st_matrix("r(diffs)", ND)

}

mat list r(diffs)

end