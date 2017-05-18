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

/* Custom fill cells */

use "$data_dir/clean/akiba_wide.dta", clear

foreach yvar in $sumvars {

	qui reg `yvar' lottery regret, vce(cl surveyid)
	est sto reg
	loc N = e(N)

	/* Column 1: Lottery - Control */

	est res reg

	pstar lottery, prec(2)
	estadd loc thisstat`count' = r(bstar): col1
	estadd loc thisstat`countse' = r(sestar): col1

	/* Column 2: Regret - Control */

	est res reg

	pstar regret, prec(2)
	estadd loc thisstat`count' = r(bstar): col2
	estadd loc thisstat`countse' = r(sestar): col2

	/* Column 3: Lottery - Regret */

	est res reg
	qui lincom lottery - regret
	loc b = r(estimate)
	loc se = r(se)
	loc p = r(p)

	pstar, b(`b') se(`se') p(`p') prec(2)
	estadd loc thisstat`count' = r(bstar): col3
	estadd loc thisstat`countse' = r(sestar): col3

	/* Column 4: Control mean */

	qui su `yvar' if control == 1
	estadd loc thisstat`count' = string(r(mean), "%9.2f"): col4
	estadd loc thisstat`countse' = "(" + string(r(sd), "%9.2f") + ")": col4

	/* Column 5: Observations */

	est res reg
	estadd loc thisstat`count' = `N': col5

	/* Row Labels */

	loc thisvarlabel: variable label `yvar' // Extracts label from row var
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	loc statnames "`statnames' thisstat`count' thisstat`countse'"
	loc count = `count' + 2
	loc countse = `count' + 1

}

/* Table options */

loc prehead "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$sumtitle} \label{tab:$sumpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "The first three columns report the difference of means across treatment groups with SEs in parentheses. Column 4 reports the mean of the control group with SD in parentheses. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."

esttab col* using "$tab_dir/$sumpath.tex", booktabs cells(none) nogap mtitle("\specialcell{Lottery -\\Control}" "\specialcell{Regret -\\Control}" "\specialcell{Lottery -\\Regret}" "\specialcell{Control mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress wrap replace

eststo clear

file open tex using "$tab_dir/$sumpath.tex", write append
file write tex _n "% File produced by sum-treat.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex
