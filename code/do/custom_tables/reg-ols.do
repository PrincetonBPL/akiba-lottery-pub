** Title: reg-ols.do
** Author: Justin Abraham
** Desc: Outputs regression tables with FWER adjusted p-values for regression with full controls
** Input: UMIP Master.dta
** Output: reg-ols.tex

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

loc surlist1 ""				// List of stored estimates for SUR
loc surlist2 ""				// List of stored estimates for SUR with controls

restore

/* SUR */

foreach yvar in $regvars {

	qui reg `yvar' lottery regret
	est store o_`yvar'
	loc surlist1 "`surlist1' o_`yvar'"

	loc `yvar'_N = e(N)

	qui reg `yvar' lottery regret $controlvars
	est store c_`yvar'
	loc surlist2 "`surlist2' c_`yvar'"

}

suest `surlist1', vce(cl surveyid)
est store sur1

suest `surlist2', vce(cl surveyid)
est store sur2

/* Custom fill cells */

foreach yvar in $regvars {

 	est restore sur1

	/* Column 1: Lottery */

	qui test [o_`yvar'_mean]lottery = 0
	loc pins = `r(p)'
	loc bins = _b[o_`yvar'_mean:lottery]
	loc seins = _se[o_`yvar'_mean:lottery]

	pstar, b(`bins') se(`seins') p(`pins') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col1
	estadd loc thisstat`countse' = "`r(sestar)'": col1

	/* Column 2: Regret */

	qui test [o_`yvar'_mean]regret = 0
	loc puct = `r(p)'
	loc buct = _b[o_`yvar'_mean:regret]
	loc seuct = _se[o_`yvar'_mean:regret]

	pstar, b(`buct') se(`seuct') p(`puct') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col2
	estadd loc thisstat`countse' = "`r(sestar)'": col2

	/* Column 3: Lottery vs Regret */

	qui test [o_`yvar'_mean]regret = [o_`yvar'_mean]lottery
	pstar, p(`r(p)') prec(2) pstar pnopar
	estadd loc thisstat`count' = "`r(pstar)'": col3

 	est restore sur2

	/* Column 4: Lottery */

	qui test [c_`yvar'_mean]lottery = 0
	loc pins = `r(p)'
	loc bins = _b[c_`yvar'_mean:lottery]
	loc seins = _se[c_`yvar'_mean:lottery]

	pstar, b(`bins') se(`seins') p(`pins') prec(2)
	estadd loc thisstat`count' = "`r(bstar)'": col4
	estadd loc thisstat`countse' = "`r(sestar)'": col4

	/* Column 5: Regret */

	qui test [c_`yvar'_mean]regret = 0
	loc puct = `r(p)'
	loc buct = _b[c_`yvar'_mean:regret]
	loc seuct = _se[c_`yvar'_mean:regret]

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

/* SUR Joint Tests */

/* est restore sur1

testparm lottery
pstar, p(`r(p)') pstar pnopar prec(2)
estadd local sur_p "`r(pstar)'": col1
testparm regret
pstar, p(`r(p)') pstar pnopar prec(2)
estadd local sur_p "`r(pstar)'": col2
test regret = lottery
pstar, p(`r(p)') pstar pnopar prec(2)
estadd local sur_p "`r(pstar)'": col3

est restore sur2

testparm lottery
pstar, p(`r(p)') pstar pnopar prec(2)
estadd local sur_p "`r(pstar)'": col4
testparm regret
pstar, p(`r(p)') pstar pnopar prec(2)
estadd local sur_p "`r(pstar)'": col5
test regret = lottery
pstar, p(`r(p)') pstar pnopar prec(2)
estadd local sur_p "`r(pstar)'": col6

loc statnames "`statnames' sur_p"
loc varlabels "`varlabels' "\midrule Joint \(p\)-value"" */

/* Table options */

loc prehead "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{$regtitle} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc prehead_n "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \label{tab:$regpath} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "\emph{Notes:} Columns 1 - 2 report OLS estimates of the treatment effect. Columns 4 - 5 reports the estimates controlling for baseline covariates. Columns 3 and 6 report the \(p\)-values for tests of the equality of the two main treatment effects after estimation. Standard errors are in parentheses. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."

esttab col* using "$tab_dir/$regpath.tex", booktabs cells(none) nogap mgroups("No controls" "With controls" "Sample", pattern(1 0 0 1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("Lottery" "Regret" "\specialcell{Difference\\\(p\)-value}" "Lottery" "Regret" "\specialcell{Difference\\\(p\)-value}" "\specialcell{Control Mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") compress replace
esttab col* using "$tab_dir/$regpath-n.tex", booktabs cells(none) nogap mgroups("No controls" "With controls" "Sample", pattern(1 0 0 1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitle("Lottery" "Regret" "\specialcell{Difference\\\(p\)-value}" "Lottery" "Regret" "\specialcell{Difference\\\(p\)-value}" "\specialcell{Control Mean\\(SD)}" "Obs.") stats(`statnames', labels(`varlabels')) prehead("`prehead_n'") postfoot("`postfoot'") compress replace

eststo clear
