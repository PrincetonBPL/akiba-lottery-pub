<?php
// trigger for development environment
// $dev_env = TRUE;
$dev_env = FALSE;

if ($dev_env) {
    // database stuff for localhost
    $host = 'localhost';
    $dbuser = 'root';
    $pw = 'root';
    $db = 'sms_pls';
} else {
    // production db stuff
    // $host = '50.63.227.201';

    // production PLS
    $host = '68.178.142.154';
    $dbuser = 'sms4pls';
    $pw = 'fr1#ndL!st';
    $db = 'sms4pls';
}


// telerivet stuff
$api_key = 'WCAA32X3G3LWZR6TGHUCGGUD2NCFK7TG';
$project_id = 'PJ51ff192761e10eb8';

// $phone_id = 'PN692e478e88edcb66'; // this is the simulated one
// $phone_id = 'PN993d6b9bc992fb90';    // this is the real one
$phone_id = 'PN4b1c16843fb5f2b3';
// project phone number
$project_phone = '0726 085 246';

// $authed_user = '17045600558'; // Jon
$authed_user = '13107803560'; // Chaning

/*** treatment parameters ***/
$draw_daily = true; // test
$match_total_savings = false; // test
$threshold = 5.00;
$draw_min = 0;
$draw_max = 9;
$ticket_limit = true; // test: set this to true if only one ticket is awarded per draw period

// interests segmented by treatment type
if ($match_total_savings) { // total balance
    $base_interest = array(
        "interest" => 0.005,
        "lottery" => 0.0,
        "regret" => 0.0);
    $match1_interest = array(
        "interest" => 0.0,
        "lottery" => 0.01,
        "regret" => 0.01);
    $match2_interest = array(
        "interest" => 0.0,
        "lottery" => 0.1,
        "regret" => 0.1);
    $match4_interest = array(
        "interest" => 0.0,
        "lottery" => 20,
        "regret" => 20);
} else { // period balance
    $base_interest = array(
        "interest" => 0.05,
        "lottery" => 0.0,
        "regret" => 0.0);
    $match1_interest = array(
        "interest" => 0.0,
        "lottery" => 0.1,
        "regret" => 0.1);
    $match2_interest = array(
        "interest" => 0.0,
        "lottery" => 1,
        "regret" => 1);
    $match4_interest = array(
        "interest" => 0.0,
        "lottery" => 200,
        "regret" => 200);
}

/* Communication messages */
// e.g., $balance_message['interest'] is a template that would produce:
// Daily balance: 20.00 KSH, Total balance: 30.30 KSH, your lucky numbers are 12-34. Save more, Sambaza *140*XX*8085551234.
//echo "%s balance: %01.2f KSH, Total balance: %01.2f KSH. Save more, Sambaza *140*XX*$project_phone.";
// updated 1/27/2014
$balance_message = array(
    "interest" => "%syour daily balance is: %01.2f KSH. Your total balance is: %01.2f KSH. Sambaza *140*XX*$project_phone# to earn more extra!",
    "lottery" => array(
        "earned" => "%syour daily balance is: %01.2f KSH. Your lucky numbers are %s. Your total balance is: %01.2f KSH. Sambaza *140*XX*$project_phone# to win more!",
        "not_earned" => "%syour daily balance is: %01.2f KSH. Your total balance is: %01.2f KSH. Sambaza *140*XX*$project_phone# to earn your ticket!"
    ),
    "regret" => array(
        "earned" => "%syour daily balance is: %01.2f KSH. Your lucky numbers are %s. Your total balance is: %01.2f KSH. Sambaza *140*XX*$project_phone# to win more!",
        "not_earned" => "%syour daily balance is: %01.2f KSH. Your lucky numbers are %s. Your total balance is: %01.2f KSH. Sambaza *140*XX*$project_phone# to earn your ticket!"
    )
);

$unknown_message = "This number is not known in the system. What is your standard phone number (10-digits)?";

$refund_message = "This is not a valid response. We are returning your airtime. Please save using your phone only. Call $project_phone for help"; 

// this is sent if an unknown phone sends an SMS directly to the project number
$error_message = "There was an error. Call $project_phone for help.";

// updated 1/27/2014
$draw_message = array(
    "interest" => "You saved %01.2f KSH today. You earned %01.1f%% extra! %01.2f KSH has been deposited into your account. Your new balance: %01.2f KSH",
    "lottery" => array(
        "win" => "You saved %01.2f KSH today. Congratulations! You won a prize of %01.2f KSH!!! The winning numbers: %s. Your lucky numbers: %s. Your new balance: %01.2f KSH",
        "lose" => "You saved %01.2f KSH today. Sorry, you did not win any prize. The winning numbers: %s. Your lucky numbers: %s. Your total balance: %01.2f KSH"
    ),
    "regret" => array(
        "win" => "You saved %01.2f KSH today. Congratulations! You won a prize of %01.2f KSH!!! The winning numbers: %s. Your lucky numbers: %s. Your new balance: %01.2f KSH",
        "lose" => "You saved %01.2f KSH today. Sorry, you did not win any prize. The winning numbers: %s. Your lucky numbers: %s. Your total balance: %01.2f KSH"
    )
);

// updated 1/27/2014
$insufficient_message = array(
    "interest" => "You saved %01.2f KSH today. You did not earn any extra. Your total balance: %01.2f KSH",
    "regret_match" => "Congratulations! You won a prize!!! The winning numbers: %s. Your lucky numbers: %s. Since you did not save today, you gave up your prize. Your total balance: %01.2f KSH",
    "regret" => "You saved %01.2f KSH today. Sorry, you did not win any prize. The winning numbers: %s. Your lucky numbers: %s. Your total balance: %01.2f KSH",
    "lottery" => "You saved %01.2f KSH today. Sorry, you did not win any prize. The winning numbers: %s. You did not earn lucky numbers. Your total balance: %01.2f KSH"
);

// updated 1/27/2014
$encourage_regret = "%sremember to save today. Your ticket can give you up to 200 times your savings! Your lucky numbers: %s. Sambaza *140*XX*$project_phone# to save.";
$encourage_lottery = "%sremember to save today. Get a lottery ticket by saving. You could win up to 200 times your savings! Sambaza *140*XX*$project_phone# to save.";
$encourage_interest = "%sremember to save today. Earn 5%% extra! Sambaza *140*XX*$project_phone# to save.";

// added 4/6/2014
$over_limit_message = "The daily savings limit is 1000000 KSH. We will return your airtime in the next 24 hours.";
//$over_limit_message = "The daily savings limit is 150 KSH. We will return your airtime in the next 24 hours. Please save 150KSH when you receive the refund.";
$period_limit = 1000000;
$treatment_length = 30; // number of periods per treatment phase, after one phase the alternate encouragement is sent.
$encourage_regret_phase2 = "%sremember to save today. Your ticket can give you up to 200 times your savings! Your lucky numbers: %s. Sambaza *140*XX*$project_phone# to save. Day %d of $treatment_length.";
$encourage_lottery_phase2 = "%sremember to save today. Get a lottery ticket by saving. You could win up to 200 times your savings! Sambaza *140*XX*$project_phone# to save. Day %d of $treatment_length.";
$encourage_interest_phase2 = "%sremember to save today. Earn 5%% extra! Sambaza *140*XX*$project_phone# to save. Day %d of $treatment_length.";

