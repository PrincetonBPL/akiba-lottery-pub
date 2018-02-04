** Title: akiba_summary.do
** Author: Justin Abraham
** Desc: Outputs summary statistics
** Input: akiba_wide.dta
** Output: Summary statistic tables in .tex format

use "$data_dir/clean/akiba_wide", clear

/* Cross-tabulations */

estpost tab treatmentgroup endline
loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Treatment group by participation at endline} \label{tab:tab-balance} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{3}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "This table reports the number of observations in the endline survey by treatment group. Columns 1 and 2 reports the number of participants who completed the baseline survey but not endline and those who completed both surveys, repsectively."
esttab using "$tab_dir/tab-balance.tex", booktabs unstack compress nogaps noobs nonumber nomtitle label mgroups("Participation at endline", pattern(1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) prehead("`prehead'") postfoot("`postfoot'") note("`footnote'") replace
eststo clear

file open tex using "$tab_dir/tab-balance.tex", write append
file write tex _n "% File produced by akiba_summary.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex

estpost tab treatmentgroup akiba_select_1
loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Self-selection by treatment group} \label{tab:tab-select} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{4}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "This table reports the number of participants self-selecting into the treatment conditions after completing the study, disaggregated by original treatment assignment."
esttab using "$tab_dir/tab-select.tex", booktabs unstack compress nogaps noobs nonumber nomtitle label mgroups("Self-selection into treatment groups", pattern(1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) prehead("`prehead'") postfoot("`postfoot'") note("`footnote'") replace
eststo clear

file open tex using "$tab_dir/tab-select.tex", write append
file write tex _n "% File produced by akiba_summary.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
file close tex

/* Unified summary statistics */

glo sumvars "demo_female_0 demo_age_0 demo_stdschool_0 demo_married_0 demo_children_0 pref_crra_0 pref_locscore_0 labor_monthlyinc_0 labor_employed_0 save_dosave_0 save_monthlysave_0 save_dorosca_0 save_monthlyrosca_0"

glo sumtitle "Baseline balance by treatment group"
glo sumpath "sum-ysumall"
do "$do_dir/custom_tables/sum-treat.do"

glo sumtitle "Baseline balance by attrition status"
glo sumpath "sum-attrall"
do "$do_dir/custom_tables/sum-participation.do"

glo sumtitle "Baseline balance by treatment group for endline sample"
glo sumpath "sum-eltreatall"
do "$do_dir/custom_tables/sum-eltreat.do"

/* Summary statistics across groups */

forval i = 1/5 {

	loc trunc "ysum`i'"
	glo sumvars $`trunc'

	glo sumtitle "Baseline balance check by treatment group"
	glo sumpath "sum-ysum`i'"
	do "$do_dir/custom_tables/sum-treat.do"

	glo sumtitle "Baseline balance check by attrition status"
	glo sumpath "sum-attr`i'"
	do "$do_dir/custom_tables/sum-participation.do"

	glo sumtitle "Baseline balance check by treatment group for endline sample"
	glo sumpath "sum-eltreat`i'"
	do "$do_dir/custom_tables/sum-eltreat.do"

}

/* Unconditional summary statistics */

forval i = 6/9 {

	loc trunc "ysum`i'"
	glo sumvars $`trunc'

	glo sumtitle "Endine summary statistics"
	glo sumpath "sum-ysum`i'"
	do "$do_dir/custom_tables/sum-unconditional.do"

}
