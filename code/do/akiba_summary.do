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

/* Baseline balance checks */

glo sumvars "demo_female_0 demo_age_0 demo_stdschool_0 demo_married_0 demo_children_0 save_dosave_0 save_monthlysave_0 labor_monthlyinc_0 labor_employed_0 pref_crra_0 pref_locscore_0 gam_cpgi_z_0 pref_avgexponential_0"

glo sumtitle "Baseline balance by treatment group"
glo sumpath "sum-ysumall"
do "$do_dir/custom_tables/sum-treat.do"

glo sumtitle "Baseline balance by attrition status"
glo sumpath "sum-attrall"
do "$do_dir/custom_tables/sum-participation.do"

glo sumtitle "Baseline balance by treatment group for endline sample"
glo sumpath "sum-eltreatall"
do "$do_dir/custom_tables/sum-eltreat.do"

/* Unconditional summary statistics */

loc ysum6 "mobile_totdeposits mobile_totdepositamt mobile_avgdepositamt mobile_totwithdrawalamt"
loc ysum7 "akiba_trust_1 akiba_confidence_1 akiba_lotteryfair_1 akiba_family_1 akiba_prizegood_1 akiba_prizebad_1 akiba_continue_1 akiba_rules_1"
loc ysum8 "akiba_controlselect_1 akiba_lotteryselect_1 akiba_regretselect_1 akiba_controlsave_1 akiba_lotterysave_1 akiba_regretsave_1"
loc ysum9 "gam_moretempted_1 gam_lesstempted_1 gam_moregamble_1 gam_lessgamble_1 self_saver_1 self_lucky_1 self_savingsfeel_1 self_nosavefeel_1"

forval i = 6/9 {

	loc trunc "ysum`i'"
	glo sumvars ``trunc''

	glo sumtitle "Endine summary statistics"
	glo sumpath "sum-ysum`i'"
	do "$do_dir/custom_tables/sum-unconditional.do"

}
