** Title: akiba_master.do
** Author: Justin Abraham
** Desc: Master do file for re-creating dataset and running analysis
** New users must change filepaths to point to your local repository

version 13.1

clear all
set maxvar 10000
set matsize 11000
set more off
set seed 95594731

timer clear
timer on 1

cd "../../"

***********
** Setup **
***********

glo project_dir "`c(pwd)'"
glo ado_dir "$project_dir/code/ado/personal"
glo data_dir "$project_dir/data"
glo do_dir "$project_dir/code/do"
glo fig_dir "$project_dir/figures"
glo tab_dir "$project_dir/tables"

adopath + "$ado_dir"
cap cd "$project_dir"

/* Typeface for graphics */

loc graphfont "CMU Serif"

graph set eps fontface "`graphfont'"
graph set eps fontfaceserif "`graphfont'"
graph set window fontface "`graphfont'"
graph set window fontfaceserif "`graphfont'"

/* Customize program */

glo builddataflag = 1		 // Build combined dataset
glo cleandataflag = 1		 // Clean combined dataset
glo summaryflag = 1	 		 // Output summary stats
glo estimateflag = 1         // Output regression tables
glo figuresflag = 1			 // Output graphs and figures

/* Analysis options */

glo attritionflag = 1		 // Attrition analysis
glo maineffectsflag = 1      // Analyze main treatment effects
glo panelflag = 1			 // Transaction analysis with panel
glo riflag = 1				 // Randomization inference
glo heteffectsflag = 1       // Analyze heterogenous treatment effects

glo USDconvertflag = 1 		 // Runs analysis in USD-PPP
glo ppprate = (1/38.84) 	 // PPP exchange rate from KSH (2009-2013)

glo laglength = 7			 // Lag length for panel analysis
glo iterations = 10000 		 // Number of iterations for calculating FWER adjusted p-values
glo riterations = 10000		 // Number of iterations for permutation test

/* Regressands by category */

glo ymobile "mobile_totdeposits mobile_savedays mobile_totdepositamt mobile_totwithdrawalamt"
glo yearly "mobile_earlytotdeposits mobile_earlysavedays mobile_earlyavgdeposits mobile_earlytotdepositamt"
glo ylate "mobile_latetotdeposits mobile_latesavedays mobile_lateavgdeposits mobile_latetotdepositamt"
glo ypanel "mobile_deposits mobile_saved mobile_depositamount mobile_withdrawalamount"
glo ysave "save_monthlysave_1 save_mpesa_1 save_monthlyrosca_1 save_dorosca_1"
glo ygamble "gam_moregamble_1 gam_lessgamble_1 gam_moretempted_1 gam_lesstempted_1"
glo yakiba "akiba_trust_z_1 akiba_confidence_z_1 akiba_family_1 akiba_continue_1"
glo ycons "akiba_spentfood_1 akiba_spentschool_1 akiba_spentbus_1 akiba_spentdura_1 akiba_spentdebt_1 akiba_spentsave_1"
glo yselect "akiba_controlselect_1 akiba_lotteryselect_1 akiba_regretselect_1 akiba_lotteryeffect_1 akiba_regreteffect_1"
glo ylottery "akiba_lotteryfair_z_1 akiba_prizegood_z_1 akiba_prizebad_z_1"
glo yself "self_saver_z_1 self_lucky_z_1 self_savingsfeel_z_1 self_nosavefeel_z_1"
glo ynull "$ymobile $ysave gam_moregamble_1"

/* Baseline summary outcomes */

glo controlvars "demo_female_0 demo_young_0 demo_stdschool_0 demo_haschild_0 demo_married_0 save_dosave_0 gam_mediancpgi_z_0"
glo ysum1 "demo_female_0 demo_age_0 demo_stdschool_0 demo_married_0 demo_children_0 pref_crra_0 pref_locscore_0"
glo ysum2 "labor_monthlyinc_0 labor_regularinc_0 labor_employed_0 labor_selfemployed_0 labor_dependants_0 labor_isdependant_0"
glo ysum3 "save_dosave_0 save_monthlysave_0 save_dorosca_0 save_monthlyrosca_0 save_mpesa_0"
glo ysum4 "gam_index_0 gam_cpgi_0 gam_cpgi_z_0 gam_wtp_0"
glo ysum5 "pref_avgindiff_0 pref_avggeometric_0 pref_avgexponential_0 pref_avghyperbolic_0 pref_decrimp_0 pref_station_0"

/* Endline summary outcomes */

glo ysum6 "mobile_totdeposits mobile_totdepositamt mobile_avgdepositamt mobile_totwithdrawalamt"
glo ysum7 "akiba_trust_1 akiba_confidence_1 akiba_lotteryfair_1 akiba_family_1 akiba_prizegood_1 akiba_prizebad_1 akiba_continue_1 akiba_rules_1"
glo ysum8 "akiba_controlselect_1 akiba_lotteryselect_1 akiba_regretselect_1 akiba_controlsave_1 akiba_lotterysave_1 akiba_regretsave_1"
glo ysum9 "gam_moretempted_1 gam_lesstempted_1 gam_moregamble_1 gam_lessgamble_1 self_saver_1 self_lucky_1 self_savingsfeel_1 self_nosavefeel_1"

/* Regressors */

glo xhet "demo_female_0 demo_young_0 demo_stdschool_0 demo_formschool_0 demo_married_0 demo_haschild_0 save_dosave_0 labor_medianinc_0 labor_employed_0 labor_selfemployed_0 labor_hasdependant_0 labor_isdependant_0 pref_riskaverse_0 pref_medianloc_0 pref_medianindiff_0 gam_mediancpgi_z_0"
glo xcor "pref_avgindiff_0 pref_avggeometric_0 pref_avgexponential_0 pref_avghyperbolic_0 pref_station_0 pref_decrimp_0 pref_crra_0 pref_locscore_z_0"

*************
** Program **
*************

/* Stop! Can't touch this */

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

shell find "$project_dir/code" -name "sublime2stata.do" -delete

timer off 1
qui timer list 1
di "Finished in `r(t1)' seconds."

/**********
** Notes **
***********

do winnings affect endline savings/gambling? disentangle regret aversion (+) and experience of winning (-), unable to because in the subject-level, savings and prizes are co-determined, must use panel. regress outcomes on matches. regress outcomes on size of match.
	For lottery and regret, does winning/losing affect future savings? A test of gambling/hot hand fallacy. Only able to test in panel data.
	For regret, does experiencing winning without claiming prize affect future savings? A test of regret aversion. Only able to test in panel data.
	To test fallacy, check lit
	two sources of variation: seeing potential winnings and experience of winning: reg savings regretXwinning with lags
	will probably have to account for serial correlation if estimating a time series model

is there adaptation over time? test for description experience gap, if so then is it experience or repetition or regret? might it shrink within the first few days? there is a slowdown in the cdf. find a statistical test for this
project timeline
can investigate more thoroughly how people saved during project period (time of day, week fixed effects, distance from reminder, etc.) bunching after/before lottery/reminder/endofday by group
what the hell is 11111 2222 winning ticket?
discrepancy in prizes and savings in a day?
