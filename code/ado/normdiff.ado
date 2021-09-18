program define normdiff, rclass
syntax varlist(min = 1) [if] [in], treat(varname) [ABSolute]

	tempname R
	tempvar touse tag
	mark `touse' `if' `in'

	qui ta `treat' if `touse', gen(`tag')
	assert `r(r)' == 2

	qui replace `tag'1 = 0 if `touse' == 0
	qui replace `tag'2 = 0 if `touse' == 0

	mata {

		varlist = st_local("varlist")
		abs = st_local("absolute")
		Ac = st_data(., (varlist), "`tag'1")
		At = st_data(., (varlist), "`tag'2")

		num = mean(At) :- mean(Ac)
		den = ((diagonal(variance(At)) :+ diagonal(variance(Ac))) :/ 2):^(0.5)
		ND = num' :/ den

		if (abs != "") ND = abs(ND)

		st_rclear()
		st_matrix("`R'", ND)

	}

	drop `tag'*

	mat rown `R' = `varlist'
	mat list `R'

	ret mat ndiffs = `R'

end