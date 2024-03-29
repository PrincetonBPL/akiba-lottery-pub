** Title: sum-unconditional.do
** Author: Justin Abraham
** Desc: Outputs baseline summary statistics (Mean SD Med Min Max N)
** Input: UMIP Master.dta
** Output: sum-unconditional.do

/* Create empty table */

clear all
eststo clear
estimates drop _all

loc columns = 6 //Change number of columns

set obs 10
gen x = 1
gen y = 1

forval i = 1/`columns' {
	qui eststo col`i': reg x y
}

loc count = 1

loc statnames "" // Added scalars to be filled
loc varlabels "" // Labels for row vars to be filled

/* Custom fill cells */

use "$data_dir/clean/akiba_wide.dta", clear

foreach yvar in $sumvars {

	qui sum `yvar', d
	loc mean = `r(mean)'
	loc sd = `r(sd)'
	loc med = `r(p50)'
	loc min = `r(min)'
	loc max = `r(max)'
	loc N = `r(N)'

	estadd loc thisstat`count' = string(`mean', "%9.2f"): col1
	estadd loc thisstat`count' = string(`sd', "%9.2f"): col2
	estadd loc thisstat`count' = string(`med', "%9.2f"): col3
	estadd loc thisstat`count' = string(`min', "%9.2f"): col4
	estadd loc thisstat`count' = string(`max', "%9.2f"): col5
	estadd loc thisstat`count' = `N': col6

	/* Row Labels */

	loc thisvarlabel: variable label `yvar' // Extracts label from row var
	local varlabels "`varlabels' "`thisvarlabel'" "
	loc statnames "`statnames' thisstat`count'"
	loc count = `count' + 2

}

/* Table options */

loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$sumtitle} \label{tab:$sumpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "This table reports unconditional summary statistics for each row variable."

esttab col* using "$tab_dir/$sumpath.tex", booktabs cells(none) nonum nogap mtitle("Mean" "SD" "Median" "Min." "Max." "Obs.") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress wrap replace

eststo clear

file open tex using "$tab_dir/$sumpath.tex", write append
file write tex _n "% File produced by sum-unconditional.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex
