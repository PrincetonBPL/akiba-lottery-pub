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

loc columns = 8

set obs 10
gen x = 1
gen y = 1

forval i = 1/`columns' {
	eststo col`i': reg x y
}

loc count = 1				// Cell first line
loc countse = `count' + 1	// Cell second line
loc countp = `countse' + 1  // Cell third line

loc statnames "" 			// Added scalars to be filled
loc varlabels "" 			// Labels for row vars to be filled

restore

/* Custom fill cells */

foreach yvar in $regvars {

 	permute treatmentgroup lottery = r(lottery) regret = r(regret) diff = r(diff), reps($riterations): ri `yvar'
	mat def R = r(b)

	/* Column 1: Lottery */

	pstar, b(`bins') se(`seins') p(`pins') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col1
	estadd loc thisstat`countse' = "`r(sestar)'": col1

	/* Column 2: Regret */


	pstar, b(`buct') se(`seuct') p(`puct') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col2
	estadd loc thisstat`countse' = "`r(sestar)'": col2

	/* Column 3: Lottery vs Regret */

	qui test [o_`yvar'_mean]regret = [o_`yvar'_mean]lottery
	pstar, p(`r(p)') prec(2) pstar pnopar
	estadd loc thisstat`count' = "`r(pstar)'": col3

 	est restore sur2

	/* Column 4: Lottery */


	pstar, b(`bins') se(`seins') p(`pins') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col4
	estadd loc thisstat`countse' = "`r(sestar)'": col4

	/* Column 5: Regret */


	pstar, b(`buct') se(`seuct') p(`puct') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col5
	estadd loc thisstat`countse' = "`r(sestar)'": col5

	/* Column 6: Lottery vs Regret */

	qui test [c_`yvar'_mean]regret = [c_`yvar'_mean]lottery
	pstar, p(`r(p)') prec(2) pstar pnopar
	estadd loc thisstat`count' = "`r(pstar)'": col6

	/* Column 7: Control Mean */

	qui sum `yvar' if control
	estadd loc thisstat`count' = string(`r(mean)', "%9.2f"): col7
	estadd loc thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")": col7

	/* Column 8: N */

	estadd loc thisstat`count' = ``yvar'_N': col8

	/* Row Labels */

	loc thisvarlabel: variable label `yvar' // Extracts label from row var
	local varlabels "`varlabels' "`thisvarlabel'" " " " " "
	loc statnames "`statnames' thisstat`count' thisstat`countse' thisstat`countp'"
	loc count = `count' + 3
	loc countse = `count' + 1
	loc countp = `countse' + 1

}


/* Table options */

loc prehead "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$regtitle} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc prehead_n "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "\emph{Notes:} Columns 1 - 2 report OLS estimates of the treatment effect. Columns 4 - 5 reports the estimates controlling for baseline covariates. Columns 3 and 6 report the \(p\)-values for tests of the equality of the two main treatment effects after estimation. Standard errors are in parentheses. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."

esttab col* using "$tab_dir/$regpath.tex", booktabs cells(none) nogap mgroups("No controls" "With controls" "Sample", pattern(1 0 0 1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("Lottery" "Regret" "\specialcell{Difference\\\(p\)-value}" "Lottery" "Regret" "\specialcell{Difference\\\(p\)-value}" "\specialcell{Control Mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress replace
esttab col* using "$tab_dir/$regpath-n.tex", booktabs cells(none) nogap mgroups("No controls" "With controls" "Sample", pattern(1 0 0 1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("Lottery" "Regret" "\specialcell{Difference\\\(p\)-value}" "Lottery" "Regret" "\specialcell{Difference\\\(p\)-value}" "\specialcell{Control Mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) prehead("`prehead_n'") postfoot("`postfoot'") compress replace

eststo clear
