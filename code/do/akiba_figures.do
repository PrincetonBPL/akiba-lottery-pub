** Title: akiba_figures.do
** Author: Justin Abraham
** Desc: Outputs figures
** Input: akiba_wide.dta, akiba_long.dta
** Output: Figures, graphs

/* Treatment effects by CRRA parameter */

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

	twoway (line C1 C5, color(navy)) (line C3 C5, color(maroon)) (rcap ubl lbl C5, color(navy)) (rcap ubr lbr C5, color(maroon)), ytitle("Effect") xtitle("CRRA parameter") legend(order(1 "Lottery" 2 "Regret")) graphregion(color(white))
	graph export "$fig_dir/line-`yvar'byrisk.eps", as(eps) replace
	!epstopdf "$fig_dir/line-`yvar'byrisk.eps"

}

/* Project panel */

if $panelflag {

	use "$data_dir/clean/akiba_long.dta", clear

	estpost tab mobile_matches
	esttab using "$tab_dir/tab-lottery", booktabs unstack noobs nonumber nomtitle label cells("b(label(freq)) pct(fmt(2)) cumpct(fmt(2))") title(Lottery results) replace
	eststo clear

	/* Savings behavior over time */

	collapse (mean) mobile_depositamount mobile_cumdepositamount mobile_deposits mobile_cumdeposits mobile_balance (sem) sem_depositamount = mobile_depositamount sem_cumdepositamount = mobile_cumdepositamount sem_deposits = mobile_deposits sem_cumdeposits = mobile_cumdeposits sem_balance = mobile_balance, by(treatmentgroup period)

	foreach root in depositamount deposits cumdepositamount cumdeposits balance {

		gen ub_`root' = mobile_`root' + sem_`root'
		gen lb_`root' = mobile_`root' - sem_`root'

	}

	graph twoway (line mobile_balance period if treatmentgroup == 1) (line mobile_balance period if treatmentgroup == 2) (line mobile_balance period if treatmentgroup == 3), ytitle("Balance") legend(order(1 "Control" 2 "Lottery" 3 "Regret")) graphregion(color(white))
	graph export "$fig_dir/line-balance.eps", as(eps) replace
	!epstopdf "$fig_dir/line-balance.eps"

	graph twoway (line mobile_depositamount period if treatmentgroup == 1) (line mobile_depositamount period if treatmentgroup == 2) (line mobile_depositamount period if treatmentgroup == 3), ytitle("Deposit amount") legend(order(1 "Control" 2 "Lottery" 3 "Regret")) graphregion(color(white))
	graph export "$fig_dir/line-depositamount.eps", as(eps) replace
	!epstopdf "$fig_dir/line-depositamount.eps"

	graph twoway (line mobile_cumdepositamount period if treatmentgroup == 1) (line mobile_cumdepositamount period if treatmentgroup == 2) (line mobile_cumdepositamount period if treatmentgroup == 3) (rcap ub_cumdepositamount lb_cumdepositamount period if treatmentgroup == 1 & period == 60, color(navy)) (rcap ub_cumdepositamount lb_cumdepositamount period if treatmentgroup == 2 & period == 60, color(maroon)) (rcap ub_cumdepositamount lb_cumdepositamount period if treatmentgroup == 3 & period == 60, color(green)), ytitle("Amount deposited") legend(order(1 "Control" 2 "Lottery" 3 "Regret")) graphregion(color(white))
	graph export "$fig_dir/line-cumdepositamount.eps", as(eps) replace
	!epstopdf "$fig_dir/line-cumdepositamount.eps"

	graph twoway (line mobile_deposits period if treatmentgroup == 1) (line mobile_deposits period if treatmentgroup == 2) (line mobile_deposits period if treatmentgroup == 3), ytitle("No. of deposits") legend(order(1 "Control" 2 "Lottery" 3 "Regret")) graphregion(color(white))
	graph export "$fig_dir/line-deposits.eps", as(eps) replace
	!epstopdf "$fig_dir/line-deposits.eps"

	graph twoway (line mobile_cumdeposits period if treatmentgroup == 1) (line mobile_cumdeposits period if treatmentgroup == 2) (line mobile_cumdeposits period if treatmentgroup == 3) (rcap ub_cumdeposits lb_cumdeposits period if treatmentgroup == 1 & period == 60, color(navy)) (rcap ub_cumdeposits lb_cumdeposits period if treatmentgroup == 2 & period == 60, color(maroon)) (rcap ub_cumdeposits lb_cumdeposits period if treatmentgroup == 3 & period == 60, color(green)), ytitle("No. of deposits") legend(order(1 "Control" 2 "Lottery" 3 "Regret")) graphregion(color(white))
	graph export "$fig_dir/line-cumdeposits.eps", as(eps) replace
	!epstopdf "$fig_dir/line-cumdeposits.eps"

	/* Convert eps to pdf for Latex */

	!epstopdf "$fig_dir/*.eps"

	/* Autoregressive plot */

	* use "$data_dir/clean/akiba_long.dta", clear

	* areg Saved_Day L(1/$laglength).Saved_Day if control, absorb(day) cl(surveyid)

	* loc k = e(rank)
	* mat V = e(V)
	* mat A_b = e(b)'
	* mat A_se = J(`k',1,-9999)
	* forval i = 1/`k' {
	* 	mat A_se[`i', 1] = sqrt(V[`i', `i'])
	* }

	* areg Saved_Day L(1/$laglength).Saved_Day if lottery, absorb(day) cl(surveyid)

	* loc k = e(rank)
	* mat V = e(V)
	* mat B_b = e(b)'
	* mat B_se = J(`k',1,-9999)
	* forval i = 1/`k' {
	* 	mat B_se[`i', 1] = sqrt(V[`i', `i'])
	* }

	* areg Saved_Day L(1/$laglength).Saved_Day if regret, absorb(day) cl(surveyid)

	* loc k = e(rank)
	* mat V = e(V)
	* mat C_b = e(b)'
	* mat C_se = J(`k',1,-9999)
	* forval i = 1/`k' {
	* 	mat C_se[`i', 1] = sqrt(V[`i', `i'])
	* }

	* foreach matr in A_b A_se B_b B_se C_b C_se {
	* 	svmat `matr'
	* }

	* keep A_b A_se B_b B_se C_b C_se
	* gen lag = _n
	* drop if lag > $laglength

	* foreach i in A B C {

	* 	gen `i'_hici = `i'_b + 1.96*`i'_se
	* 	gen `i'_loci = `i'_b - 1.96*`i'_se

	* }

	* graph twoway (line A_b lag) (line B_b lag) (line C_b lag), ytitle("Likelihood of saving") xtitle("Lag in days") legend(order(1 "Control" 2 "Lottery" 3 "Regret")) graphregion(color(white))
	* graph export "$fig_dir/line-ar.eps", as(eps) replace

	* /Distributed lag plot */

	* use "$data_dir/clean/akiba_long.dta", clear

	* areg Saved_Day L(1/$laglength).Won_Day L(1/$laglength).Regret_Day L(1/$laglength).Lost_Day if ~control, absorb(day) cl(surveyid)

	* loc k = e(rank)
	* mat V = e(V)
	* mat B = e(b)'
	* mat SE = J(`k',1,-9999)
	* forval i = 1/`k' {
	* 	mat SE[`i', 1] = sqrt(V[`i', `i'])
	* }

	* svmat B
	* svmat SE
	* keep B SE
	* gen lag = _n
	* gen day_type = 0

	* replace day_type = 1 if lag > $laglength & lag <= 2*$laglength
	* replace lag = lag - $laglength if lag > $laglength & lag <= 2*$laglength

	* replace day_type = 2 if lag > 2*$laglength & lag <= 3*$laglength
	* replace lag = lag - 2*$laglength if lag > 2*$laglength & lag <= 3*$laglength

	* drop if lag > $laglength

	* graph twoway (line B lag if day_type == 0) (line B lag if day_type == 1) (line B lag if day_type == 2), ytitle("Likelihood of saving") xtitle("Lag in days") legend(order(1 "Won prize" 2 "Won without saving" 3 "Lost with saving")) graphregion(color(white))
	* graph export "$fig_dir/line-dl.eps", as(eps) replace

}
