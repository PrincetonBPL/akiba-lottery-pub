** Title: akiba_build.do
** Author: Justin Abraham, Arun Varghese
** Desc: Combines, lab data, respondent database, ledger data, and questionnaires. Adapted from Arun's scripts.
** Input: pls_subject.csv
** Output: akiba_merged.dta

***********************
** Subjects database **
***********************

import delim "$data_dir/lab/pls_subject_anon.csv", clear

* Drop errors and test users
drop if survey_id < 5

* Updating auth to account for subjects that have withdrawn since pls_subject data pull (when was this?)
replace auth = 0 if survey_id == 240277 | survey_id == 108435 | survey_id == 105992 | survey_id == 289541

* Drop extra variables
keep account survey_id treat_type auth first_drawing_id

* Rename survey_id to personid
rename survey_id personid

* Make corrections where subject ID was recorded incorrectly
replace personid = 172401 if personid == 174401
replace personid = 138029 if personid == 138025
replace personid = 147877 if personid == 147677
replace personid = 150341 if personid == 199772
replace personid = 160639 if personid == 155694
replace personid = 162341 if personid == 147899
replace personid = 173373 if personid == 114005
replace personid = 201248 if personid == 252691
replace personid = 212400 if personid == 161643

* Standardizing account format
destring account, replace
format account %15.0g

* Some subjects who were in pilot were accidently invited to and participated in our sessions. Marking those subjects below.
gen in_pilot = 0
replace in_pilot = 1 if personid == 125932
replace in_pilot = 1 if personid == 109992
replace in_pilot = 1 if personid == 158804
replace in_pilot = 1 if personid == 125543
replace in_pilot = 1 if personid == 169770
replace in_pilot = 1 if personid == 275555

tempfile subjects
save `subjects', replace

**************
** Lab data **
**************

cd "$project_dir/data/lab"

loc files: dir . files "*.xls"
loc i = 1

foreach file in `files' {
	clear
	ztree2stata subjects using "`file'"
	gen sessionnum = `i'
	tempfile file`i'
	save `file`i'', replace
	loc ++i
}

loc i = `i'-1


use `file1', clear

if `i' >1 {
	forvalues j = 2/`i' {
		append using `file`j''
		display "appended `j'"
	}
}

egen sid = group(sessionnum Subject)

tempfile lab
save `lab', replace

/* Risk (Eckel-Grossman) */

keep if TREATMENTID == 1
drop if treatment == 3	// Risk was run twice in Session 2, drop the second instance

/*  OPTIONS
	1) 28 vs. 28
	2) 24 vs. 36
	3) 20 vs. 44
	4) 16 vs. 52
	5) 12 vs. 60
	6)  2 vs. 70

	1) r= 3.45971
	2) r= 1.16065
	3) r= 0.705582
	4) r= 0.498612
	5) r= 0

	Implied CRRA Range
	1) 3.45971<r
	2) 1.16065< r < 3.45971
	3) 0.705582< r <1.16065
	4) 0.498612< r <0.705582
	5) 0< r <0.498612
	6) r < 0

	Values used (midpoints except for extremes)
	1) 3.45971
	2) 2.31018
	3) 0.933116
	4) 0.602097
	5) 0.249306
	6) 0
*/

keep TREATMENTID MPLChoice MPLRT payamt sid MPLChoice session Subject sessionnum

tempfile risk
save `risk', replace

/* Time (multiple price list) */

use `lab', replace

keep if TREATMENTID == 2

	/*  OPTIONS
		1) 1 vs 14 days
		2) 1 vs 28 days
		3) 1 vs 84 days
		4) 14 vs 28 days

		A) 100 sooner vs
		B) 100 - 1000 later (steps of 100)

		For choices, -1 refers to selecting sooner, and 1 refers to selecting later
	*/

egen patresp1 = rowtotal(choice1-choice10)
egen patresp2 = rowtotal(choice11-choice20)
egen patresp3 = rowtotal(choice21-choice30)
egen patresp4 = rowtotal(choice31-choice40)
recode patresp* (-10=0) (-8=1) (-6=2) (-4=3) (-2=4) (0=5) (2=6) (4=7) (6=8) (8=9) (10=10)

gen indiff1 = patresp1
gen indiff2 = patresp2
gen indiff3 = patresp3
gen indiff4 = patresp4
recode indiff* (0 = 1000) (1=950) (2=850) (3=750) (4=650) (5=550) (6=450) (7=350) (8=250) (9=150) (10=100)

keep TREATMENTID patresp* indiff* paydays earnings sid

tempfile time
save `time', replace

/* WTP for lottery */

use `lab', clear
keep if TREATMENTID == 3
/*  OPTIONS
	10 questions
	1) 30; 2) 25; 3) 20; 4) 15; 5) 10; 6) 5; 7) 4; 8) 3; 9) 2; 10) 1 KSH
	-1 refers to choosing money, 1 refers to choosing ticket
*/
egen wtplottery = rowtotal(choice1-choice10), m
recode wtplottery (-10=1) (-8=1.5) (-6=2.5) (-4=3.5) (-2=4.5) (0=7.5) (2=12.5) (4=17.5) (6=22.5) (8=27.5) (10=30)

keep TREATMENTID wtplottery sid earnings

tempfile lottery
save `lottery', replace

/* Locus of control */

/*
	Happy face or sad face appears (randomly = 70% happy)
	You get 5 points for happy and 0 for sad
	20 rounds, then rate the level to which you felt you controlled the faces
	1 = no influence, 10 = total control
*/

use `lab', clear
keep if TREATMENTID == 4
rename TotalScore loc_score

* Since loc_score and influence are so strongly related, regress loc_score on influence and keep the residuals
reg influence loc_score
predict influence_res,res

keep TREATMENTID loc_score influence* sid

tempfile loc
save `loc', replace

/* Demographic and gambling questionnaire */

use `lab', clear

keep if TREATMENTID == 5
drop response28
keep TREATMENTID sid response*

rename response1 labgender
rename response2 labage
rename response3 labmarital_status
rename response4 labnum_child
rename response5 labnum_child_home
rename response6 labemployment
rename response7 labnum_dependants
rename response8 labsupported_dummy
rename response9 labinc_permonth
rename response10 labsaving_yesno
rename response11 labtot_save_MPESA
rename response12 labrosca_yesno
rename response13 labrosca_monthly
rename response14 labtot_save_pastmonth
forvalues i=15/27 {
rename response`i' gamblingfreq`=`i'-14'
}
egen cpgi = rowtotal(gamblingfreq1-gamblingfreq8)
replace cpgi = cpgi-8

//ADD VALUE LABELS
label define lb_gender 1 "male" 2 "female"
label define lb_marital 1 " married" 2 "cohabiting" 3 "divorced" 4 "widowed" 5 "single" 6 "other"
label define lb_employment 1 "regular income" 2 "irregular income" 3 "unemployed"
label define lb_yesno 1 "yes" 2 "no"
label define lb_gamble1 1 "never" 2 "sometimes" 3 "often" 4 "almost always"
label define lb_gamble2 1 "never" 2 "1-4 times" 3 "daily" 4 "multi-per-day"
label val labgender lb_gender
label val labmarital_status lb_marital
label val labemployment lb_employment
label val labsupported_dummy lb_yesno
label val labsaving_yesno lb_yesno
label val labrosca_yesno lb_yesno
label val gamblingfreq1-gamblingfreq8 lb_gamble1
label val gamblingfreq9-gamblingfreq13 lb_gamble2

//ADD VARIABLE LABELS FOR GAMBLING
* Q1-8 is the Canadian Problem Gambling Index
* 1=Never, 2=Sometimes, 3=Often, 4=Almost Always
* Score usually 0-3, total it up and 0 = non-problem gambler, 1-2= low-risk gambler, 3-7=moderate risk, 8+=problem gambler
label var gamblingfreq1 "Bet more than could really afford to lose?"
label var gamblingfreq2 "Needed to gamble with larger amounts of money to get the same feeling of excitement?"
label var gamblingfreq3 "Gone back anohter day to try and win back the money you lost?"
label var gamblingfreq4 "Borrowed money or sold anything to get money to gamble?"
label var gamblingfreq5 "Felt that you might have a problem with gambling?"
label var gamblingfreq6 "Felt that gambling has caused you health problems, including stress and anxiety?"
label var gamblingfreq7 "People critized your betting or told you that you have a gambling problem, whether or not you thought it was true?"
label var gamblingfreq8 "Felt your gambling has caused financial problems for you or your household? Felt guilty about the way you gamble or what happens when you gamble?"
label var cpgi "Canadian Problem Gambling Index, 0=non-problem 1-2=low-risk 3-7=mod-risk 8+=problem"
* 1=Never, 2=1-4times, 3=Daily, 4=Multiple times per day
label var gamblingfreq9 "Bet money at a racetrack"
label var gamblingfreq10 "Bet money on a sporting event"
label var gamblingfreq11 "Played the lottery (Charity Sweepstakes)"
label var gamblingfreq12 "Gambled at a Casino"
label var gamblingfreq13 "Played cards or another gamke for money (billards, checkers, etc.)"

tempfile ques
save `ques', replace

/* Merge lab data */

use `risk', clear

merge 1:1 sid using `time', nogen
merge 1:1 sid using `lottery', nogen
merge 1:1 sid using `loc', nogen
merge 1:1 sid using `ques', nogen

* 8-30 ADDED A LINE FOR DATA THAT WAS ORIGINALLY MISSING (for 6/11/2014 session)

gen sess_match = "052214_1" if session == "140522_1204"
replace sess_match = "060314_1" if session == "140603_1323"
replace sess_match = "060514_1" if session == "140605_0904"
replace sess_match = "060514_2" if session == "140605_1227"

replace sess_match = "060914_1" if session == "140609_1043"
replace sess_match = "060914_2" if session == "140609_1314"

replace sess_match = "061014_1" if session == "140610_0853"
replace sess_match = "061014_2" if session == "140610_1249"

replace sess_match = "061114_1" if session == "140611_1301"

replace sess_match = "061214_1" if session == "140612_0844"
replace sess_match = "061214_2" if session == "140612_1327"

replace sess_match = "061314_1" if session == "140613_0821"
replace sess_match = "061314_2" if session == "140613_1228"

replace sess_match = "061614_1" if session == "140616_1011"
replace sess_match = "061614_2" if session == "140616_1255"

replace sess_match = "061714_1" if session == "140617_0855"

replace sess_match = sess_match+"_"+string(Subject)

order sid sessionnum sess_match

save `lab', replace

**********************************
** Enrollment and questionnaire **
**********************************

use "$data_dir/questionnaires/_C02akibasmart_anon.dta", clear

* Drop pilot data
drop if identifydate == 19781

gen sess_match = "052214_1" if identifydate == 19865 & sessionnumber == 1

replace sess_match = "060314_1" if identifydate == 19877 & sessionnumber == 1
replace sess_match = "060514_1" if identifydate == 19879 & sessionnumber == 1
replace sess_match = "060514_2" if identifydate == 19879 & sessionnumber == 2

replace sess_match = "060914_1" if identifydate == 19883 & sessionnumber == 1
replace sess_match = "060914_2" if identifydate == 19883 & sessionnumber == 2

replace sess_match = "061014_1" if identifydate == 19884 & sessionnumber == 1
replace sess_match = "061014_2" if identifydate == 19884 & sessionnumber == 2

replace sess_match = "061114_1" if identifydate == 19885 & sessionnumber == 1

replace sess_match = "061214_1" if identifydate == 19886 & sessionnumber == 1
replace sess_match = "061214_2" if identifydate == 19886 & sessionnumber == 2

replace sess_match = "061314_1" if identifydate == 19887 & sessionnumber == 1
replace sess_match = "061314_2" if identifydate == 19887 & sessionnumber == 2

replace sess_match = "061614_1" if identifydate == 19890 & sessionnumber == 1
replace sess_match = "061614_2" if identifydate == 19890 & sessionnumber == 2

replace sess_match = "061714_1" if identifydate == 19891 & sessionnumber == 1

* Drop others
keep sess_match personid age education marital children cellphone1 surveyid birthyear gender occupation occupation_spec incomestream selfemployed nativelanguage nativelanguage_spec ztreeclientnumber

* Tag duplicates with dup
duplicates tag personid, gen(dup)

* Tag which duplicate to drop with 'drop'
* Duplicates seemed to be members of the same household (genders were different between duplicate copies)
* So am tagging which duplicate copy to drop based on how gender matches name we have in Akiba database
gen drop = 0
replace drop = 1 in 56
replace drop = 1 in 125
replace drop = 1 in 203
replace drop = 1 in 264

* Need to identify groups by sess_match where a duplicate occurs so that I can re-assign ztreeclientnumbers

//egen renum_group = max(dup), by(sess_match)  (used this to see which groups had a duplicate personid in them)

* Regenerate ztreeclient numbers bc original didn't account for personid duplicates
drop if drop==1
bysort sess_match (ztreeclientnumber): gen ztreeclientnum_new = _n
drop dup drop ztreeclientnumber //renum_group

* Will merge with session data on sess_match
replace sess_match = sess_match+"_"+string(ztreeclientnum_new)
drop ztreeclientnum_new

tempfile enroll
save `enroll', replace

*****************
** Ledger data **
*****************

import delim "$data_dir/ledger/ledger_report_083014.csv", clear

format account %15.0g

* Dropping >60 Day negative entries.  These were automatically generated when subjects saved after their 60th day.

drop if period > 59 & amount < 0
drop if period > 60

* If only prize == 1, this is a prize winning amount.
* If only refund == 1, this is refunded amount.  Usually due to savings >150ksh before we raised the limit.
* If prize ==1 AND refund == 1, this is a 30th day withdrawal.

gen type_deposit = (refund == 0 & prize == 0)
gen type_refund = (refund == 1 & prize == 0)
gen type_prize = (refund == 0 & prize == 1)
gen type_withdrawal = (refund == 1 & prize == 1)

drop refund prize

* Creating transaction IDs

sort account time
bysort account: gen trid = _n

tempfile ledger
save `ledger', replace

*********************
** Lottery tickets **
*********************

import delim "$data_dir/lottery/ticket_report_091014.csv", clear

format account %15.0g

* Adjusting period because Arun says so

replace period = period - 1
drop if period > 60

* AV: FOR USER 254722616846, IN PERIODS 3,4 AND 6 SHE WAS GIVEN TWO SETS OF LUCKY #S.
* AT BEG OF EXPERIMENT, WE HAD AN ISSUE WHERE PARTICIPANTS SENDING IN SAVINGS BEFORE THE
* BOD MSG WOULD RECIEVE DIFF LUCKY #S THAN IN THEIR BOD MSG.  THIS IS WHERE LILIAN'S
* EXTRA LUCKY #S COME FROM.  IN PERIODS 4 AND 6, MATCH TYPE WAS ZERO AND LILIAN SAVED,
* SO 'AWARDED' == 0 FOR BOTH LUCKY #'S.  TO CORRECT, I WILL DELETE ONE OF THE LUCKY #'S
* FROM BOTH PERIOD 4 AND 6.  THIS CAUSES NO LOSS OF GENERALITY.
* IN PERIOD 3, THE LUCKY # AFTER THE BOD MSG MATCHES ON ONE NUMBER.
* I WILL DELETE THE LUCKY # FROM BEFORE BOD MSG.  THIS WILL CAUSE A SMALL
* LOSS OF INFORMATION.

drop if account == 254722616846 & participantticket == 740 & period == 2
drop if account == 254722616846 & participantticket == 2740 & period == 3
drop if account == 254722616846 & participantticket == 6770 & period == 5

tempfile tickets
save `tickets', replace

***************************
** Endline questionnaire **
***************************

import delim "$data_dir/questionnaires/AKIBA SMART STUDY (Responses) - Form responses 1_anon.csv", clear

drop if surveyid == .
drop if surveyid == 3

* Correcting error made with Vincent Opiyo's surveyid
replace surveyid = 169770 if surveyid > 999999

* dropping extra variables
drop v35 pleaseconsiderthefollowingthreed timestamp

* renaming variables
rename nameoffieldofficer endline_FO
rename respondentsfirstname endline_firstname
rename surveyid endline_surveyid
rename telephonenumber endline_telephonenumber
rename howmuchmoneyinkshdidyouearninthe endline_pastmonth_earnings
rename howmuchmoneydoyouhaveonmpesarigh endline_mpesa
rename doyoucurrentlyparticipateinamerr endline_ROSCA
rename ifyouparticipateinamerrygoroundo endline_ROSCA_monthly
rename pleasethinkaboutallyoursavingsin endline_totalsavings_pastmonth
rename howmuchdoyoutrustakibasmartingen endline_akibatrust
rename whatisyourconfidencelevelthataki endline_akibaconfidence
rename didyoutellaboutakibasmarttoyourf endline_fam_friends
rename ifyeshowoften endline_fam_friends_howoften
rename inthepast2monthsyousavedwithakib endline_akibarules
rename nowiwillaskamoredetailedquestion endline_akiba_detailedQ
rename ifcustomanswerenterithere endline_akiba_detailedQcustom
rename inthepasttwomonthshowdidyoufeelo endline_past2mo_feel
rename doyouseeyourselfasasaveringenera endline_saver
rename ifweofferedyouthese3savingsplans endline_chooseplan
rename imaginethatweofferedyouplan1matc endline_plan1save
rename imaginethatweofferedyouplan2lott endline_plan2save
rename imaginethatweofferedyouplan3regr endline_plan3save
rename ifweofferedyoutocontinuesavingwi endline_akiba_anotheryr
rename nowthatyousavedwithakibainthelas endline_othersaving
rename nowthatyousavedmoneywithakibaint endline_savingsfeel
rename inthepasttwomonthsatwhattimesdur endline_savingstime
rename v29 endline_savingstime_custom
rename doyoutrustthatthelotterywasfair endline_lotterytrust
rename howgooddidyoufeelwhenyouwonapriz endline_prizegood
rename howbaddidyoufeelwhenyoudidntwina endline_prizebad
rename areyouingeneralaluckyperson endline_lucky
rename treatmenttype endline_treatmenttype
rename respondentslastname endline_respondentslastname
rename ifyousavedwithakibasmartwhatdidy endline_moneyspent
rename afterparticipatinginakibasmartfo endline_gambling_temptation
rename v39 endline_gambling_freq
rename doyouhaveanycomplementscomplaint endline_comments

rename endline_surveyid personid

replace personid = 261993 if personid == 261668 & endline_firstname == "lucy"

* dropping duplicates
* 2 sets of duplicatesL
* 2 identical entries for Kennedy Tanui (274505), dropping one
* 2 different entries for Dorcus Mogaka (233962), NOTE: seems like he was given endline twice and gave different answers, keeping only the first entry

duplicates drop personid, force

drop endline_firstname endline_respondentslastname

tempfile endline
save `endline', replace

************************
** Merge all datasets **
************************

use `lab', clear

merge 1:1 sess_match using `enroll', nogen
merge 1:1 personid using `subjects', nogen
merge 1:1 personid using `endline'

gen attrit = _merge == 1
drop _merge

recode auth (1 = 0) (0 = 1) (nonm = .), gen(left_akiba)
drop auth

qui compress
save "$data_dir/clean/akiba_subjects.dta", replace

use `tickets', clear

merge 1:m account period using `ledger', keep(1 3) nogen

qui compress
save "$data_dir/clean/akiba_mobile.dta", replace
