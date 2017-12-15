** Title: reg-main.do
** Author: Justin Abraham
** Desc: Outputs minimal regression tables
** Input: UMIP Master.dta
** Output: reg-main.tex

/* Create empty table */

preserve

clear
eststo clear
estimates drop _all

loc columns = 5

set obs 10
gen x = 1
gen y = 1

forval i = 1/`columns' {
	qui eststo col`i': reg x y
}

loc count = 1				// Cell first line
loc countse = `count' + 1	// Cell second line

loc statnames "" 			// Added scalars to be filled
loc varlabels "" 			// Labels for row vars to be filled

loc surlist ""				// List of stored estimates for SUR

restore

/* SUR */

foreach yvar in $regvars {

	qui reg `yvar' lottery regret
	est store o_`yvar'
	loc surlist "`surlist' o_`yvar'"

	loc `yvar'_N = e(N)

}

suest `surlist', vce(cl surveyid)
est store sur

/* Hypothesis tests */

loc varindex = 1
loc varlist "$regvars"
loc length: list sizeof varlist

forval i = 1/3 {

	mat def B`i' = J(`length', 1, .)
	mat def SE`i' = J(`length', 1, .)
	mat def P`i' = J(`length', 1, .)

}

foreach yvar in $regvars {

	loc H1 = "[o_`yvar'_mean]lottery"
	loc H2 = "[o_`yvar'_mean]regret"
	loc H3 = "[o_`yvar'_mean]regret - [o_`yvar'_mean]lottery"

 	est restore sur

	forval i = 1/3 {

		qui lincom `H`i''
		mat def B`i'[`varindex', 1] = r(estimate)
		mat def SE`i'[`varindex', 1] = r(se)

		qui test `H`i'' = 0
		mat def P`i'[`varindex', 1] = r(p)

	}

	loc ++varindex

}

/* Fill table cells */

loc varindex = 1

foreach yvar in $regvars {

	forval i = 1/3 {

		loc b = B`i'[`varindex', 1]
		loc se = SE`i'[`varindex', 1]
		loc p = P`i'[`varindex', 1]

		pstar, b(`b') se(`se') p(`p') prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col`i'
		estadd loc thisstat`countse' = "`r(sestar)'": col`i'

	}

	/* Column 4: Control Mean */

	qui sum `yvar' if control == 1
	estadd loc thisstat`count' = string(`r(mean)', "%9.2f"): col4
	estadd loc thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")": col4

	/* Column 5: N */

	estadd loc thisstat`count' = ``yvar'_N': col5

	/* Row Labels */

	loc thisvarlabel: variable label `yvar'
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	loc statnames "`statnames' thisstat`count' thisstat`countse'"
	loc count = `count' + 2
	loc countse = `count' + 1
	loc ++varindex

}

/* Table options */

loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$regtitle} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc prehead_n "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \label{tab:$regpath} \maxsizebox*{0.90\textwidth}{0.90\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "\emph{Notes:} Columns 1 - 3 report OLS estimates of the treatment effect. Standard errors are in parentheses, Observations are at the individual level. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."

esttab col* using "$tab_dir/$regpath.tex", booktabs cells(none) nogap mgroups("Effect estimates" "Sample", pattern(1 0 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("Lottery" "Regret" "\specialcell{Regret - \\Lottery}" "\specialcell{Control Mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress replace
esttab col* using "$tab_dir/$regpath-n.tex", booktabs cells(none) nogap mgroups("Effect estimates" "Sample", pattern(1 0 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("Lottery" "Regret" "\specialcell{Regret - \\Lottery}" "\specialcell{Control Mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) prehead("`prehead_n'") postfoot("`postfoot'") compress replace

eststo clear

file open tex using "$tab_dir/$regpath.tex", write append
file write tex _n "% File produced by reg-main.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex
