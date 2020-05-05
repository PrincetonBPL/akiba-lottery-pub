** Title: akiba_master.do
** Author: Justin Abraham
** Desc: Master do file for recreating dataset and running analysis
** Ensure pwd is set to where this file is located

version 13.1

clear all
set maxvar 10000
set matsize 11000
set more off
set seed 95594731

timer clear
timer on 1

cd "~/repos/akiba-lottery-pub"

///////////
// Setup //
///////////

glo project_dir "`c(pwd)'"
glo ado_dir "$project_dir/code/ado"
glo data_dir "$project_dir/data"
glo do_dir "$project_dir/code/do"
glo fig_dir "$project_dir/figures"
glo tab_dir "$project_dir/tables"

adopath + "$ado_dir"
cap cd "$project_dir"

/* Customize program */

glo builddataflag = 1	// Build combined dataset
glo cleandataflag = 1	// Clean combined dataset
glo summaryflag = 1	 	// Output summary stats
glo estimateflag = 1    // Output regression tables
glo figuresflag = 1		// Output graphs and figures

/* Analysis options */

glo attritionflag = 1	// Attrition analysis
glo maineffectsflag = 1 // Treatment effects (covariate adjustment, multiple inference)
glo riflag = 1			// Tests with randomization inference
glo heteffectsflag = 1  // Heterogenous treatment effects

glo USDconvertflag = 1  // Runs and reports analysis in USD-PPP
glo ppprate = (1/38.84) // PPP exchange rate from KSH (2009-2013)

glo iterations = 10000  // Number of iterations for calculating FWER adjusted p-values
glo riterations = 10000 // Number of iterations for permutation test

/* Regressands by category */

glo ymobiledesc "Mobile savings"
glo yearlydesc "Mobile savings (before 30 days)"
glo ylatedesc "Mobile savings (after 30 days)"
glo ypaneldesc "Mobile savings by period"
glo ysavedesc "Savings outside the project"
glo ygambledesc "Gambling"
glo yakibadesc "Akiba Smart"
glo yconsdesc "Expenditure"
glo yselectdesc "Hypothetical treatment selection"
glo ylotterydesc "Lottery usage"
glo yselfdesc "Self-perceptions"

glo ymobile "mobile_totdeposits mobile_savedays mobile_totdepositamt mobile_totwithdrawalamt"
glo yearly "mobile_earlytotdeposits mobile_earlysavedays mobile_earlyavgdeposits mobile_earlytotdepositamt"
glo ylate "mobile_latetotdeposits mobile_latesavedays mobile_lateavgdeposits mobile_latetotdepositamt"
glo ypanel "mobile_deposits mobile_saved mobile_depositamount mobile_withdrawalamount"
glo ysave "save_monthlysave_1 save_mpesa_1 save_monthlyrosca_1 save_dorosca_1"
glo ygamble "gam_moregamble_1 gam_lessgamble_1 gam_moretempted_1 gam_lesstempted_1"
glo yakiba "akiba_trust_z_1 akiba_confidence_z_1 akiba_family_1 akiba_continue_1"
glo ycons "akiba_spentairtime_1 akiba_spentbus_1 akiba_spentdurables_1 akiba_spentloans_1 akiba_spentfood_1 akiba_spenthouse_1 akiba_spenthealth_1 akiba_spentother_1 akiba_spentsave_1 akiba_spentschool_1 akiba_spenttransfer_1 akiba_spenttravel_1 akiba_spentnone_1"
glo yselect "akiba_controlselect_1 akiba_lotteryselect_1 akiba_regretselect_1 akiba_lotteryeffect_1 akiba_regreteffect_1"
glo ylottery "akiba_lotteryfair_z_1 akiba_prizegood_z_1 akiba_prizebad_z_1"
glo yself "self_saver_z_1 self_lucky_z_1 self_savingsfeel_z_1 self_nosavefeel_z_1"
glo ynull "$ymobile $ysave gam_moregamble_1"
glo yhet "mobile_totdeposits mobile_totdepositamt save_dorosca_1 gam_moregamble_1"

/* Regressors */

glo xhet "demo_female_0 demo_young_0 demo_stdschool_0 demo_formschool_0 demo_married_0 demo_haschild_0 save_dosave_0 labor_medianinc_0 labor_employed_0 labor_selfemployed_0 labor_hasdependant_0 labor_isdependant_0 pref_riskaverse_0 pref_medianloc_0 pref_medianindiff_0 gam_mediancpgi_z_0"
glo xcor "pref_avgindiff_0 pref_avggeometric_0 pref_avgexponential_0 pref_avghyperbolic_0 pref_station_0 pref_decrimp_0 pref_crra_0 pref_locscore_z_0"

/* Control variables */

glo controlvars "demo_female_0 demo_young_0 demo_stdschool_0 demo_haschild_0 demo_married_0 save_dosave_0 gam_mediancpgi_z_0"

/////////////
// Program //
/////////////

glo currentdate = date("$S_DATE", "DMY")
glo date : di %td_CY.N.D date("$S_DATE", "DMY")
glo stamp = trim("$date")

if $builddataflag {

	do "$do_dir/akiba_subjects.do"
	do "$do_dir/akiba_mobile.do"

}

if $cleandataflag do "$do_dir/akiba_clean.do"
if $summaryflag do "$do_dir/akiba_summary.do"
if $figuresflag do "$do_dir/akiba_figures.do"
if $estimateflag do "$do_dir/akiba_estimate.do"

timer off 1
qui timer list 1
di "Finished in `r(t1)' seconds."

///////////
// Notes //
//////////*
