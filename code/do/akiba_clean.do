** Title: akiba_clean.do
** Author: Justin Abraham
** Desc: Prepares merged final data for analysis
** Input: akiba_subjects.dta, akiba_mobile.dta
** Output: akiba_wide.dta, akiba_long.dta

use "$data_dir/clean/akiba_subjects.dta", clear

************
** Survey **
************

la def la_yesno 0 "No" 1 "Yes"

replace surveyid = personid
la var surveyid "Survey ID"

la var account "Unique account no."
la var in_pilot "Participated in pilot study"

recode auth (1 = 0) (0 = 1) (nonm = .), gen(left_akiba)
la var left_akiba "Left mid-project"

ren ps_foname FO_0
la var FO_0 "Field officer"

ren nameoffieldofficer FO_1
la var FO_1 "Field officer"

ren session sessionstr
encode sessionstr, gen(session)
la var session "Lab session"

la var attrit "Unobserved at endline"
la def la_attrit 0 "Completed" 1 "Attrited"
la val attrit la_attrit

recode attrit (1 = 0) (0 = 1) (nonm = .), gen(endline)
la var endline "Completed endline"
la def la_endline 0 "Attrited" 1 "Completed"
la val endline la_endline

gen enroll_date = mdyhms(month(enrollmentdate), day(enrollmentdate), year(enrollmentdate), hh(enrollmentstart), mm(enrollmentstart), ss(enrollmentstart))
format enroll_date %tCDD_Mon_YY_HH:MM:SS
la var enroll_date "Enrollment date"

gen survey_date = mdyhms(month(identifydate), day(identifydate), year(identifydate), hh(identifystart), mm(identifystart), ss(identifystart))
format survey_date %tCDD_Mon_YY_HH:MM:SS
la var survey_date "Survey date"

replace nrblocation = 0 if inkibera == 1
la def nrblocation 0 "kibera", add

drop if mi(surveyid, account)

***************
** Treatment **
***************

gen treatmatch = trim(itrim(lower(treat_type))) == trim(itrim(lower(endline_treatmenttype))) if endline
replace treat_type = trim(itrim(proper(treat_type)))
encode treat_type, gen(treatmentgroup)
la var treatmentgroup "Treatment group"

tab treatmentgroup, gen(treat)

ren treat1 control
la var control "Interest"
ren treat2 lottery
la var lottery "Lottery"
ren treat3 regret
la var regret "Regret"

gen treated = ~control
la var treated "Treated"

drop if mi(treatmentgroup)

******************
** Demographics **
******************

gen demo_female_0 = labgender - 1
la var demo_female_0 "Female"

gen demo_age_0 = labage
replace demo_age_0 = age if mi(demo_age_0)
recode demo_age_0 (min/17 99/max = .)
la var demo_age_0 "Age"

xtile demo_young_0 = demo_age_0, n(2)
replace demo_young_0 = 2 - demo_young_0
la var demo_young_0 "Below 30 y.o."

ren education demo_education_0

gen demo_stdschool_0 = demo_education > 9
la var demo_stdschool_0 "Completed std. 8"

gen demo_formschool_0 = demo_education > 13
la var demo_formschool_0 "Completed formal 4"

ren nativelanguage demo_language_0
ren nativelanguage_spec demo_language_spec_0

ren labnum_child demo_children_0
la var demo_children_0 "No. of children"

gen demo_haschild_0 = demo_children_0 > 0 if ~mi(demo_children_0)
la var demo_haschild_0 "Has children"

ren labmarital_status demo_marital_0
la var demo_marital_0 "Marital status"

recode demo_marital_0 (3 4 5 = 0) (1 2 = 1) (nonm = .), gen(demo_married_0)
la var demo_married_0 "Married/co-habitating"

***********
** Labor **
***********

ren occupation labor_job_0
ren occupation_spec labor_jobspec_0

ren labemployment labor_empstatus_0
la var labor_empstatus_0 "Employment status"

recode labor_empstatus_0 (1 2 = 1) (3 = 0), gen(labor_employed_0)
la var labor_employed_0 "Employed"

gen labor_selfemployed_0 = selfemployed - 1
replace labor_selfemployed_0 = 0 if ~labor_employed_0
la var labor_selfemployed_0 "Self-employed"

gen labor_isdependant_0 = 2 - labsupported_dummy
la var labor_isdependant_0 "Subject is a dependant"

ren labnum_dependants labor_dependants_0
la var labor_dependants_0 "No. of dependants"

gen labor_hasdependant_0 = labor_dependants_0 > 0 if ~mi(labor_dependants_0)
la var labor_hasdependant_0 "Has dependant"

recode labor_empstatus_0 (1 = 1) (2 = 0) (3 = .), gen(labor_regularinc_0)
la var labor_regularinc_0 "Receives regular income"

ren labinc_permonth labor_monthlyinc_0
la var labor_monthlyinc_0 "Monthly income"

ren endline_pastmonth_earnings labor_monthlyinc_1
la var labor_monthlyinc_1 "Monthly income"

forval i = 0/1 {

	if $USDconvertflag {

		replace labor_monthlyinc_`i' = labor_monthlyinc_`i' * $ppprate
		loc pppla "`:var la labor_monthlyinc_`i'' (USD PPP)"
		la var labor_monthlyinc_`i' "`pppla'"

	}

	gen lnlabor_monthlyinc_`i' = asinh(labor_monthlyinc_`i')
	la var lnlabor_monthlyinc_`i' "Log monthly income"

}

xtile labor_medianinc_0 = labor_monthlyinc_0, n(2)
replace labor_medianinc_0 = labor_medianinc_0 - 1
la var labor_medianinc_0 "Above median monthly inc."

*************
** Savings **
*************

gen save_dosave_0 = 2 - labsaving_yesno
la var save_dosave_0 "Currently saves"

ren labtot_save_pastmonth save_monthlysave_0
la var save_monthlysave_0 "Total savings last month"

ren endline_totalsavings_pastmonth save_monthlysave_1
la var save_monthlysave_1 "Total savings last month"

ren labtot_save_MPESA save_mpesa_0
la var save_mpesa_0 "M-Pesa savings last month"

ren endline_mpesa save_mpesa_1
la var save_mpesa_1 "M-Pesa savings last month"

recode labrosca_yesno (1 = 1) (2 = 0) (nonm = .), gen(save_dorosca_0)
la var save_dorosca_0 "Currently saves with ROSCA"

replace endline_ROSCA = trim(lower(endline_ROSCA))
encode endline_ROSCA, gen(save_dorosca_1)
replace save_dorosca_1 = save_dorosca_1 - 1
la var save_dorosca_1 "Currently saves with ROSCA"

ren labrosca_monthly save_monthlyrosca_0
la var save_monthlyrosca_0 "ROSCA savings last month"

gen save_monthlyrosca_1 = real(endline_ROSCA_monthly)
la var save_monthlyrosca_1 "ROSCA savings last month"

gen save_othersavings_0 = save_monthlysave_0 - save_monthlyrosca_0 - save_mpesa_0
la var save_othersavings_0 "Other savings last month"

gen save_othersavings_1 = save_monthlysave_1 - save_monthlyrosca_1 - save_mpesa_1
la var save_othersavings_1 "Other savings last month"

forval i = 0/1 {

	replace save_monthlyrosca_`i' = 0 if save_dorosca_`i' == 0

	if $USDconvertflag {

		foreach var of varlist save_monthlysave_`i' save_mpesa_`i' save_monthlyrosca_`i' save_othersavings_`i' {

			replace `var' = `var' * $ppprate
			loc pppla "`:var la `var'' (USD PPP)"
			la var `var' "`pppla'"

		}

	}

	gen save_propincome_`i' = save_monthlysave_`i' / labor_monthlyinc_`i'
	la var save_propincome_`i' "Monthly savings rate"

	gen lnsave_monthlysave_`i' = asinh(save_monthlysave_`i')
	la var lnsave_monthlysave_`i' "Log total savings last month"

	gen lnsave_mpesa_`i' = asinh(save_mpesa_`i')
	la var lnsave_mpesa_`i' "Log M-Pesa savings last month"

	gen lnsave_monthlyrosca_`i' = asinh(save_monthlyrosca_`i')
	la var lnsave_monthlyrosca_`i' "Log ROSCA savings last month"

	gen lnsave_othersavings_`i' = asinh(save_othersavings_`i')
	la var lnsave_othersavings_`i' "Log other savings last month"

}

xtile lnsave_mediansave_0 = lnsave_monthlysave_0, n(2)
replace lnsave_mediansave_0 = lnsave_mediansave_0 - 1
la var lnsave_mediansave_0 "Above median monthly savings"

**************
** Gambling **
**************

forval i = 1/13 {

	ren gamblingfreq`i' gam_freq`i'_0

}
*
egen gam_index_0 = weightave(gam_freq*), normby(control)
la var gam_index_0 "Weighted index of gambling frequency"

xtile gam_medianindex_0 = gam_index_0, n(2)
replace gam_medianindex_0 = gam_medianindex_0 - 1
la var gam_medianindex_0 "Above median gamb. index"

/* Canadian Problem Gambling Index */

ren cpgi gam_cpgi_0
la var gam_cpgi_0 "Canadian Problem Gambling Index"

egen gam_cpgi_z_0 = weightave(gam_cpgi_0), normby(control)
la var gam_cpgi_z_0 "Standardized CPGI"

xtile gam_mediancpgi_z_0 = gam_cpgi_z_0, n(2)
replace gam_mediancpgi_z_0 = gam_mediancpgi_z_0 - 1
la var gam_mediancpgi_z_0 "Above median CPGI"

/* Endline gambling measures */

encode endline_gambling_temptation, gen(gam_temptation_1)

recode gam_temptation_1 (1 = 1) (2 3 = 0), gen(gam_lesstempted_1)
la var gam_lesstempted_1 "Less tempted to gamble"

recode gam_temptation_1 (2 = 1) (1 3 = 0), gen(gam_moretempted_1)
la var gam_moretempted_1 "More tempted to gamble"

encode endline_gambling_freq, gen(gam_behavior_1)

recode gam_behavior_1 (1 = 1) (2 3 = 0), gen(gam_lessgamble_1)
la var gam_lessgamble_1 "Gamble less"

recode gam_behavior_1 (3 = 1) (1 2 = 0), gen(gam_moregamble_1)
la var gam_moregamble_1 "Gamble more"

ren wtplottery gam_wtp_0
la var gam_wtp_0 "WTP for lottery"

xtile gam_wtpmedian_0 = gam_wtp_0, n(2)
replace gam_wtpmedian_0 = gam_wtpmedian_0 - 1
la var gam_wtpmedian_0 "Above median WTP for lottery"

*****************
** Preferences **
*****************

/* Temporal discounting */

gen pref_ssamount = 100
la var pref_ssamount "Smaller, sooner amount"

gen pref_llamount = 1000
la var pref_llamount "Larger, later amount"

ren indiff* pref_indiff*_0

la var pref_indiff1_0 "Indiff. point (0 wk. - 2 wk.)"
la var pref_indiff2_0 "Indiff. point (0 wk. - 4 wk.)"
la var pref_indiff3_0 "Indiff. point (0 wk. - 12 wk.)"
la var pref_indiff4_0 "Indiff. point (2 wk. - 4 wk.)"

forval i = 1/4 {

	loc varlab: var la pref_indiff`i'_0
	loc t0 = real(substr("`varlab'", 16, 1))
	loc t = real(substr("`varlab'", 24, length("`varlab'") - 27))

	gen pref_geometric`i'_0 = (pref_ssamount/pref_indiff`i'_0)^-(52/`t'-`t0') - 1
	la var pref_geometric`i'_0 "Geo. discount factor"

	gen pref_exponential`i'_0 = -ln(pref_ssamount/pref_indiff`i'_0)/(`t'-`t0'/52)
	la var pref_exponential`i'_0 "Exp. discount factor"

	gen pref_hyperbolic`i'_0 = (pref_indiff`i'_0/pref_ssamount - 1)/(`t'-`t0'/52)
	la var pref_hyperbolic`i'_0 "Hyp. discount factor"

}

egen pref_avgindiff_0 = rowmean(pref_indiff*)
la var pref_avgindiff_0 "Avg. indiff. point"

xtile pref_medianindiff_0 = pref_avgindiff_0, n(2)
replace pref_medianindiff_0 = pref_medianindiff_0 - 1
la var pref_medianindiff_0 "Above median i. point"

egen pref_avggeometric_0 = rowmean(pref_geometric*)
la var pref_avggeometric_0 "Geo. discount factor"

egen pref_avgexponential_0 = rowmean(pref_exponential*)
la var pref_avgexponential_0 "Exp. discount factor"

egen pref_avghyperbolic_0 = rowmean(pref_hyperbolic*)
la var pref_avghyperbolic_0 "Hyp. discount factor"

gen pref_station_0 = pref_exponential4_0 - pref_exponential1_0
la var pref_station_0 "Dept. from stationarity"

gen pref_decrimp1 = pref_exponential2_0 - pref_exponential1_0
gen pref_decrimp2 = pref_exponential3_0 - pref_exponential2_0

egen pref_decrimp_0 = rowmean(pref_decrimp*)
la var pref_decrimp_0 "Decreasing impatience"

ren MPLRT pref_MPLRT
ren influence pref_influence

foreach v of varlist gam_wtp_0 pref_indiff* pref_*amount {

	if $USDconvertflag {

		replace `v' = `v' * $ppprate
		loc pppla "`:var la `v'' (USD PPP)"
		la var `v' "`pppla'"

	}

}

/* Risk aversion */

gen pref_crra_0 = MPLChoice
recode pref_crra_0 (1=3.45971) (2=2.31018) (3=0.933116) (4=0.602097) (5=0.249306) (6=0)
la var pref_crra_0 "Coefficient of relative risk aversion"

xtile pref_riskaverse_0 = pref_crra_0, n(2)
replace pref_riskaverse_0 = pref_riskaverse_0 - 1
la var pref_riskaverse_0 "Risk averse"

/* Locus of control */

ren loc_score pref_locscore_0
la var pref_locscore_0 "Locus of control"

egen pref_locscore_z_0 = weightave(pref_locscore_0), normby(control)
la var pref_locscore_z_0 "Locus of control"

xtile pref_medianloc_0 = pref_locscore_z_0, n(2)
replace pref_medianloc_0 = pref_medianloc_0 - 1
la var pref_medianloc_0 "Above median LOC"

/* Self-perceptions */

ren endline_lucky self_lucky_1
ren endline_saver self_saver_1
la var self_saver_1 "Do you see yourself as a saver?"

xtile temp = self_lucky_1, n(2)
gen self_lucky_upper_1 = .
la var self_lucky_upper_1 "Lucky"
replace self_lucky_upper_1 = temp - 1
drop temp

xtile temp = self_saver_1, n(2)
gen self_saver_upper_1 = .
la var self_saver_upper_1 "Saver"
replace self_saver_upper_1 = temp - 1
drop temp

ren endline_savingsfeel self_savingsfeel_1
la var self_savingsfeel_1 "Do you feel you saved enough?"

ren endline_past2mo_feel self_nosavefeel_1
la var self_nosavefeel_1 "How did you feel not saving?"

********************
** Akiba feedback **
********************

ren endline_akibatrust akiba_trust_1
la var akiba_trust_1 "How much do you trust Akiba Smart?"

ren endline_akibaconfidence akiba_confidence_1
la var akiba_confidence_1 "What is your confidence in Akiba Smart?"

ren endline_lotterytrust akiba_lotteryfair_1
replace akiba_lotteryfair_1 = . if control

ren endline_prizegood akiba_prizegood_1
replace akiba_prizegood_1 = . if control

ren endline_prizebad akiba_prizebad_1
replace akiba_prizebad_1 = . if control

recode akiba_rules (5 = 0) (nonm = 1), gen(akiba_rules_1)
la var akiba_rules_1 "Can describe rules of AKIBA"

encode endline_chooseplan, gen(akiba_select_1)
la var akiba_select_1 "Group self-selection"

la def la_select 1 "Interest" 2 "Lottery" 3 "Regret"
la val akiba_select_1 la_select

tab akiba_select_1, gen(akiba_select)

ren akiba_select1 akiba_controlselect_1
la var akiba_controlselect_1 "Select control group"

ren akiba_select2 akiba_lotteryselect_1
la var akiba_lotteryselect_1 "Select lottery group"

ren akiba_select3 akiba_regretselect_1
la var akiba_regretselect_1 "Select regret group"

gen akiba_controlsave_1 = real(endline_plan1save)
la var akiba_controlsave_1 "Save with control"

gen akiba_lotterysave_1 = real(endline_plan2save)
la var akiba_lotterysave_1 "Save with lottery"

gen akiba_regretsave_1 = real(endline_plan3save)
la var akiba_regretsave_1 "Save with regret"

gen akiba_lotteryeffect_1 = akiba_lotterysave_1 - akiba_controlsave_1
la var akiba_lotteryeffect_1 "Perceived effect of lottery"

gen akiba_regreteffect_1 = akiba_regretsave_1 - akiba_controlsave_1
la var akiba_regreteffect_1 "Perceived effect of regret"

ren endline_comments akiba_comments_1
ren endline_moneyspent akiba_spent_1
ren endline_fam_friends_howoften akiba_familyspec_1

gen akiba_spentfood_1 = strpos(lower(akiba_spent_1), "food") if ~mi(akiba_spent_1)
la var akiba_spentfood_1 "Spent balance on food"
gen akiba_spentschool_1 = strpos(lower(akiba_spent_1), "school") if ~mi(akiba_spent_1)
la var akiba_spentschool_1 "Spent balance on school"
gen akiba_spentbus_1 = strpos(lower(akiba_spent_1), "business") if ~mi(akiba_spent_1)
la var akiba_spentbus_1 "Spent balance on business"
gen akiba_spentdura_1 = strpos(lower(akiba_spent_1), "cloth") | strpos(lower(akiba_spent_1), "furniture") | strpos(lower(akiba_spent_1), "chick") | strpos(lower(akiba_spent_1), "tank") | strpos(lower(akiba_spent_1), "mirro") if ~mi(akiba_spent_1)
la var akiba_spentdura_1 "Spent balance on durable goods"
gen akiba_spentdebt_1 = strpos(lower(akiba_spent_1), "paid") | strpos(lower(akiba_spent_1), "paying") | strpos(lower(akiba_spent_1), "rent") | strpos(lower(akiba_spent_1), "debt") | strpos(lower(akiba_spent_1), "utilit") if ~mi(akiba_spent_1)
la var akiba_spentdebt_1 "Spent balance on repaying loans"
gen akiba_spentsave_1 = strpos(lower(akiba_spent_1), "saving") | strpos(lower(akiba_spent_1), "merry") if ~mi(akiba_spent_1)
la var akiba_spentsave_1 "Saved balance"

replace endline_fam_friends = trim(itrim(lower(endline_fam_friends)))
encode endline_fam_friends, gen(akiba_family_1)
replace akiba_family_1 = akiba_family_1 - 1
la var akiba_family_1 "Did you tell friends and famiy about AKIBA?"

replace endline_akiba_anotheryr = trim(lower(endline_akiba_anotheryr))
encode endline_akiba_anotheryr, gen(akiba_continue_1)
recode akiba_continue_1 (1 = 0) (2 = 1) (3 = .)
la var akiba_continue_1 "Continue saving with AKIBA"

foreach v of varlist akiba_trust_1 akiba_confidence_1 self_savingsfeel_1 self_nosavefeel_1 self_saver_1 self_lucky_1 akiba_lotteryfair_1 akiba_prizebad_1 akiba_prizegood_1 {

	loc root = substr("`v'", 1, length("`v'") - 2)
	loc vlabel : var label `v'
	egen `root'_z_1 = weightave(`v'), normby(control)
	la var `root'_z_1 "`vlabel'"

}

foreach v of varlist akiba_controlsave_1 akiba_lotterysave_1 akiba_regretsave_1 akiba_lotteryeffect_1 akiba_regreteffect_1 {

	if $USDconvertflag {

		replace `v' = `v' * $ppprate
		loc pppla "`: var la `v'' (USD PPP)"
		la var `v' "`pppla'"

	}

	gen ln`v' = asinh(`v')
	loc loglabel : var label `v'
	loc loglabel = "Log " + lower("`loglabel'")
	la var ln`v' "`loglabel'"

}

tempfile clean_subjects
save `clean_subjects', replace

********************
** Mobile savings **
********************

use "$data_dir/clean/akiba_mobile.dta"

la var period "Period"

gen period_date = dofc(clock(time, "MD20Yhm"))
format period_date %tdDD_Mon_YY
la var period_date "Date of savings period"

gen mobile_depositamount = amount if type_deposit
gen mobile_refundamount = amount if type_refund
gen mobile_prizeamount = amount if type_prize
gen mobile_withdrawalamount = amount if type_withdrawal

collapse (mean) ticketid participantticket winningticket matchtype awarded (sum) mobile_*amount type_*, by(account period period_date)

/* Transaction amounts */

la var mobile_depositamount "Amount deposited"
la var mobile_refundamount "Amount refunded"
la var mobile_prizeamount "Amount received as prize"

replace mobile_withdrawalamount = abs(mobile_withdrawalamount)
la var mobile_withdrawalamount "Amount withdrew"

egen mobile_netamount = rowtotal(mobile_depositamount mobile_refundamount mobile_prizeamount), m
replace mobile_netamount = mobile_netamount - mobile_withdrawalamount if ~mi(mobile_withdrawalamount)
la var mobile_netamount "Net transaction amount"

/* Transaction types */

ren type_deposit mobile_deposits
la var mobile_deposits "No. of deposits made"

ren type_refund mobile_refunds
la var mobile_refunds "No. of refunds made"

ren type_prize mobile_prizes
la var mobile_prizes "No. of prizes won"

ren type_withdrawal mobile_withdrawals
la var mobile_withdrawals "No. of withdrawals made"

/* Lottery tickets */

la var participantticket "Ticket no."
la var winningticket "Winning ticket no."

ren matchtype mobile_matches
la var mobile_matches "No. of matches on ticket"

/* Merge with subjects data */

merge m:1 account using `clean_subjects', keep(2 3) // Why are there 24 unmatched from subjects? They're not in the raw ledger data and didn't use account

/* Create balanced panel for days without account activity */

replace period = 1 if _merge == 2

xtset surveyid period
tsfill, full

bys surveyid: egen mobile_nonuser = mode(_merge)
recode mobile_nonuser (2 = 1) (3 = 0)
la var mobile_nonuser "Never used mobile savings"

/* Set mobile savings variables to 0 for days without account activity */

foreach var of varlist mobile_*amount mobile_deposits mobile_refunds mobile_prizes mobile_withdrawals {

	replace `var' = 0 if mi(treatmentgroup)

}

/* Expand subject-level variables to all periods for days without account activity */

foreach var of varlist account in_pilot left_akiba control lottery regret treated endline attrit session *_date FO_* demo_* labor_* lnlabor_* save_* lnsave_* gam_* pref_* self_* akiba_* lnakiba_* mobile_nonuser treatmentgroup {

	bysort surveyid: egen `var'_temp = mode(`var'), maxmode
	replace `var' = `var'_temp if mi(treatmentgroup)
	drop `var'_temp

}

drop _merge

/* Cumulative outcomes at the participant-period level */

sort account period

bysort account: gen mobile_balance = sum(mobile_netamount)
la var mobile_balance "Current balance"

gen temp_finalbalance = mobile_balance if period == 60
bysort account: egen mobile_finalbalance = mode(temp_finalbalance)
la var mobile_finalbalance "Balance at end of project"

bysort account: gen mobile_cumdepositamount = sum(mobile_depositamount)
la var mobile_cumdepositamount "Cumulative deposit amount"

bysort account: gen mobile_cumdeposits = sum(mobile_deposits)
la var mobile_cumdeposits "Cumulative deposits made"

/* Daily mobile savings activity */

gen mobile_saved = mobile_depositamount > 0 & ~mi(mobile_depositamount)
la var mobile_saved "Made a deposit"

gen mobile_withindeposits = mobile_deposits if mobile_saved == 1
la var mobile_withindeposits "No. of deposits on days saved"

gen mobile_matched = mobile_matches > 0 & ~mi(mobile_matches)
la var mobile_matched "Winning ticket"

gen mobile_awarded = mobile_matched == 1 & mobile_saved == 1 & control == 0
la var mobile_awarded "Awarded prize"

/* Outcomes for early-late periods */

gen mobile_earlydeposits = mobile_deposits if period <= 30
la var mobile_earlydeposits "No. of deposits (before 30 days)"

gen mobile_earlydepositamount = mobile_depositamount if period <= 30
la var mobile_earlydepositamount "Amount deposited (before 30 days)"

gen mobile_earlysaved = mobile_saved if period <= 30
la var mobile_earlysaved "Made a deposit (before 30 days)"

gen mobile_latedeposits = mobile_deposits if period > 30
la var mobile_latedeposits "No. of deposits (after 30 days)"

gen mobile_latedepositamount = mobile_depositamount if period > 30
la var mobile_latedepositamount "Made a deposit (after 30 days)"

gen mobile_latesaved = mobile_saved if period > 30
la var mobile_latesaved "Amount deposited (after 30 days)"

foreach v of varlist mobile_balance mobile_finalbalance mobile_*amount {

	if $USDconvertflag {

		replace `v' = `v' * $ppprate
		loc pppla "`:var la `v'' (USD PPP)"
		la var `v' "`pppla'"

	}

	gen ln`v' = asinh(`v')
	loc loglabel : var label `v'
	loc loglabel = "Log " + lower("`loglabel'")
	la var ln`v' "`loglabel'"

}

/* Save panel dataset */

keep surveyid account period period_date in_pilot left_akiba nrblocation kiberalocation treatmentgroup control lottery regret treated endline attrit participantticket winningticket mobile_* lnmobile_* session *_date FO_* demo_* labor_* lnlabor_* save_* lnsave_* gam_* pref_* self_* akiba_* lnakiba_*
order surveyid account period period_date in_pilot left_akiba nrblocation kiberalocation treatmentgroup control lottery regret treated endline attrit participantticket winningticket mobile_* lnmobile_* session *_date FO_* demo_* labor_* lnlabor_* save_* lnsave_* gam_* pref_* self_* akiba_* lnakiba_*
order *_0 *_1, after(survey_date)

qui compress
label data "Produced by akiba_clean.do on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)'"
save "$data_dir/clean/akiba_long.dta", replace

************************
** Subject-level data **
************************

keep account period* mobile_*

collapse ///
	(mean) mobile_finalbalance = mobile_finalbalance mobile_avgdeposits = mobile_deposits mobile_avgdepositamt = mobile_depositamount mobile_avgrefunds = mobile_refunds mobile_avgrefundamt = mobile_refundamount mobile_avgprizes = mobile_prizes mobile_avgprizeamt = mobile_prizeamount mobile_avgwithdrawals = mobile_withdrawals mobile_avgwithdrawalamt = mobile_withdrawalamount mobile_earlyavgdeposits = mobile_earlydeposits mobile_lateavgdeposits = mobile_latedeposits ///
	(sum) mobile_totdeposits = mobile_deposits mobile_totdepositamt = mobile_depositamount mobile_totrefunds = mobile_refunds mobile_totrefundamt = mobile_refundamount mobile_totprizes = mobile_prizes mobile_totprizeamt = mobile_prizeamount mobile_totwithdrawals = mobile_withdrawals mobile_totwithdrawalamt = mobile_withdrawalamount mobile_totmatches = mobile_matched mobile_savedays = mobile_saved mobile_earlytotdeposits = mobile_earlydeposits mobile_earlytotdepositamt = mobile_earlydepositamount mobile_earlysavedays = mobile_earlysaved mobile_latetotdeposits = mobile_latedeposits mobile_latetotdepositamt = mobile_latedepositamount mobile_latesavedays = mobile_latesaved ///
	(max) mobile_nonuser = mobile_nonuser ///
	(min) mobile_startdate = period_date ///
, by(account)

merge 1:1 account using `clean_subjects', nogen

foreach root in deposit refund prize withdrawal {

	gen mobile_no`root's = mobile_tot`root's == 0
	la var mobile_no`root's "No `root's made"

	la var mobile_avg`root's "Daily avg. no. of `root's"
	la var mobile_avg`root'amt "Daily avg. `root' amount"
	la var mobile_tot`root's "Total no. of `root's"
	la var mobile_tot`root'amt "Total `root' amount"

}

gen mobile_anydeposit = mobile_totdeposits > 0
la var mobile_anydeposit "Made at least one deposit"

gen mobile_withdrew = mobile_totwithdrawals > 0 | ~mi(mobile_totwithdrawals)
la var mobile_withdrew "Withdrew at day 30"

foreach v of varlist mobile_finalbalance mobile_*amt {

	gen ln`v' = asinh(`v')
	loc loglabel : var label `v'
	loc loglabel = "Log " + lower("`loglabel'")
	la var ln`v' "`loglabel'"

}

la var mobile_earlytotdeposits "Total no. of deposits (before 30 days)"
la var mobile_earlytotdepositamt "Total deposit amount (before 30 days)"
la var mobile_earlysavedays "No. of days saved (before 30 days)"
la var mobile_earlyavgdeposits "Daily avg. no. of deposits (before 30 days)"

la var mobile_latetotdeposits "Total no. of deposits (after 30 days)"
la var mobile_latetotdepositamt "Total deposit amount (after 30 days)"
la var mobile_latesavedays "No. of days saved (after 30 days)"
la var mobile_lateavgdeposits "Daily avg. no. of deposits (after 30 days)"

la var mobile_finalbalance "Final balance"
la var mobile_savedays "No. of days saved"
la var mobile_totmatches "No. of hypothetical and realized lottery wins"
la var mobile_nonuser "Never used mobile savings"
la var mobile_startdate "Savings period start date"

/* Save subjects dataset */

keep surveyid account in_pilot left_akiba nrblocation kiberalocation treatmentgroup control lottery regret treated endline attrit session *_date FO_* demo_* mobile_* lnmobile_* labor_* lnlabor_* save_* lnsave_* gam_* pref_* self_* akiba_* lnakiba_*
order surveyid account in_pilot left_akiba nrblocation kiberalocation treatmentgroup control lottery regret treated endline attrit session *_date FO_* demo_* mobile_* lnmobile_* labor_* lnlabor_* save_* lnsave_* gam_* pref_* self_* akiba_* lnakiba_*
order *_0 *_1, after(survey_date)

qui compress
label data "Produced by akiba_clean.do on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)'"
saveold "$data_dir/clean/akiba_wide.dta", replace
