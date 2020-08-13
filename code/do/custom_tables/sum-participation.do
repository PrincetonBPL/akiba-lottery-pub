** Title: sum-participation.do
** Author: Justin Abraham
** Desc: Outputs summary statistics by participation
** Input: UMIP Master.dta
** Output: sum-participation.tex

/* Create empty table */

clear all
eststo clear
estimates drop _all

loc columns = 3 //Change number of columns

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

	qui reg `yvar' endline, vce(cl surveyid)
	loc N = e(N)

	/* Column 1: Completed - attrited */

	sigstar endline, prec(2) aer
	estadd loc thisstat`count' = "`r(bstar)'": col1
	estadd loc thisstat`countse' = "`r(sestar)'": col1

	/* Column 2: Completed Mean */

	qui sum `yvar' if endline == 1
	estadd loc thisstat`count' = string(r(mean), "%9.2f"): col2
	estadd loc thisstat`countse' = "(" + string(r(sd), "%9.2f") + ")": col2

	/* Column 3: Observations */

	estadd loc thisstat`count' = `N': col3

	/* Row Labels */

	loc thisvarlabel: variable label `yvar' // Extracts label from row var
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	loc statnames "`statnames' thisstat`count' thisstat`countse'"
	loc count = `count' + 2
	loc countse = `count' + 1

}

/* Table options */

loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$sumtitle} \label{tab:$sumpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "Column 1 reports the difference of means between participants who completed endline and those who attrited. Standard errors are in parentheses. Column 2 reports the mean among participants at endline with SD in parentheses."

esttab col* using "$tab_dir/$sumpath.tex", booktabs cells(none) nogap mtitle("\specialcell{Completed -\\attrited}" "\specialcell{Mean (SD)\\of completed}" "Obs.") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress replace

eststo clear

file open tex using "$tab_dir/$sumpath.tex", write append
file write tex _n "% File produced by sum-participation.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex
