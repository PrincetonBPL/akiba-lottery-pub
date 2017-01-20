<?php
// TODO when numbers are linked to an existing account (i.e., on any insert to the pls_subject table) make sure to assign a treatment_type
/**
 * This is the webhook url for the Kenyan PLS
 * Need to process messages like this: "You have received 5.00 KSH from 17045600558.  Your account balance is 12.10 KSH, expiry date is 06-11-2013"
 */
date_default_timezone_set("Africa/Nairobi");

require_once("config_pls.php");

// print_r($balance_message);

/*** treatment parameters ***/
// indicator for treatment type of this user
// $treatment_type = "interest"; // or "lottery" or "regret"

// TODO remove + from all phone numbers

function over_limit($account_number) {
    // get access to global variables
    global $mysqli, $period_limit;

    $period_result = $mysqli->query("SELECT * FROM `pls_ledger` WHERE `account` LIKE '$account_number' AND `prize` = 0 AND `time` > (SELECT max(`time_sent`) FROM `pls_drawing`) ORDER BY `id`");

    $period_balance = 0;
    if ($period_result->num_rows > 0) {
        $first_item = true;
        while($period_row = $period_result->fetch_assoc()) {
            if ($period_row['refund'] == 1 & $first_item) {
                $first_item = false;
            } else {
                $period_balance = round($period_balance + $period_row['amount'], 2);
                $first_item = false;
            }
        }
    }

    return $period_balance > $period_limit;
}

function get_info($account_number, $treatment_type) {
    //echo "Account Number: $account_number <br />Treatment Type: $treatment_type<br />";
    // get access to global variables
    global $threshold, $mysqli, $draw_min, $draw_max, $draw_daily;
    // message variables
    global $balance_message, $unknown_message, $refund_message, $error_message, $draw_message, $insufficient_message, $ticket_limit;

    //echo "query 1:<br />";
    //echo "SELECT sum(`amount`) AS 'balance' FROM `pls_ledger` WHERE `account` LIKE '$account_number' <br />";
    // grab total balance
    $result = $mysqli->query("SELECT sum(`amount`) AS 'balance' FROM `pls_ledger` WHERE `account` LIKE '$account_number'");
    $total_balance = 0.00;
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $total_balance = round($row['balance'],2);
    }

    //echo "query 2: <br />";
    //echo "SELECT sum(`amount`) AS 'balance' FROM `pls_ledger` WHERE `account` LIKE '$account_number' AND `time` > (SELECT max(`time_sent`) FROM `pls_drawing`) <br />";
    // total the amounts since last draw
    $period_result = $mysqli->query("SELECT * FROM `pls_ledger` WHERE `account` LIKE '$account_number' AND `prize` = 0 AND `time` > (SELECT max(`time_sent`) FROM `pls_drawing`) ORDER BY `id`");

    $period_balance = 0.00;
    $tickets_earned = 0;
    $current_tickets = 0;
    $ticket_string = "";
    $till_threshold = round($threshold,2);
    // if user has met the threshold: update the pls_nums 
    // if ($daily_amount >= $daily_threshold)
    if ($period_result->num_rows > 0) {
        $first_item = true;
        while($period_row = $period_result->fetch_assoc()) {
            if ($period_row['refund'] == 1 & $first_item) {
                $first_item = false;
            } else {
                $period_balance = round($period_balance + $period_row['amount'], 2);
                $first_item = false;
            }
        }

        // check number of tickets this person should have
        if ($ticket_limit) {
            if ($period_balance >= $threshold) {
                $tickets_earned = 1;
            } else {
                $tickets_earned = 0;
            }
        } else {
            $tickets_earned = floor($period_balance / $threshold);
        }
        $till_threshold = round(($threshold * ($tickets_earned + 1)) - $period_balance,2);

        //echo "query 3:<br />";
        //echo "SELECT * FROM `pls_ticket` WHERE `account` LIKE '$account_number' AND `time` > (SELECT max(`time_sent`) FROM `pls_drawing`);<br />";
        // check how many valid tickets this person already has
        $ticket_result = $mysqli->query("SELECT * FROM `pls_ticket` WHERE `account` LIKE '$account_number' AND `time` > (SELECT max(`time_sent`) FROM `pls_drawing`);"); 

        // create array of tickets
        $all_tickets = $ticket_result->num_rows;
        $awarded_tickets = array();
        $unawarded_tickets = array();
        if ($all_tickets > 0) {
            while ($ticket_row = $ticket_result->fetch_assoc()) {
                if ($ticket_row[`awarded`] == 1) {
                    $current_tickets++;
                    $awarded_tickets[] = $ticket_row;
                    // add to ticket string
                    $ticket_string .= $ticket_row['num1'] . $ticket_row['num2'] .
                        "-" . $ticket_row['num3'] . $ticket_row['num4'] . ", ";
                } else {
                    $unawarded_tickets[] = $ticket_row;
                    // add to ticket string
                    $ticket_string .= $ticket_row['num1'] . $ticket_row['num2'] .
                        "-" . $ticket_row['num3'] . $ticket_row['num4'] . ", ";
                }
            }
        }

        // add any new tickets
        if ($tickets_earned - $all_tickets === 1 || (!$ticket_limit && $tickets_earned > $all_tickets)) {
            for ($i = 0; $i < $tickets_earned - $current_tickets; $i++) {
                $num1 = rand($draw_min, $draw_max);
                $num2 = rand($draw_min, $draw_max);
                $num3 = rand($draw_min, $draw_max);
                $num4 = rand($draw_min, $draw_max);
                $ticket_string .= $num1 . $num2 . "-" . $num3 . $num4 . ", ";
                //echo "query 4:<br />";
                //echo "INSERT INTO `pls_ticket` (`account`, `num1`, `num2`, `num3`, `num4`, `awarded`, `time`) VALUES ('$account_number', $num1, $num2, $num3, $num4, 1 ,'" . date("Y-m-d\Th:i:s") . "')<br/>";
                $mysqli->query("INSERT INTO `pls_ticket` (`account`, `num1`, `num2`, `num3`, `num4`, `awarded`, `time`) VALUES ('$account_number', $num1, $num2, $num3, $num4, 1 ,'" . date("Y-m-d\TH:i:s") . "')");
            }
        }

        if (strlen($ticket_string) > 4) {
            if ($ticket_limit) {
                $ticket_string = substr($ticket_string, 0, -2);
            } else {
                $ticket_string = substr($ticket_string, 0, -2);
            }
        }
            
        // update the awards if necessary
        if ($tickets_earned > count($awarded_tickets) && count($unawarded_tickets) > 0) {
            $still_unawarded = max(count($unawarded_tickets) - ($tickets_earned - count($awarded_tickets)), 0);
            while (count($unawarded_tickets) > $still_unawarded) {
                $update = array_pop($unawarded_tickets);
                //echo "query 5:<br />";
                //echo "UPDATE `pls_ticket` SET `awarded` = 1 WHERE `id` = " . $update['id'] . ";<br/>";
                $mysqli->query("UPDATE `pls_ticket` SET `awarded` = 1 WHERE `id` = " . $update['id'] . ";");
            }
        }


        // make sure regret type has a ticket
        if (strlen($ticket_string) === 0) {
            $num1 = rand($draw_min, $draw_max);
            $num2 = rand($draw_min, $draw_max);
            $num3 = rand($draw_min, $draw_max);
            $num4 = rand($draw_min, $draw_max);
            $ticket_string .= $num1 . $num2 . "-" . $num3 . $num4 . ", ";
            $mysqli->query("INSERT INTO `pls_ticket` (`account`, `num1`, `num2`, `num3`, `num4`, `awarded`, `time`) VALUES ('$account_number', $num1, $num2, $num3, $num4, 1 ,'" . date("Y-m-d\TH:i:s") . "')");
        }
    }
    // send info
    if ($draw_daily) {
        $period_name = "Daily";
    } else {
        $period_name = "Weekly";
    }
    

    // default message
    $message = "$period_name balance: $period_balance KSH, Total balance: $total_balance KSH, $till_threshold KSH till next ticket$ticket_string";

    // test sprintf messages
    //echo "balance_message: <br/>";
    //echo " $api_key<br/>";
    //print_r($balance_message);
    //echo sprintf($balance_message["interest"], $period_name, $period_balance, $total_balance);
    // construct info message based on treatment type
    //echo "query 6:<br />";
    //echo "SELECT * FROM `pls_subject` WHERE `account` LIKE '$account_number';<br />";
    $type_result = $mysqli->query("SELECT * FROM `pls_subject` WHERE `account` LIKE '$account_number';"); 
    if ($type_result->num_rows > 0) {
        $type_array = $type_result->fetch_assoc();
        if (strlen($type_array['name']) > 0) {
            $account_name = $type_array['name'] . ", ";
        } else {
            $account_name = "";
        }

        if ($type_array['treat_type'] == "interest") {
            // control (or interest) treatment type
            $message = sprintf($balance_message["interest"], $account_name, $period_balance, $total_balance);
        } elseif ($type_array['treat_type'] == "lottery") {
            // lottery treatment type
            // clear ticket string if there are no tickets
            if ($tickets_earned >= 1) {
                $message = sprintf($balance_message["lottery"]["earned"], $account_name, $period_balance, $ticket_string, $total_balance);
            } else {
                $message = sprintf($balance_message["lottery"]["not_earned"], $account_name, $period_balance, $total_balance);
            }
        } else {
            // regret treatment type
            if ($tickets_earned >= 1) {
                $message = sprintf($balance_message["regret"]["earned"], $account_name, $period_balance, $ticket_string, $total_balance);
            } else {
                $message = sprintf($balance_message["regret"]["not_earned"], $account_name, $period_balance, $ticket_string, $total_balance);
            }
        }
    }

    return $message;
}

// telerivet secret
$secret = "MFADTXHQ29K7TECAZ2X4GGENCTLH7GXU";
// safaricom # for SMS notifications
$safaricom = "safaricom";
// $safaricom = "+17045600558"; // testing
// $draw_day = "Monday";
$account_number = 0;
$new_account = false;

// for testing
if ($dev_env) {
    $_POST['secret'] = $secret;
    $_POST['event'] = 'incoming_message';
    // add airtime
    $_POST['from_number'] = "safaricom";
    $_POST['content'] = "You have received 10.00 KSH from 17045600558.  Your account balance is 12.10 KSH, expiry date is 06-11-2013";
    // $_POST['content'] = "You have received 100.00 KSH from 718928874.  Your account balance is 12.10 KSH, expiry date is 06-11-2013";
    // check balance
    // $_POST['from_number'] = "+254718928874";
    // $_POST['content'] = "balance";
    // $_POST['content'] = "718928874";

}

if ($_POST['secret'] !== $secret){
    header('HTTP/1.1 403 Forbidden');
    echo "Invalid webhook secret";
} else {
    if ($_POST['event'] == 'incoming_message'){

        if ($dev_env) {
            $from_number = preg_replace("[\+]", "", $_POST['from_number']);
        }
        $from_number = $_POST['from_number'];
        $content = $_POST['content'];

        // this array will store the outgoing SMS
        $messages = array();

        // see if this is a notification SMS
        $pattern = "/You.have.received.[0-9]*\.[0-9]*.KSH.from.[0-9]*\./";
        $notification = preg_match($pattern,$content);
        // print_r($notification);
        // This regex should never match and should be removed
        $phonenumber = preg_match("/^\s*\+?[0-9\s]*$/",$content);

        // connect to the database
        $mysqli = new mysqli($host,$dbuser,$pw,$db);
        if (mysqli_connect_errno($link)){
            echo "Failed to connect to MySQL: " . mysqli_connect_error();
        }

        // Notification from Safaricom
        if ($notification === 1 && (strtolower($from_number) == $safaricom || $from_number == $authed_user)) {
        // if (1==1) {
            // 6/2/2014: Added last matching option to deal with Safaricom advertisements
            $array =  preg_split("/(You.have.received.|.KSH.from.|\...?Your|\.Balance)/", $content, 3, PREG_SPLIT_NO_EMPTY);
            // print_r($array);
            $amount = $array[0];
            //$subject_number = $array[1];
            $subject_number = "+254" . $array[1];

            // create entry in db
            // see if user has an account
            $result = $mysqli->query("SELECT * FROM `pls_subject` WHERE `number` LIKE '$subject_number'");
            if($result->num_rows>0){ // user already has an account
                $row = $result->fetch_assoc();
                $account_number = $row['account'];
                $treatment_type = $row['treat_type'];

                // add amount to ledger
                $mysqli->query("INSERT INTO `pls_ledger` (`account`,`amount`,`time`) VALUES ('$account_number', $amount, '" . date("Y-m-d\TH:i:s") . "')");

                // check if auth'd
                $result = $mysqli->query("SELECT `auth` FROM `pls_subject` WHERE `number` LIKE '$account_number';");
                if ($result->num_rows > 0) {
                    $row = $result->fetch_assoc();
                    if($row['auth'] == 1) { // this is an auth'd user
                        if (over_limit($account_number)) {
                            // refund and send refund message
                            $cleaned_account_number = preg_replace("/^\+254/", "0", $account_number);
                            // // refund
                            // $messages[] = array(
                            //     "to_number" => "*140*" . round($amount) . "*" . $cleaned_account_number . "#",
                            //     "message_type" => "ussd"
                            // ); // production
                                // "to_number" => "+17045600558");// testing
                            // add entry to account for refund
                            $msg = "INSERT INTO `pls_ledger` (`account`, `amount`, `time`, `refund`) VALUES ('" . $account_number . "', " . (0-$amount) . ", '" . date("Y-m-d\TH:i:s") . "', 1)";
                            $mysqli->query($msg);
                            // send email
                            mail("chaningjang@gmail.com, jonpage.econ@gmail.com, arun@busaracenter.org",
                                "SMS_PLS - Over Limit Alert",
                                "Subject Number: $subject_number\r\nAmount to refund: $amount",
                                "From: admin@economistry.com\n");
                            // refund message
                            $messages[] = array("content" => sprintf($over_limit_message, $amount),
                                "to_number" => $subject_number,
                                "status_url" => "http://www.economistry.com/sms/status_sms.php");

                        } else {
                            $messages[] = array("content" => get_info($account_number, $treatment_type),
                                "to_number" => $subject_number,
                                "status_url" => "http://www.economistry.com/sms/status_sms.php");
                        }
                    } else { // this is not an auth'd user
                        // prompt new user to connect account to an authorized one
                        $messages[] = array("content" => $unknown_message,
                            "to_number" => $subject_number,
                            "status_url" => "http://www.economistry.com/sms/status_sms.php");
                    }
                }
            } else { // user does not have an entry in pls_subject
                $mysqli->query("INSERT INTO `pls_subject` (`number`, `account`) VALUES ('$subject_number', '$subject_number')");

                // add amount to ledger
                $mysqli->query("INSERT INTO `pls_ledger` (`account`,`amount`,`time`) VALUES ('$subject_number', $amount, '" . date("Y-m-d\TH:i:s") . "')");
                // prompt new user to connect account to an authorized one
                $messages[] = array("content" => $unknown_message,
                    "to_number" => $subject_number,
                    "status_url" => "http://www.economistry.com/sms/status_sms.php");
            }

            // example message:
            // Daily balance: 100.00 KSH, Total balance: 10000.00 KSH, 10.00 KSH till next ticket, Ticket numbers: (12,34)

        } else if ($notification === 0 && strtolower($from_number) !== $safaricom) {
            // this is not a notification SMS
            // see if this is an existing user
            $result = $mysqli->query("SELECT `auth`, `treat_type` FROM `pls_subject` WHERE `number` LIKE '$from_number';");
            if ($result->num_rows > 0) {
                $row = $result->fetch_assoc();
                if ($row['auth'] == 1) {
                    // user is authorized => send info
                    // send info
                    $messages[] = array("content" => get_info($from_number, $row['treat_type']),
                        "to_number" => $from_number,
                        "status_url" => "http://www.economistry.com/sms/status_sms.php");
                } else { 
                    // user is not authorized => see if number given is authorized
                    if ($phonenumber === 1) {
                        $link_number = str_replace("/^0/", "+254", $content);
                        $result = $mysqli->query("SELECT `account` FROM `pls_subject` WHERE `number` LIKE '$link_number' AND `auth` = 1;");
                        $row = $result->fetch_assoc();
                        if ($result->num_rows > 0) {
                            // user can be linked
                            $link_number = $row['account']; // set to the master account associated with the proposed linking number
                            // 1) update entry in subject so that account points to the account for the found number
                            $mysqli->query("UPDATE `pls_subject` SET `account` = '$link_number' WHERE `number` LIKE '$from_number';");
                            // 2) update the ledger entries for this user
                            $mysqli->query("UPDATE `pls_ledger` SET `account` = '$link_number' WHERE `account` LIKE '$from_number';");
                            // 3) chack the balance and award any tickets this subject is eligible for
                            // 4) send info to user
                            $messages[] = array("content" => get_info($link_number, $row['treat_type']),
                                "to_number" => $from_number,
                                "status_url" => "http://www.economistry.com/sms/status_sms.php");
                        } else {
                            // user could not be linked
                            // see if user has a positive balance in the ledger
                            $result = $mysqli->query("SELECT sum(`amount`) AS 'balance' FROM `pls_ledger` WHERE `account` LIKE '" . $from_number . "';");
                            if ($result->num_rows > 0) {
                                $row = $result->fetch_assoc();
                                if ($row['balance'] > 0) {
                                    // here we should refund the user
                                    //$cleaned_from_number = preg_replace("[\+ ]", "", $from_number);
                                    $cleaned_from_number = preg_replace("/^\+254/", "0", $from_number);
                                    // $messages[] = array(
                                    //     "to_number" => "*140*" . round($row['balance']) . "*" . $cleaned_from_number . "#",
                                    //     "message_type" => "ussd"
                                    // ); // production
                                        // "to_number" => "+17045600558");// testing
                                    // add entry to account for refund
                                    $mysqli->query("INSERT INTO `pls_ledger` (`account`, `amount`, `time`, `refund`) VALUES ('" . $from_number . "', " . (0-$row['balance']) . ", '" . date("Y-m-d\TH:i:s") . "', 1)");
                                }
                            }

                            // not sending this now, to see if the problem has been sending multiple messages here.
                            $messages[] = array("content" => $refund_message,
                                "status_url" => "http://www.economistry.com/sms/status_sms.php");
                        }
                    } else {
                        // a phone number was not sent for this unauthorized user.
                        $messages[] = array("content" => $unknown_message,
                            "status_url" => "http://www.economistry.com/sms/status_sms.php");
                    }
                }
            } else {
                // there is an error
                $messages[0] = array("content" => $error_message,
                    "status_url" => "http://www.economistry.com/sms/status_sms.php");
            }


        }    
        // send out the messages
        header("Content-Type: application/json");
        echo json_encode(array(
            'messages' => $messages
        ));
        // print_r($messages);
    }
}
