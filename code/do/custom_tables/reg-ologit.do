** Title: reg-ologit.do
** Author: Justin Abraham
** Desc: Outputs multinomial logit estimates by relative risk ratios
** Input: UMIP Master.dta
** Output: reg-ologit.tex

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

foreach yvar in $regvars {

	ologit `yvar' i.treatmentgroup, vce(cl surveyid)
	loc obs = e(N)

	/* Column 1 */

	lincom _b[2.treatmentgroup]

		loc b = r(estimate)
		loc se = r(se)
		loc p = r(p)

	sigstar, b(`b') se(`se') p(`p') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col1
	estadd loc thisstat`countse' = "`r(sestar)'": col1

	/* Column 2 */

	lincom _b[3.treatmentgroup]

		loc b = r(estimate)
		loc se = r(se)
		loc p = r(p)

	sigstar, b(`b') se(`se') p(`p') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col2
	estadd loc thisstat`countse' = "`r(sestar)'": col2

	/* Column 3 */

	lincom _b[:3.treatmentgroup] - _b[:2.treatmentgroup]

		loc b = r(estimate)
		loc se = r(se)
		loc p = r(p)

	sigstar, b(`b') se(`se') p(`p') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col3
	estadd loc thisstat`countse' = "`r(sestar)'": col3

	/* Column 4: N */

	estadd loc thisstat`count' = `obs': col4


	loc thisvarlabel: var la `yvar'
	loc varlabels "`varlabels' "`thisvarlabel'" " " "
	loc statnames "`statnames' thisstat`count' thisstat`countse'"
	loc count = `count' + 2
	loc countse = `count' + 1				

}

/* Table options */

loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$regtitle} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc prehead_n "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "\emph{Notes:} This table reports estimates from a ordered logit regression of the categorial response on treatment assigment. Each row corresponds to an outcome variable. Columns 1-2 reports the treatment effect in log-odds compared to the control group. Column 3 reports the difference between the two PLS treatments. Standard errors are in parentheses. Column 4 reports the number of observations in the analytic sample. Observations are at the individual level. Standard errors are clustered at the individual level. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."

esttab col* using "$tab_dir/$regpath.tex", booktabs cells(none) nogap mgroups("Log odds" "Sample", pattern(1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("PLS-N" "PLS-F" "\specialcell{PLS-F $-$ \\PLS-N}" "Obs.") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress replace
esttab col* using "$tab_dir/$regpath-n.tex", booktabs cells(none) nogap mgroups("Log odds" "Sample", pattern(1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("PLS-N" "PLS-F" "\specialcell{PLS-F $-$ \\PLS-N}" "Obs.") stats(`statnames', labels(`varlabels')) prehead("`prehead_n'") postfoot("`postfoot'") compress replace

eststo clear

file open tex using "$tab_dir/$regpath.tex", write append
file write tex _n "% File produced by reg-ologit.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex
