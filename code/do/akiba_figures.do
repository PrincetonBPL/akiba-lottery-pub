** Title: akiba_figures.do
** Author: Justin Abraham
** Desc: Outputs figures
** Input: akiba_wide.dta, akiba_long.dta
** Output: Figures, graphs

/////////////////////////////////////////
/* Treatment effects by CRRA parameter */
/////////////////////////////////////////

foreach yvar in $ymobile {

	use "$data_dir/clean/akiba_wide.dta", clear

	qui tab pref_crra_0, gen(crra) matrow(R)
	mat def C = J(6, 4, .)
	mat C = C, R

	forval i = 1/6 {

		qui reg `yvar' regret lottery if crra`i', vce(r)
		mat C[`i', 1] = _b[lottery]
		mat C[`i', 2] = _se[lottery]
		mat C[`i', 3] = _b[regret]
		mat C[`i', 4] = _se[regret]

	}

	clear
	svmat C

	gen ubl = C1 + (C2 * 1.96)
	gen lbl = C1 - (C2 * 1.96)

	gen ubr = C3 + (C4 * 1.96)
	gen lbr = C3 - (C4 * 1.96)

	twoway (line C1 C5, color(gs0) lpattern(solid)) (line C3 C5, color(gs0) lpattern(dash)) (rcap ubl lbl C5, color(gs0)) (rcap ubr lbr C5, color(gs0)), ytitle("Effect point estimate") xtitle("CRRA parameter") legend(order(1 "Lottery" 2 "Regret")) graphregion(color(white))
	graph export "$fig_dir/line-`yvar'byrisk.eps", replace
	!epstopdf "$fig_dir/line-`yvar'byrisk.eps"

}

///////////////////
/* Project panel */
///////////////////

use "$data_dir/clean/akiba_long.dta", clear

estpost tab mobile_matches
esttab using "$tab_dir/tab-lottery", booktabs unstack noobs nonumber nomtitle label cells("b(label(freq)) pct(fmt(2)) cumpct(fmt(2))") title(Lottery results) replace
eststo clear

////////////////////////////////
/* Savings behavior over time */
////////////////////////////////

collapse (mean) mobile_depositamount mobile_cumdepositamount mobile_deposits mobile_cumdeposits mobile_balance (sem) sem_depositamount = mobile_depositamount sem_cumdepositamount = mobile_cumdepositamount sem_deposits = mobile_deposits sem_cumdeposits = mobile_cumdeposits sem_balance = mobile_balance, by(treatmentgroup period)

foreach root in depositamount deposits cumdepositamount cumdeposits balance {

	gen ub_`root' = mobile_`root' + sem_`root'
	gen lb_`root' = mobile_`root' - sem_`root'

}

graph twoway (line mobile_balance period if treatmentgroup == 1, color(gs0) lpattern(solid)) (line mobile_balance period if treatmentgroup == 2, color(gs0) lpattern(dash)) (line mobile_balance period if treatmentgroup == 3, color(gs0) lpattern(dot)), ytitle("Balance (USD PPP)") legend(order(1 "Control" 2 "Lottery" 3 "Regret")) graphregion(color(white))
graph export "$fig_dir/line-balance.eps", replace
!epstopdf "$fig_dir/line-balance.eps"

graph twoway (line mobile_deposits period if treatmentgroup == 1, color(gs0) lpattern(solid)) (line mobile_deposits period if treatmentgroup == 2, color(gs0) lpattern(dash)) (line mobile_deposits period if treatmentgroup == 3, color(gs0) lpattern(dot)), title("A: Average number of daily deposits made", color(gs0) size(medsmall)) ytitle("No. of deposits") legend(off) graphregion(color(white)) ylabel(,glcolor(gs14)) saving("$fig_dir/line-deposits", replace)
gr export "$fig_dir/line-mobile_deposits.eps"
cap noi !epstopdf "$fig_dir/line-mobile_deposits.eps"

graph twoway (line mobile_depositamount period if treatmentgroup == 1, color(gs0) lpattern(solid)) (line mobile_depositamount period if treatmentgroup == 2, color(gs0) lpattern(dash)) (line mobile_depositamount period if treatmentgroup == 3, color(gs0) lpattern(dot)), title("B: Average daily amount deposited", color(gs0) size(medsmall)) ytitle("Deposit amount (USD PPP)") legend(order(1 "Control" 2 "Lottery" 3 "Regret")) graphregion(color(white)) ylabel(,glcolor(gs14)) saving("$fig_dir/line-depositamount", replace)
gr export "$fig_dir/line-mobile_depositamount.eps"
cap noi !epstopdf "$fig_dir/line-mobile_depositamount.eps"

graph twoway (line mobile_cumdeposits period if treatmentgroup == 1, color(gs0) lpattern(solid)) (line mobile_cumdeposits period if treatmentgroup == 2, color(gs0) lpattern(dash)) (line mobile_cumdeposits period if treatmentgroup == 3, color(gs0) lpattern(dot)) (rcap ub_cumdeposits lb_cumdeposits period if treatmentgroup == 1 & period == 60, color(gs0)) (rcap ub_cumdeposits lb_cumdeposits period if treatmentgroup == 2 & period == 60, color(gs0)) (rcap ub_cumdeposits lb_cumdeposits period if treatmentgroup == 3 & period == 60, color(gs0)), title("A: Cumulative number of deposits made", color(gs0) size(medsmall)) ytitle("No. of deposits") legend(off) graphregion(color(white)) ylabel(,glcolor(gs14)) saving("$fig_dir/line-cumdeposits", replace)
gr export "$fig_dir/line-mobile_cumdeposits.eps"
cap noi !epstopdf "$fig_dir/line-mobile_cumdeposits.eps"

graph twoway (line mobile_cumdepositamount period if treatmentgroup == 1, color(gs0) lpattern(solid)) (line mobile_cumdepositamount period if treatmentgroup == 2, color(gs0) lpattern(dash)) (line mobile_cumdepositamount period if treatmentgroup == 3, color(gs0) lpattern(dot)) (rcap ub_cumdepositamount lb_cumdepositamount period if treatmentgroup == 1 & period == 60, color(gs0)) (rcap ub_cumdepositamount lb_cumdepositamount period if treatmentgroup == 2 & period == 60, color(gs0)) (rcap ub_cumdepositamount lb_cumdepositamount period if treatmentgroup == 3 & period == 60, color(gs0)), title("B: Cumulative amount deposited", color(gs0) size(medsmall)) ytitle("Amount deposited") legend(order(1 "Control" 2 "Lottery" 3 "Regret")) graphregion(color(white)) ylabel(,glcolor(gs14)) saving("$fig_dir/line-cumdepositamount", replace)
gr export "$fig_dir/line-mobile_cumdepositamount.eps"
cap noi !epstopdf "$fig_dir/line-mobile_cumdepositamount.eps"

cd "$fig_dir"
gr combine line-deposits.gph line-depositamount.gph, row(1) col(1) xcommon xsize(6) ysize(8) graphregion(color(white))
gr export "$fig_dir/line-deposits.eps", replace
cap noi !epstopdf "$fig_dir/line-deposits.eps"

cd "$fig_dir"
gr combine line-cumdeposits.gph line-cumdepositamount.gph, row(1) col(1) xcommon xsize(6) ysize(8) graphregion(color(white))
gr export "$fig_dir/line-cumdeposits.eps", replace
cap noi !epstopdf "$fig_dir/line-cumdeposits.eps"

///////////////////////
/* Effects over time */
///////////////////////

use "$data_dir/clean/akiba_long.dta", clear

foreach yvar of varlist mobile_deposits mobile_depositamount {

	mat def M = J(60, 4, .)
	loc varlabel = "`: var la `yvar''"

	reg `yvar' i.treatmentgroup##i.period, vce(cl surveyid)

	mat def M[1, 1] = _b[2.treatmentgroup]
	mat def M[1, 2] = _se[2.treatmentgroup]
	mat def M[1, 3] = _b[3.treatmentgroup]
	mat def M[1, 4] = _se[3.treatmentgroup]

	forval i = 2/60 {

		qui lincom 2.treatmentgroup + 2.treatmentgroup#`i'.period
		mat def M[`i', 1] = r(estimate)
		mat def M[`i', 2] = r(se)

		qui lincom 3.treatmentgroup + 3.treatmentgroup#`i'.period
		mat def M[`i', 3] = r(estimate)
		mat def M[`i', 4] = r(se)

	}

	preserve
	clear
	svmat M

	gen period = _n
	la var period "Savings period (days)"

	gen ub1 = M1 + (M2 * 1.96)
	gen lb1 = M1 - (M2 * 1.96)

	gen ub2 = M3 + (M4 * 1.96)
	gen lb2 = M3 - (M4 * 1.96)

	gr tw (rarea ub1 lb1 period, color(gs12) sort) (line M1 period, color(gs0) lpattern(solid)), title("A: Effect of lottery over time", color(gs0) size(medsmall)) ytitle("Effect size") legend(off) graphregion(color(white)) ylabel(,glcolor(gs14)) saving("$fig_dir/line-timeeffectlottery", replace)

	gr tw (rarea ub2 lb2 period, color(gs12) sort) (line M3 period, color(gs0) lpattern(solid)), title("B: Effect of regret over time", color(gs0) size(medsmall)) ytitle("Effect size") legend(off) graphregion(color(white)) ylabel(,glcolor(gs14)) saving("$fig_dir/line-timeeffectregret", replace)

	cd "$fig_dir"
	gr combine line-timeeffectlottery.gph line-timeeffectregret.gph, row(1) col(1) xcommon xsize(6) ysize(8) graphregion(color(white))
	gr export "$fig_dir/line-time`yvar'.eps", replace
	cap noi !epstopdf "$fig_dir/line-time`yvar'.eps"

	restore

}

//////////////////////////
// Schedule of deposits //
//////////////////////////

use "$data_dir/clean/akiba_mobile.dta", clear
merge m:m account using "$data_dir/clean/akiba_subjects.dta", keep(3) keepusing(attrit treat_type endline_treatmenttype) nogen

recode attrit (1 = 0) (0 = 1) (nonm = .), gen(endline)
gen treatmatch = trim(itrim(lower(treat_type))) == trim(itrim(lower(endline_treatmenttype))) if endline
replace treat_type = trim(itrim(proper(treat_type)))
encode treat_type, gen(treatmentgroup)

gen dailytime = hms(hh(clock(time, "MD20Yhm")), mm(clock(time, "MD20Yhm")), ss(clock(time, "MD20Yhm")))

tw (hist dailytime if type_deposit & treatmentgroup == 1, frac width(1800000) lwidth(thin) lcolor(gs1) fcolor(none)) (hist dailytime if type_deposit & treatmentgroup == 2, frac width(1800000) lwidth(thin) lcolor(gs1) fcolor(gs12)) (hist dailytime if type_deposit & treatmentgroup == 3, frac width(1800000) lwidth(thin) lcolor(gs1) fcolor(gs2)), xline(28800000) xtitle("Time") ylabel(, glwidth(vthin) glcolor(gs14)) xlabel(0(7200000)86400000, format(%tcHH:MM) angle(330)) graphregion(color(white)) legend(order(1 "Control" 2 "Lottery" 3 "Regret"))
gr export "$fig_dir/hist-deposits.eps", replace
cap noi !epstopdf "$fig_dir/hist-deposits.eps"

tw (hist dailytime if type_deposit & inrange(dailytime, 25200000, 36000000) & treatmentgroup == 1, frac width(360000) lwidth(thin) lcolor(gs1) fcolor(none)) (hist dailytime if type_deposit & inrange(dailytime, 25200000, 36000000) & treatmentgroup == 2, frac width(360000) lwidth(thin) lcolor(gs1) fcolor(gs12)) (hist dailytime if type_deposit & inrange(dailytime, 25200000, 36000000) & treatmentgroup == 3, frac width(360000) lwidth(thin) lcolor(gs1) fcolor(gs2)), xline(28800000) xtitle("Time") ylabel(, glwidth(vthin) glcolor(gs14)) xlabel(25200000(720000)36000000,format(%tcHH:MM) angle(330)) graphregion(color(white)) legend(order(1 "Control" 2 "Lottery" 3 "Regret"))
gr export "$fig_dir/hist-zoomdeposits.eps", replace
cap noi !epstopdf "$fig_dir/hist-zoomdeposits.eps"
