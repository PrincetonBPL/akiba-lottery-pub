** Title: reg-mde.do
** Author: Justin Abraham
** Desc: Outputs MDEs for outcomes of interest
** Input: UMIP Master.dta
** Output: reg-mde.tex

/* Create empty table */

preserve

clear
eststo clear
estimates drop _all

loc columns = 4

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

restore

/* Custom fill cells */

loc t1 = 1.96
loc t2 = 0.84

foreach yvar in $regvars {

 	qui reg `yvar' lottery regret, vce(cl surveyid)
	loc `yvar'_N = e(N)

	/* Column 1: Lottery */

	loc mde = (`t1' + `t2') * _se[lottery]
	estadd loc thisstat`count' = string(`mde', "%9.2f"): col1

	/* Column 2: Regret */

	/* loc mde = (`t1' + `t2') * _se[regret]
	estadd loc thisstat`count' = string(`mde', "%9.2f"): col2 */

	/* Column 3: Lottery vs Regret */

	qui reg `yvar' regret if treated, vce(cl surveyid)

	loc mde = (`t1' + `t2') * _se[regret]
	estadd loc thisstat`count' = string(`mde', "%9.2f"): col2

	/* Column 4: Control Mean */

	qui sum `yvar' if control
	estadd loc thisstat`count' = string(`r(mean)', "%9.2f"): col3
	estadd loc thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")": col3

	/* Column 5: N */

	estadd loc thisstat`count' = ``yvar'_N': col4

	/* Row Labels */

	loc thisvarlabel: variable label `yvar' // Extracts label from row var
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	loc statnames "`statnames' thisstat`count' thisstat`countse'"
	loc count = `count' + 2
	loc countse = `count' + 1

}

/* Table options */

loc prehead "\begin{table}[ht]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$regtitle} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc prehead_n "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "\emph{Notes:} Columns 1--2 report the minimum detectable effect sizes of the lottery treatment compared to control and the regret treatment against the lottery, respectively, with \(\alpha\) = 0.05 and 0.8 power. Columns 3--4 report the control group means and SDs and size of the analytic sample."

esttab col* using "$tab_dir/$regpath.tex", booktabs cells(none) nogap mtitle("No Feedback" "\specialcell{PLS-\\No Feedback}" "\specialcell{Control Mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress replace
esttab col* using "$tab_dir/$regpath-n.tex", booktabs cells(none) nogap mtitle("No Feedback" "\specialcell{PLS-\\No Feedback}" "\specialcell{Control Mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) prehead("`prehead_n'") postfoot("`postfoot'") compress replace

eststo clear

file open tex using "$tab_dir/$regpth.tex", write append
file write tex _n "% File produced by reg-mde.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex
