<?php
/**
 * This is the cron job to create the daily/weekly tickets for the regret treatment group
 * The correct interval can be set in the server
 * TODO Fix so tickets are added to the db only for people that do not have them already today.
 */
$_POST['confirm'] = "regret";

if (isset($_POST['confirm'])) {
    if ($_POST['confirm'] == "regret") {
        // this is an authorized request
        date_default_timezone_set("Africa/Nairobi");
        require_once('config_pls.php');

        # connect to the database
        $mysqli = new mysqli($host,$dbuser,$pw,$db);
        if (mysqli_connect_errno($link)){
            echo "Failed to connect to MySQL: " . mysqli_connect_error();
die;
        }

        if ($draw_daily) {
            $period_name = "Daily";
        } else {
            $period_name = "Weekly";
        }

        // 1) grab all auth'd accounts
        $result = $mysqli->query("SELECT * FROM `pls_subject` WHERE `auth` = 1;");
        if ($result->num_rows > 0) {
            // setup the cURL requests
            $ch = array();
            $messages = array();

            $i = 1;
            while ($row = $result->fetch_assoc()) {
                if (strlen($row['name']) > 0) {
                    $account_name = $row['name'] . ", ";
                } else {
                    $account_name = "";
                } 

                // set current period for this user
                $first_period = $row['first_drawing_id'];
                $user_period = 1;
                $period_result = $mysqli->query("SELECT max(`id`) AS 'max' FROM `pls_drawing`");
                if($period_result->num_rows > 0) {
                    $period_row = $period_result->fetch_assoc();
                    $user_period = ($period_row['max'] + 2) - $first_period;
                } else {
                    $user_period = 1;
                }

                if ($row['treat_type'] == "regret") {
                    // build REST requests for TeleRivet
                    // ADDED 5/23/2014 - START
                    // check to see if this user has a ticket
                    $ticket_result = $mysqli->query("SELECT * FROM `pls_ticket` WHERE `account` LIKE '" . $row['account'] . "' AND `time` > (SELECT max(`time_sent`) FROM `pls_drawing`);"); 
                    $num_tickets = $ticket_result->num_rows;
                    print_r("num_tickets: $num_tickets");
                    if ($num_tickets > 0) {
                        while ($ticket_row = $ticket_result->fetch_assoc()) {
                            $num1 = $ticket_row['num1'];
                            $num2 = $ticket_row['num2'];
                            $num3 = $ticket_row['num3'];
                            $num4 = $ticket_row['num4'];
                        }
                    } else {
                    // ADDED - END
                        // draw numbers
                        $num1 = rand($draw_min, $draw_max);
                        $num2 = rand($draw_min, $draw_max);
                        $num3 = rand($draw_min, $draw_max);
                        $num4 = rand($draw_min, $draw_max);

                        // add numbers for this user
                        $mysqli->query("INSERT INTO `pls_ticket` (`account`, `num1`, `num2`, `num3`, `num4`, `time`) VALUES ('" . $row['account'] . "', $num1, $num2, $num3, $num4, '" . date("Y-m-d\Th:i:s") . "');");
                    } // ALSO ADDED
                    // encourage them to save
                    if ($user_period <= $treatment_length) {
                        $message = sprintf($encourage_regret, $account_name, $num1 . $num2 . "-" . $num3 . $num4);
                    } else {
                        $message = sprintf($encourage_regret_phase2, $account_name, $num1 . $num2 . "-" . $num3 . $num4, $user_period - $treatment_length);
                    }
                    $messages[] = array(
                        'content' => $message,
                        'phone_id' => $phone_id,
                        'to_number' => $row['account'],
                    );

                    // add to the curl queue
                    $ch[$i] = curl_init();
                    curl_setopt($ch[$i], CURLOPT_URL, 
                        "https://api.telerivet.com/v1/projects/$project_id/messages/outgoing");
                    curl_setopt($ch[$i], CURLOPT_USERPWD, "{$api_key}:");  
                    curl_setopt($ch[$i], CURLOPT_RETURNTRANSFER, 1);
                    curl_setopt($ch[$i], CURLOPT_POSTFIELDS, http_build_query(array(
                        'content' => $message,
                        'phone_id' => $phone_id,
                        'to_number' => $row['account'],
                    ), '', '&'));

                } elseif ($row['treat_type'] == "interest") {
                    if ($user_period <= $treatment_length) {
                        $message = sprintf($encourage_interest, $account_name);
                    } else {
                        $message = sprintf($encourage_interest_phase2, $account_name, $user_period - $treatment_length);
                    }
                    $messages[] = array(
                        'content' => $message,
                        'phone_id' => $phone_id,
                        'to_number' => $row['account'],
                    );

                    // add to the curl queue
                    $ch[$i] = curl_init();
                    curl_setopt($ch[$i], CURLOPT_URL, 
                        "https://api.telerivet.com/v1/projects/$project_id/messages/outgoing");
                    curl_setopt($ch[$i], CURLOPT_USERPWD, "{$api_key}:");  
                    curl_setopt($ch[$i], CURLOPT_RETURNTRANSFER, 1);
                    curl_setopt($ch[$i], CURLOPT_POSTFIELDS, http_build_query(array(
                        'content' => $message,
                        'phone_id' => $phone_id,
                        'to_number' => $row['account'],
                    ), '', '&'));

                } else {
                    if ($user_period <= $treatment_length) {
                        $message = sprintf($encourage_lottery, $account_name);
                    } else {
                        $message = sprintf($encourage_lottery_phase2, $account_name, $user_period - $treatment_length);
                    }
                    $messages[] = array(
                        'content' => $message,
                        'phone_id' => $phone_id,
                        'to_number' => $row['account'],
                    );

                    // add to the curl queue
                    $ch[$i] = curl_init();
                    curl_setopt($ch[$i], CURLOPT_URL, 
                        "https://api.telerivet.com/v1/projects/$project_id/messages/outgoing");
                    curl_setopt($ch[$i], CURLOPT_USERPWD, "{$api_key}:");  
                    curl_setopt($ch[$i], CURLOPT_RETURNTRANSFER, 1);
                    curl_setopt($ch[$i], CURLOPT_POSTFIELDS, http_build_query(array(
                        'content' => $message,
                        'phone_id' => $phone_id,
                        'to_number' => $row['account'],
                    ), '', '&'));

                }
                $i++;

            }
            print_r($messages);

            if (!$dev_env) {
                $mh = curl_multi_init();
                for ($i = 0; $i < count($ch); $i++) {
                    curl_multi_add_handle($mh, $ch[$i+1]);
                    echo "added message " . $i+1;
                }

                $active = null;
                //execute the handles
                do {
                    $mrc = curl_multi_exec($mh, $active);
                } while ($mrc == CURLM_CALL_MULTI_PERFORM);

                while ($active && $mrc == CURLM_OK) {
                    if (curl_multi_select($mh) != -1) {
                        do {
                            $mrc = curl_multi_exec($mh, $active);
                        } while ($mrc == CURLM_CALL_MULTI_PERFORM);
                    }
                }

                for ($i = 1; $i < count($ch); $i++) {
                    curl_multi_remove_handle($mh, $ch[$i]);
                }

                curl_multi_close($mh);
            }
        }
    }
}
