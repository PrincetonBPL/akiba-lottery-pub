** Title: sum-normdiff
** Author: Justin Abraham
** Desc: Outputs normalized differences as in Imbens Rubin (2015) for a set of covariates
** Input: UMIP Master.dta
** Output: sum-normdiff

/* Create empty table */

clear all
eststo clear
estimates drop _all

loc columns = 3 // Change number of columns

set obs 10
gen x = 1
gen y = 1

forval i = 1/`columns' {
	qui eststo col`i': reg x y
}

loc count = 1

loc statnames "" // Added scalars to be filled
loc varlabels "" // Labels for row vars to be filled

use "$data_dir/clean/akiba_wide.dta", clear

/* Variable labels */

foreach yvar in $sumvars {

	loc thisvarlabel: var la `yvar'
	loc varlabels "`varlabels' "`thisvarlabel'" "

}

/* Normalized differences */

normdiff $sumvars if regret == 0, treat(lottery)
mat def V1 = r(ndiffs)

normdiff $sumvars if lottery == 0, treat(regret)
mat def V2 = r(ndiffs)

normdiff $sumvars if control == 0, treat(regret)
mat def V3 = r(ndiffs)

/* Custom fill cells */

loc varcount: word count $sumvars

forval i = 1/`varcount' {

	forval j = 1/3 {

		loc res: di %9.3f = V`j'[`i', 1]
		estadd loc thisstat`i' = "`res'": col`j'

	}

	loc statnames "`statnames' thisstat`i'"

}

/* Table options */

loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$sumtitle} \label{tab:$sumpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "This table reports normalized differences between treatment groups for each row variable. The normalized difference is the difference in group means scaled by the square root of the average of the within-group variances and is a scale-invariant way of comparing the distribution of variables across treatment groups (Imbens and Rubin, 2015)."

esttab col* using "$tab_dir/$sumpath.tex", booktabs cells(none) nogap mtitle("\specialcell{PLS-N $-$\\Control}" "\specialcell{PLS-F $-$\\Control}" "\specialcell{PLS-F $-$\\PLS-N}") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress wrap replace

eststo clear

file open tex using "$tab_dir/$sumpath.tex", write append
file write tex _n "% File produced by sum-normdiff with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex
