** Title: akiba_estimate.do
** Author: Justin Abraham
** Desc: Run specified regressions and outputs tables in .tex format
** Input: akiba_wide.dta, akiba_long.dta
** Output: Regression tables

///////////////////////////////////////////////
/* Control variables demeaned and interacted */
///////////////////////////////////////////////

foreach v in $controlvars {

	foreach type in wide long {

		cap noi {

			use "$data_dir/clean/akiba_`type'.dta", clear
			qui sum `v'
			gen Lx`v' = lottery * (`v' - `r(mean)')
			gen Rx`v' = regret * (`v' - `r(mean)')
			save "$data_dir/clean/akiba_`type'.dta", replace

		}

	}

	glo controlvars "$controlvars Lx`v' Rx`v'"

}

///////////////
/* Attrition */
///////////////

if $attritionflag {

use "$data_dir/clean/akiba_wide.dta", clear

	eststo: reg endline lottery regret, vce(r)

		test lottery = regret
		estadd scalar Diff_p = round(r(p), 0.01)

		testparm lottery regret
		estadd scalar Joint_p = round(r(p), 0.01)


	loc prehead "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Attrition by treatment group} \label{tab:reg-attr} \maxsizebox*{\paperwidth}{\paperheight}{ \begin{threeparttable} \begin{tabular}{l*{1}{c}} \toprule"
	loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
	loc footnote "This table reports a regression of selection on each of the treatment arms. Standard errors are in parentheses. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."
	esttab using "$tab_dir/reg-attr", alignment(c) ar2 nobaselevels nonum nogap label b(%9.2f) se(%9.2f) sfmt(%9.2f) scalars("Diff_p Difference p-value" "Joint_p Joint p-value") star(* 0.10 ** 0.05 *** 0.01) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") se compress booktabs replace
	eststo clear

	file open tex using "$tab_dir/reg-attr.tex", write append
	file write tex _n "% File produced by akiba-estimate.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
	file close tex

}

///////////////////////
/* Treatment effects */
///////////////////////

loc grouplist "ymobile yearly ylate ypanel ysave ygamble yakiba yselect yself" // ylottery

loc ymobiledesc "Mobile savings by respondent"
loc yearlydesc "Mobile savings by respondent ($\leq$ 30 days)"
loc ylatedesc "Mobile savings by respondent (> 30 days)"
loc ypaneldesc "Mobile savings by period"
loc ysavedesc "Savings outside the study"
loc ygambledesc "Gambling behavior outside the study"
loc yakibadesc "Akiba SMART"
loc yselectdesc "Group self-selection"
loc ylotterydesc "Lottery usage"
loc yselfdesc "Self-perceptions"

if $maineffectsflag {

	foreach group in `grouplist' {

		loc root = substr("`group'", 2, .)
		glo regvars "$`group'"

		if ("`group'" != "ypanel") {

			use "$data_dir/clean/akiba_wide.dta", clear

			glo regpath "reg-`root'"
			glo regtitle "Treatment effects -- ``group'desc'"
			do "$do_dir/custom_tables/reg-fdr.do"

			glo regpath "reg-fwer`root'"
			glo regtitle "Treatment effects controlling the FWER -- ``group'desc'"
			do "$do_dir/custom_tables/reg-fwer.do"

		}

		else {

			use "$data_dir/clean/akiba_long.dta", clear

			glo regpath "reg-`root'"
			glo regtitle "Treatment effects -- ``group'desc'"
			do "$do_dir/custom_tables/reg-fdr.do"

		}

	}

}

////////////////////////////////////////
/* Exact test of the treatment effect */
////////////////////////////////////////

if $riflag {

	cap program drop ri

	program ri, rclass

		version 13.1
		qui reg `1' i.treatmentgroup `2', vce(cl surveyid)

		return scalar lottery = _b[2.treatmentgroup]
		return scalar lotteryse = _se[2.treatmentgroup]

		return scalar regret = _b[3.treatmentgroup]
		return scalar regretse = _se[3.treatmentgroup]

		return scalar diff = _b[2.treatmentgroup] - _b[3.treatmentgroup]

	end

	foreach group in `grouplist' {

		loc root = substr("`group'", 2, .)
		glo regvars "$`group'"
		glo regpath "ri-`root'"
		glo regtitle "Treatment effects with randomization inference -- ``group'desc'"

		if ("`group'" == "ypanel") use "$data_dir/clean/akiba_long.dta", clear
		else use "$data_dir/clean/akiba_wide.dta", clear

		do "$do_dir/custom_tables/reg-ri.do"

	}

}

/////////////////////////////////////
/* Heterogeneous treatment effects */
/////////////////////////////////////

if $heteffectsflag {

	glo yvars "mobile_totdeposits mobile_totdepositamt save_dorosca_1 gam_moregamble_1"
	glo hetvars "$xhet"
	glo control "control"

	glo treat "lottery"
	do "$do_dir/custom_tables/reg-hetero.do"

	glo treat "regret"
	do "$do_dir/custom_tables/reg-hetero.do"

	loc righthand ""
	loc fillmiss ""

	foreach xvar in $xhet {

		loc xvarlab : var label `xvar'

		cap: gen `xvar'_miss = mi(`xvar')
		cap: gen `xvar'_full = `xvar'
		cap: replace `xvar'_full = 0 if `xvar'_miss
		loc fillmiss "`fillmiss' `xvar'_full `xvar'_miss"

		gen LX`xvar' = lottery * `xvar'
		la var LX`xvar' "Lottery $\times$ \\ `xvarlab'"

		gen RX`xvar' = regret * `xvar'
		la var RX`xvar' "Regret $\times$ \\ `xvarlab'"

		loc righthand "`righthand' LX`xvar' RX`xvar'"

		loc xvarlab = lower("`xvarlab'")

		loc columns = 0

		foreach yvar in mobile_totdeposits mobile_avgdeposits mobile_savedays gam_moregamble_1 {

			eststo: reg `yvar' lottery LX`xvar' regret RX`xvar' `xvar', vce(r)

			sum `yvar' if control
			estadd scalar ymean = round(r(mean), 0.01)

			test lottery + LX`xvar' = 0
			estadd scalar Ljoint_p = round(r(p), 0.01)

			test regret + RX`xvar' = 0
			estadd scalar Rjoint_p = round(r(p), 0.01)

			loc ++columns

		}

		loc prehead "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Heterogeneous effects - Primary outcomes by `xvarlab'} \label{tab:het-`xvar'} \maxsizebox*{\paperwidth}{\paperheight}{ \begin{threeparttable} \begin{tabular}{l*{`columns'}{c}} \toprule"
		loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
		loc footnote "This table reports OLS estimates of the treatment effect and its interaction with baseline. Standard errors are in parentheses. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level. We also report the \(p\)-values for joint tests on the direct treatment effect conditional on the baseline covariate $= 1$."

		esttab using "$tab_dir/het-`xvar'.tex", alignment(c) ar2 obslast nobaselevels label b(%9.2f) se(%9.2f) sfmt(%9.2f) scalars("ymean Control mean" "Ljoint_p Lottery \emph{p}-value" "Rjoint_p Regret \emph{p}-value") nogap star(* 0.10 ** 0.05 *** 0.01) prehead("`prehead'") postfoot("`postfoot'") note("`footnote'") substitute(\_ ) se compress booktabs replace
		eststo clear

		file open tex using "$tab_dir/het-`xvar'.tex", write append
		file write tex _n "% File produced by akiba_estimate.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
		file close tex

	}

	foreach yvar in mobile_totdeposits mobile_avgdeposits mobile_savedays gam_moregamble_1 {

		eststo, prefix(horse): reg `yvar' lottery regret `righthand' `fillmiss', vce(r)

		sum `yvar' if control
		estadd scalar ymean = round(r(mean), 0.01)

	}

	esttab horse* using "$tab_dir/het-horserace.tex", alignment(c) ar2 nobaselevels label drop(`fillmiss') b(%9.2f) se(%9.2f) sfmt(%9.2f) scalars("ymean Control mean") title("Heterogeneous effects - Full regression") star(* 0.10 ** 0.05 *** 0.01) se compress booktabs replace
	eststo clear

	file open tex using "$tab_dir/het-horserace.tex", write append
	file write tex _n "% File produced by akiba_estimate.do with `c(filename)' on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)' with seed `c(seed)'"
	file close tex

}

/* Panel analysis */

if $panelflag {

	* use "$data_dir/clean/akiba_long.dta", clear

	* sort period account

	* eststo: xtreg mobile_saved L(1/$laglength).mobile_saved if control, fe i(period) vce(cl surveyid)
	* mat A_b = e(b)'
	* mat A_se = e(se)'

	* testparm L(1/$laglength).mobile_saved
	* estadd scalar Joint_p = round(r(p), 0.01)
	* estadd loc treat "Interest"
	* estadd loc fe "Period"
	* estadd loc cl "Individual"

	* eststo: xtreg mobile_saved L(1/$laglength).mobile_saved if lottery, fe i(period) vce(cl surveyid)
	* mat B_b = e(b)'
	* mat B_se = e(se)'

	* testparm L(1/$laglength).mobile_saved
	* estadd scalar Joint_p = round(r(p), 0.01)
	* estadd loc treat "Lottery"
	* estadd loc fe "Period"
	* estadd loc cl "Individual"

	* eststo: xtreg mobile_saved L(1/$laglength).mobile_saved if regret, fe i(period) vce(cl surveyid)
	* mat C_b = e(b)'
	* mat C_se = e(se)'

	* testparm L(1/$laglength).mobile_saved
	* estadd scalar Joint_p = round(r(p), 0.01)
	* estadd loc treat "Regret"
	* estadd loc fe "Period"
	* estadd loc cl "Individual"

	* loc prehead "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Autoregressive model} \label{tab:panel-ar} \maxsizebox*{\paperwidth}{\paperheight}{ \begin{threeparttable} \begin{tabular}{l*{3}{c}} \toprule"
	* loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
	* loc footnote "This table reports estimates of an AR model of savings with a lag length of $laglength across each treatment arm. Standard errors are in parentheses. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."
	* esttab using "$tab_dir/panel-ar", alignment(c) ar2 nobaselevels label b(%9.2f) se(%9.2f) sfmt(%9.2f) scalars("treat Treatment" "Joint_p Joint p-value" "fe Fixed effects" "cl Cluster") nogap star(* 0.10 ** 0.05 *** 0.01) prehead("`prehead'") postfoot("`postfoot'") note("`footnote'") se compress booktabs replace
	* eststo clear

	* foreach yvar in mobile_saved mobile_depositamount {

	* 	eststo: xtreg `yvar' L(1/$laglength).mobile_saved L(1/$laglength).mobile_matched L(1/$laglength).mobile_awarded if ~control, absorb(period) vce(cl surveyid)
	* 	estadd loc fe "Day"
	* 	estadd loc cl "Individual"

	* }

	* loc prehead "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Distributed lag model} \label{tab:panel-dl} \maxsizebox*{\paperwidth}{\paperheight}{ \begin{threeparttable} \begin{tabular}{l*{3}{c}} \toprule"
	* loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
	* loc footnote "This table reports estimates of a distributed lag model with a lag length of $laglength. Standard errors are in parentheses. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."
	* esttab using "$tab_dir/panel-dl", alignment(c) ar2 nobaselevels label b(%9.2f) se(%9.2f) sfmt(%9.2f) scalars("fe Fixed effects" "cl Cluster") nogap star(* 0.10 ** 0.05 *** 0.01) prehead("`prehead'") postfoot("`postfoot'") note("`footnote'") se compress booktabs replace
	* eststo clear

}

/////////////////////////////////////
/* Minimum detectable effect sizes */
/////////////////////////////////////

glo regvars "$ynull"
glo regpath "reg-mde"
glo regtitle "Minimum detectable effect sizes"
do "$do_dir/custom_tables/reg-mde.do"

/////////////////////////////////////////////
/* Baseline correlates of savings behavior */
/////////////////////////////////////////////

use "$data_dir/clean/akiba_wide.dta", clear

loc varlist = "$xcor"
loc length: list sizeof varlist

foreach xvar of varlist $xcor {

	eststo, pre(num): reg mobile_totdeposits `xvar' if control == 1, vce(cl surveyid)

		estadd loc ar2 = string(e(r2_a), "%9.2f")
		estadd loc fstat = string(e(F), "%9.2f")

	eststo, pre(amt): reg mobile_totdepositamt `xvar' if control == 1, vce(cl surveyid)

		estadd loc ar2 = string(e(r2_a), "%9.2f")
		estadd loc fstat = string(e(F), "%9.2f")

}

loc prehead "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Baseline correlates of number of deposits made} \label{tab:reg-cortotdeposits} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`length'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "This table reports estimates of `length' univariate regressions of number of deposits made on preference parameters estimated in the lab. Standard errors are clustered at the participant level and reported in parentheses. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."
esttab num* using "$tab_dir/reg-cortotdeposits", alignment(c) obslast nobaselevels nomtitle label b(%9.2f) se(%9.2f) sfmt(%9.2f) scalars("ar2 Adjusted R2" "fstat F-statistic") nogap star(* 0.10 ** 0.05 *** 0.01) prehead("`prehead'") postfoot("`postfoot'") note("`footnote'") se compress booktabs replace

loc prehead "\begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Baseline correlates of amount deposited} \label{tab:reg-cortotdepositamt} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{l*{`length'}{c}} \toprule"
loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item \emph{Notes:} @note \end{tablenotes} \end{threeparttable} } \end{table}"
loc footnote "This table reports estimates of `length' univariate regressions of amount deposited on preference parameters estimated in the lab. Standard errors are clustered at the participant level and reported in parentheses. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."
esttab amt* using "$tab_dir/reg-cortotdepositamt", alignment(c) obslast nobaselevels nomtitle label b(%9.2f) se(%9.2f) sfmt(%9.2f) scalars("ar2 Adjusted R2" "fstat F-statistic") nogap star(* 0.10 ** 0.05 *** 0.01) prehead("`prehead'") postfoot("`postfoot'") note("`footnote'") se compress booktabs replace
eststo clear
