** Title: akiba_mobile.do
** Author: Justin Abraham, Arun Varghese
** Desc: Combines ledger and lottery ticket data
** Input: ledger_report_083014.csv, ticket_report_091014.csv
** Output: akiba_mobile.dta

*****************
** Ledger data **
*****************

import delim "$data_dir/ledger/ledger_report_083014_anon.csv", clear

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

******************
** Lottery data **
******************

import delim "$data_dir/lottery/ticket_report_091014_anon.csv", clear

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

drop if account == 22514262 & participantticket == 740 & period == 2
drop if account == 22514262 & participantticket == 2740 & period == 3
drop if account == 22514262 & participantticket == 6770 & period == 5

tempfile tickets
save `tickets', replace

**********
** Save **
**********

use `tickets', clear
merge 1:m account period using `ledger', keep(1 3) nogen

label data "Produced by akiba_mobile.do on `c(current_time)' `c(current_date)' by user `c(username)' on Stata `c(version)'"
save "$data_dir/clean/akiba_mobile.dta", replace
