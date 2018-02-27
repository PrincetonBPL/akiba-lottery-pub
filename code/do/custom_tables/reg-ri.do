** Title: reg-ri.do
** Author: Justin Abraham
** Desc: Outputs regression tables with randomization inference
** Input: UMIP Master.dta
** Output: reg-ri.tex

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

restore

/* Custom fill cells */

foreach yvar in $regvars {

	/* Column 1: Lottery */

	permute treatmentgroup lottery = r(lottery) lotteryse = r(lotteryse) regret = r(regret) regretse = r(regretse) diff = r(diff), reps($riterations): ri `yvar'
	mat def EST = r(b)
	mat def P = r(p)

	loc b = EST[1, colnumb(matrix(EST),"lottery")]
	loc se = EST[1, colnumb(matrix(EST),"lotteryse")]
	loc p = P[1, colnumb(matrix(P),"lottery")]

	sigstar, b(`b') se(`se') p(`p') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col1
	estadd loc thisstat`countse' = "`r(sestar)'": col1

	/* Column 2: Regret */

	loc b = EST[1, colnumb(matrix(EST),"regret")]
	loc se = EST[1, colnumb(matrix(EST),"regretse")]
	loc p = P[1, colnumb(matrix(P),"regret")]

	sigstar, b(`b') se(`se') p(`p') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col2
	estadd loc thisstat`countse' = "`r(sestar)'": col2

	/* Column 3: Lottery vs Regret */

	loc b = EST[1, colnumb(matrix(EST),"diff")]
	loc se = EST[1, colnumb(matrix(EST),"diffse")]
	loc p = P[1, colnumb(matrix(P),"diff")]

	sigstar, b(`b') se(`se') p(`p') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col3
	estadd loc thisstat`countse' = "`r(sestar)'": col3

	/* Column 4: Control Mean */

	qui sum `yvar' if control
	estadd loc thisstat`count' = string(`r(mean)', "%9.2f"): col4
	estadd loc thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")": col4

	/* Column 5: N */

	qui count if ~mi(`yvar')
	estadd loc thisstat`count' = r(N): col5

	/* Row Labels */

	loc thisvarlabel: variable label `yvar' // Extracts label from row var
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	loc statnames "`statnames' thisstat`count' thisstat`countse'"
	loc count = `count' + 2
	loc countse = `count' + 1

}

/* Table options */

loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$regtitle} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc prehead_n "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "\emph{Notes:} Columns 1--3 report OLS estimates of the treatment effect. Standard errors are in parentheses and were calculated under permutation of the treatment assignment. Columns 4--5 report the mean and SD of the control group and the number observations, respectively. Observations are at the individual level. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."

esttab col* using "$tab_dir/$regpath.tex", booktabs cells(none) nogap mgroups("Effect estimates" "Sample", pattern(1 0 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("Lottery" "Regret" "\specialcell{Regret-\\Lottery}" "\specialcell{Control Mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress replace
esttab col* using "$tab_dir/$regpath-n.tex", booktabs cells(none) nogap mgroups("Effect estimates" "Sample", pattern(1 0 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("Lottery" "Regret" "\specialcell{Regret-\\Lottery}" "\specialcell{Control Mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) prehead("`prehead_n'") postfoot("`postfoot'") compress replace

eststo clear

file open tex using "$tab_dir/$regpath.tex", write append
file write tex _n "% File produced by reg-ri.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex
