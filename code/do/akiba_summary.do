** Title: akiba_summary.do
** Author: Justin Abraham
** Desc: Outputs summary statistics
** Input: akiba_wide.dta
** Output: Summary statistic tables in .tex format

use "$data_dir/clean/akiba_wide", clear

/* Cross-tabulations */

estpost tab treatmentgroup endline
loc prehead "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Treatment group by participation at endline} \label{tab:tab-balance} \maxsizebox*{\paperwidth}{\paperheight}{ \begin{threeparttable} \begin{tabular}{l*{3}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "This table reports a cross-tabulation between treatment assignment and selection into the endline survey."
esttab using "$tab_dir/tab-balance", booktabs unstack noobs nonumber nomtitle label mgroups("Participation in endline", pattern(1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) prehead("`prehead'") postfoot("`postfoot'") note("`footnote'") replace
eststo clear

estpost tab treatmentgroup akiba_select_1
loc prehead "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Self-selection by treatment group} \label{tab:tab-select} \maxsizebox*{\paperwidth}{\paperheight}{ \begin{threeparttable} \begin{tabular}{l*{4}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "This table reports a cross-tabulation between self-selection into the treatment conditions and original treatment assignment."
esttab using "$tab_dir/tab-select", booktabs unstack noobs nonumber nomtitle label mgroups("Self-selection", pattern(1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) prehead("`prehead'") postfoot("`postfoot'") note("`footnote'") replace
eststo clear

/* Summary statistics across groups */

forval i = 1/5 {

	loc trunc "ysum`i'"
	glo sumvars $`trunc'

	glo sumtitle "Summary statistics by treatment group"
	glo sumpath "sum-ysum`i'"
	do "$do_dir/custom_tables/sum-treat.do"

	glo sumtitle "Summary statistics by attrition"
	glo sumpath "sum-attr`i'"
	do "$do_dir/custom_tables/sum-participation.do"

	glo sumtitle "Summary statistics of attriters by treatment group"
	glo sumpath "sum-attrtreat`i'"
	do "$do_dir/custom_tables/sum-attrtreat.do"

}

/* Unified summary statistics */

glo sumvars "$ysum1 $ysum2 $ysum3"

glo sumtitle "Summary statistics by treatment group"
glo sumpath "sum-ysumall"
do "$do_dir/custom_tables/sum-treat.do"

glo sumtitle "Summary statistics by attrition"
glo sumpath "sum-attrall"
do "$do_dir/custom_tables/sum-participation.do"

glo sumtitle "Summary statistics of attriters by treatment group"
glo sumpath "sum-attrtreatall"
do "$do_dir/custom_tables/sum-attrtreat.do"

/* Unconditional summary statistics */

forval i = 6/9 {

	loc trunc "ysum`i'"
	glo sumvars $`trunc'

	glo sumtitle "Endine summary statistics"
	glo sumpath "sum-ysum`i'"
	do "$do_dir/custom_tables/sum-unconditional.do"

}
