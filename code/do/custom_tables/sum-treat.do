** Title: sum-treat.do
** Author: Justin Abraham
** Desc: Outputs baseline summary statistics conditional on treatment group
** Input: UMIP Master.dta
** Output: sum-treat.do

/* Create empty table */

clear all
eststo clear
estimates drop _all

loc columns = 5 //Change number of columns

set obs 10
gen x = 1
gen y = 1

forval i = 1/`columns' {
	qui eststo col`i': reg x y
}

loc count = 1
loc countse = `count' + 1

loc statnames "" // Added scalars to be filled
loc varlabels "" // Labels for row vars to be filled
loc surlist ""
loc surtest ""

/* SUR */

use "$data_dir/clean/akiba_wide.dta", clear

foreach yvar in $sumvars {

	qui reg `yvar' lottery regret
	est sto e_`yvar'
	loc surlist "`surlist' e_`yvar'"

}

qui suest `surlist', vce(cl surveyid)
est sto sur

/* Custom fill cells */

est restore sur

foreach yvar in $sumvars {

	qui test [e_`yvar'_mean]lottery = 0
	loc p = `r(p)'
	loc b = _b[e_`yvar'_mean:lottery]
	loc se = _se[e_`yvar'_mean:lottery]

	sigstar, b(`b') se(`se') p(`p') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col1
	estadd loc thisstat`countse' = "`r(sestar)'": col1

	qui test [e_`yvar'_mean]regret = 0
	loc p = `r(p)'
	loc b = _b[e_`yvar'_mean:regret]
	loc se = _se[e_`yvar'_mean:regret]

	sigstar, b(`b') se(`se') p(`p') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col2
	estadd loc thisstat`countse' = "`r(sestar)'": col2

	qui lincom [e_`yvar'_mean]regret - [e_`yvar'_mean]lottery
	loc b = `r(estimate)'
	loc se = `r(se)'

	qui test [e_`yvar'_mean]regret - [e_`yvar'_mean]lottery = 0
	loc p = `r(p)'

	sigstar, b(`b') se(`se') p(`p') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col3
	estadd loc thisstat`countse' = "`r(sestar)'": col3

	qui su `yvar' if control == 1
	estadd loc thisstat`count' = string(r(mean), "%9.2f"): col4
	estadd loc thisstat`countse' = "(" + string(r(sd), "%9.2f") + ")": col4

	qui su `yvar' if ~mi(lottery, regret)
	loc N = e(N)
	estadd loc thisstat`count' = `N': col5

	loc surtest "`surtest' ([e_`yvar'_mean]regret = [e_`yvar'_mean]lottery = 0)"

	/* Row Labels */

	loc thisvarlabel: variable label `yvar' // Extracts label from row var
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	loc statnames "`statnames' thisstat`count' thisstat`countse'"
	loc count = `count' + 2
	loc countse = `count' + 1

}

/* Joint test */

est restore sur

testparm lottery
sigstar, p(`r(p)') pstar prec(2)
estadd local sur_p "`r(pstar)'": col1

testparm regret
sigstar, p(`r(p)') pstar prec(2)
estadd local sur_p "`r(pstar)'": col2

test `surtest'
sigstar, p(`r(p)') pstar prec(2)
estadd local sur_p "`r(pstar)'": col3

loc statnames "`statnames' sur_p"
loc varlabels "`varlabels' "\midrule Joint test \emph{p}-value" "

/* Table options */

loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$sumtitle} \label{tab:$sumpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "The first three columns report the difference of means across treatment groups with standard errors in parentheses. Column 4 reports the mean of the control group with SD in parentheses. The bottom row reports the \(p\)-value of a joint test of significance for each hypothesis. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."

esttab col* using "$tab_dir/$sumpath.tex", booktabs cells(none) nogap mtitle("\specialcell{PLS-N $-$\\Control}" "\specialcell{PLS-F $-$\\Control}" "\specialcell{PLS-F $-$\\PLS-N}" "\specialcell{Control mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress wrap replace

eststo clear

file open tex using "$tab_dir/$sumpath.tex", write append
file write tex _n "% File produced by sum-treat.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex
