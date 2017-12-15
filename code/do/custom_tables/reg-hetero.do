** Title: reg-hetero
** Author: Justin Abraham
** Desc: Outputs treatment effects
** Input: akiba_wide.dta
** Output: het-something.tex

/* Create empty table */

clear
eststo clear
estimates drop _all


loc columns = 0

foreach var in $yvars {

	loc ++columns

}

set obs 10
gen x = 1
gen y = 1

forval i = 1/`columns' {
	eststo col`i': reg x y
}

loc spacer1 = 1
loc count = 2
loc countse = `count' + 1
loc count2 = `countse' + 1
loc countse2 = `count2' + 1
loc counttest = `countse2' + 1
* loc spacer3  = `counttest' + 1

loc header ""
loc statnames ""
loc statlabels ""

/* Custom fill cells */

use "$data_dir/clean/akiba_wide.dta", clear

foreach het in $hetvars {

	loc column = 1

	foreach yvar in $yvars {

		qui reg `yvar' i.$treat##i.`het' if $treat | $control, vce(r)

		est sto reg

		loc b = _b[1.$treat] + _b[1.$treat#1.`het']
		qui test 1.$treat + 1.$treat#1.`het' = 0

		pstar, b(`b') p(`r(p)') prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col`column'
		estadd loc thisstat`countse' = "`r(sestar)'": col`column'

		qui est res reg

		pstar 1.$treat, prec(2)
		estadd loc thisstat`count2' = "`r(bstar)'": col`column'
		estadd loc thisstat`countse2' = "`r(sestar)'": col`column'

		* pstar 1.$treat#1.`het', prec(2)
		* estadd loc thisstat`counttest' = "`r(bstar)'": col`column'

		loc ++column

	}

	/* Load names and stats */

	loc groupla : var la `het'
	loc statlabels "`statlabels' "\textit{`groupla'}" "\hspace{0.5cm} \(\hat\beta|x_i=1\)" " " "\hspace{0.5cm} \(\hat\beta|x_i=0\)" " " "
	loc statnames "`statnames' this`spacer1' thisstat`count' thisstat`countse' thisstat`count2' thisstat`countse2'"

	loc spacer1 = `spacer1' + 7
	loc count = `spacer1' + 1
	loc countse = `count' + 1
	loc count2 = `countse' + 1
	loc countse2 = `count2' + 1
	loc counttest = `countse2' + 1
	* loc spacer3  = `counttest' + 1

}

/* Table settings */

foreach var in $yvars {

	loc label: var la `var'
	loc header "`header' "`label'""

}

loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Heterogeneous treatment effects of $treat} \label{tab:het-$treat} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \label{tab:het-$treat} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "\emph{Notes:} This table reports heterogeneous treatment effects of $treat on each of the column variables where each panel represents a dimension of heterogeneity. The first row of each panel is the treatment coefficient when the baseline dummy variable \(x_i = 1\) and the second row is the treatment coefficient when \(x_i = 0\). Standard errors are in parentheses. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct."

esttab col* using "$tab_dir/het-$treat.tex", booktabs unstack cells(none) nocons compress nobaselevels noomit nonumber nogap label noobs mti(`header') mgroups("Dependent variables", pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) stats(`statnames', labels(`statlabels')) prehead("`prehead'") postfoot("`postfoot'") note("`footnote'") substitute(\_ _) replace
esttab col* using "$tab_dir/het-$treat-n.tex", booktabs unstack cells(none) nocons compress nobaselevels noomit nonumber nogap label noobs mti(`header') mgroups("Dependent variables", pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) stats(`statnames', labels(`statlabels')) prehead("`prehead_n'") postfoot("`postfoot'") note("`footnote'") substitute(\_ _) replace

eststo clear

file open tex using "$tab_dir/$regpath.tex", write append
file write tex _n "% File produced by reg-hetero.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex
