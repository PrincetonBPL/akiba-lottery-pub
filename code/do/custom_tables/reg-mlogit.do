** Title: reg-mlogit.do
** Author: Justin Abraham
** Desc: Outputs multinomial logit estimates by relative risk ratios
** Input: UMIP Master.dta
** Output: reg-mlogit.tex

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

/* Estimation */

mlogit $depvar i.treatmentgroup, rrr vce(cl surveyid) b($basevalue)

	mat def V = e(out)
	loc matlength = e(k_out)
	loc baseix = e(ibaseout)
	loc baselabel = e(baselab)
	loc obs = e(N)

forval i = 1/`matlength' {

	if `i' != `baseix' {

		/* Column 1 */

		qui lincom _b[`i':2.treatmentgroup], rrr

			loc b = r(estimate)
			loc se = r(se)
			loc p = r(p)

		sigstar, b(`b') se(`se') p(`p') prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col1
		estadd loc thisstat`countse' = "`r(sestar)'": col1

		/* Column 2 */

		qui lincom _b[`i':3.treatmentgroup], rrr

			loc b = r(estimate)
			loc se = r(se)
			loc p = r(p)

		sigstar, b(`b') se(`se') p(`p') prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col2
		estadd loc thisstat`countse' = "`r(sestar)'": col2

		/* Column 3 */

		qui lincom _b[`i':3.treatmentgroup] - _b[`i':2.treatmentgroup], rrr

			loc b = r(estimate)
			loc se = r(se)
			loc p = r(p)

		sigstar, b(`b') se(`se') p(`p') prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col3
		estadd loc thisstat`countse' = "`r(sestar)'": col3

		/* Column 4: Control Mean */

		/* Column 5: N */

		estadd loc thisstat`count' = `obs': col4

		/* Row Labels */

		loc value = V[1, `i']
		loc labelname: value label $depvar
		loc valuelabel: label `labelname' `value'

		loc varlabels "`varlabels' "`valuelabel'" " " "
		loc statnames "`statnames' thisstat`count' thisstat`countse'"
		loc count = `count' + 2
		loc countse = `count' + 1

	}

}

/* Table options */

loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$regtitle} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc prehead_n "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "\emph{Notes:} This table reports estimates from a multinomial logit estimation of the categorial response on treatment assigment. Each row corresponds to a response category with the baseline value as `` `baselabel' ''.  Columns 1--2 reports the treatment effect in relative risk ratios compared to the control group. Column 3 reports the difference between the two PLS treatments. Standard errors are in parentheses. Column 4 reports the number of observations in the analytic sample. Observations are at the individual level. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."

esttab col* using "$tab_dir/$regpath.tex", booktabs cells(none) nogap mgroups("Relative risk ratio" "Sample", pattern(1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("No Feedback" "PLS" "\specialcell{PLS-\\No Feedback}" "Obs.") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress replace
esttab col* using "$tab_dir/$regpath-n.tex", booktabs cells(none) nogap mgroups("Relative risk ratio" "Sample", pattern(1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("No Feedback" "PLS" "\specialcell{PLS-\\No Feedback}" "Obs.") stats(`statnames', labels(`varlabels')) prehead("`prehead_n'") postfoot("`postfoot'") compress replace

eststo clear

file open tex using "$tab_dir/$regpath.tex", write append
file write tex _n "% File produced by reg-mlogit.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex
