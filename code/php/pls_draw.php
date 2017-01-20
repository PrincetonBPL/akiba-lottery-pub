<?php
/**
 * This is the cron job to conduct the daily/weekly drawing
 * The correct interval can be set in the server
 * When the drawing occurs, any applicable interest will be applied
 */
$_POST['confirm'] = "draw";

if (isset($_POST['confirm'])) {
    if ($_POST['confirm'] == "draw") {
        // this is an authorized request
        // this number is used if we are crediting their account directly after a winning
        $sambaza = 140;

        # 1) add an entry to `pls_drawing`
        date_default_timezone_set("Africa/Nairobi");

        require_once('config_pls.php');

        # connect to the database
        $mysqli = new mysqli($host,$dbuser,$pw,$db);
        if (mysqli_connect_errno($link)){
            echo "Failed to connect to MySQL: " . mysqli_connect_error();
die;
        }

        // send info
        if ($draw_daily) {
            $period_name = "Daily";
        } else {
            $period_name = "Weekly";
        }

        // draw numbers
        $num1 = rand($draw_min, $draw_max);
        $num2 = rand($draw_min, $draw_max);
        $num3 = rand($draw_min, $draw_max);
        $num4 = rand($draw_min, $draw_max);
        # 1) grab all auth'd accounts
        $result = $mysqli->query("SELECT * FROM `pls_subject` WHERE `auth` = 1;");
        if ($result->num_rows > 0) {
            // echo "more than 0 subjects<br/>";
            // for testing
            $messages = array();

            # setup the cURL requests
            $ch = array();
            # $mh = curl_multi_init();
            $i = 1;
            #$win = false;
            while ($row = $result->fetch_assoc()) {
                echo "found " . $row['account'] . "<br/>";
                if (strlen($row['name']) > 0) {
                    $account_name = $row['name'] . ", ";
                } else {
                    $account_name = "";
                }
                // reset match indicators
                $match1 = false;
                $match2 = false;
                $match4 = false;
                # reset amount to add
                $to_add = 0;
                $period_balance = 0.00;
                $total_balance = 0.00;
                $account_number = $row['account'];
                $message = "";

                # build REST requests for TeleRivet
                $ch[$i] = curl_init();
                curl_setopt($ch[$i], CURLOPT_URL, 
                    "https://api.telerivet.com/v1/projects/$project_id/messages/outgoing");
                curl_setopt($ch[$i], CURLOPT_USERPWD, "{$api_key}:");  
                curl_setopt($ch[$i], CURLOPT_RETURNTRANSFER, 1);

                # get period balance
                $period_result = $mysqli->query("SELECT * FROM `pls_ledger` WHERE `account` LIKE '$account_number' AND `prize` = 0 AND `time` > (SELECT max(`time_sent`) FROM `pls_drawing`) ORDER BY `id`");
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
                    echo "period balance: " . $period_balance . "<br />";
                }

                // get total balance
               $total_result = $mysqli->query("SELECT sum(`amount`) AS 'balance' FROM `pls_ledger` WHERE `account` LIKE '$account_number'");
               if ($total_result->num_rows > 0) {
                   $total_row = $total_result->fetch_assoc();
                   $total_balance = round($total_row['balance'],2);
               }

                // find the tickets and look for a match
                $tickets_result = $mysqli->query("SELECT * FROM `pls_ticket` WHERE `account` LIKE '" . $row['account'] . "' AND `time` > (SELECT max(`time_sent`) FROM `pls_drawing`);");
                if ($tickets_result->num_rows > 0) { // You had tickets
                    echo "you had tickets<br />";

                    // see if they win
                    while($tickets_row = $tickets_result->fetch_assoc()) {
                        $ticket_string = "" . $tickets_row['num1'] . $tickets_row['num2'] . "-" . $tickets_row['num3'] . $tickets_row['num4'];
                        if ((int)$tickets_row['num1'] == (int)$num1 && (int)$tickets_row['num2'] == (int)$num2 && (int)$tickets_row['num3'] == (int)$num3 && (int)$tickets_row['num4'] == (int)$num4) {
                            $match4 = true;
                            echo "match 4<br/>";
                        } elseif ((int)$tickets_row['num1'] == (int)$num1 && (int)$tickets_row['num2'] == (int)$num2) {
                            $match2 = true;
                            echo "match 2<br/>";
                        } elseif ((int)$tickets_row['num1'] == (int)$num1 || (int)$tickets_row['num2'] == (int)$num2) {
                            $match1 = true;
                            echo "match 1<br/>";
                        }
                    }

                    // assign a label for the messages
                    if ($match4) {
                        $prize = 3;
                    } elseif ($match2) {
                        $prize = 2;
                    } elseif ($match1) {
                        $prize = 1;
                    }


                    if ($period_balance > 0) { // user did contribute enough to play
                        $to_add = round($base_interest[$row['treat_type']] * $period_balance, 2);
                        echo "positive period balance <br />";

                        if ($row['treat_type'] == "interest") {
                            echo "interest <br />";
                            // sms to user
                                $message = sprintf($draw_message["interest"], $period_balance, $base_interest["interest"]*100, $to_add, ($to_add + $total_balance));

                        } else {
                            echo "not interest <br />";

                            if ($match4 || $match2 || $match1) { // Won!!!
                                echo "won <br/>";
                                if ($match4 == true) {
                                    echo "match 4 <br />";
                                    $to_add = $period_balance * $match4_interest[$row['treat_type']];
                                } elseif ($match2 == true) {
                                    echo "match 2 <br />";
                                    $to_add = $period_balance * $match2_interest[$row['treat_type']];
                                } else {
                                    echo "match 1 <br />";
                                    $to_add = $period_balance * $match1_interest[$row['treat_type']];
                                }
                                $message = sprintf($draw_message[$row['treat_type']]["win"], $period_balance, $to_add, $num1 . $num2 . "-" . $num3 . $num4, $ticket_string, $total_balance + $to_add);
                            } else { // Lost
                                echo "lost <br/>";
                                echo "TOTAL BALANCE: $total_balance <br/>";
                                $message = sprintf($draw_message[$row['treat_type']]["lose"], $period_balance, $num1 . $num2 . "-" . $num3 . $num4, $ticket_string, $total_balance);
                            }
                        }
                    } else { // user did not contribute enough
                        echo "insufficient <br />";
                        if ($row['treat_type'] == "regret" && ($match1 || $match2 || $match4)) {
                            if ($match4 == true) {
                                echo "insufficient match 4<br/>";
                                $regret_amount = $period_balance * $match4_interest[$row['treat_type']];
                            } elseif ($match2 == true) {
                                $regret_amount = $period_balance * $match2_interest[$row['treat_type']];
                                echo "insufficient match 2<br />";
                            } else {
                                $regret_amount = $period_balance * $match1_interest[$row['treat_type']];
                                echo "insufficient match 1<br />";
                            }
                            echo "regret insufficient but would have won<br/>";
                            $message = sprintf($insufficient_message["regret_match"], $num1 . $num2 . "-" . $num3 . $num4, $ticket_string, $total_balance);
                        } elseif ($row['treat_type'] == "regret") {
                            echo "regret <br />";
                            $message = sprintf($insufficient_message["regret"], $period_balance, $num1 . $num2 . "-" . $num3 . $num4, $ticket_string, $total_balance);
                        } elseif ($row['treat_type'] == "lottery") {
                            echo "lottery <br />";
                            $message = sprintf($insufficient_message["lottery"], $period_balance, $num1 . $num2 . "-" . $num3 . $num4, $total_balance);
                        } else {
                            echo "interest (insufficient) <br/>";
                            $message = sprintf($insufficient_message["interest"], $period_balance, $total_balance);
                        }
                    }
                } else {
                    if ($row['treat_type'] == "interest") {
                        echo "shouldn't be here";
                        // this should be a regret match, but there is no match 
                        $message = sprintf($insufficient_message["interest"], $period_balance, $total_balance);
                    } elseif ($row['treat_type'] == "regret") {
                        echo "BOD task must have failed";
                        $ticket1 = rand($draw_min, $draw_max);
                        $ticket2 = rand($draw_min, $draw_max);
                        $ticket3 = rand($draw_min, $draw_max);
                        $ticket4 = rand($draw_min, $draw_max);
                        $ticket_string = "" . $ticket1 . $ticket2 . "-" . $ticket3 . $ticket4;

                        if ((int)$ticket1 == (int)$num1 && (int)$ticket2 == (int)$num2 && (int)$ticket3 == (int)$num3 && (int)$ticket4 == (int)$num4) {
                            $match4 = true;
                            echo "match 4<br/>";
                        } elseif ((int)$ticket1 == (int)$num1 && (int)$ticket2 == (int)$num2) {
                            $match2 = true;
                            echo "match 2<br/>";
                        } elseif ((int)$ticket1 == (int)$num1 || (int)$ticket2 == (int)$num2) {
                            $match1 = true;
                            echo "match 1<br/>";
                        }

                        if ($match1 || $match2 || $match4) {
                            if ($match4 == true) {
                                echo "insufficient match 4<br/>";
                                $regret_amount = $period_balance * $match4_interest[$row['treat_type']];
                            } elseif ($match2 == true) {
                                $regret_amount = $period_balance * $match2_interest[$row['treat_type']];
                                echo "insufficient match 2<br />";
                            } else {
                                $regret_amount = $period_balance * $match1_interest[$row['treat_type']];
                                echo "insufficient match 1<br />";
                            }
                            echo "regret insufficient but would have won<br/>";
                            $message = sprintf($insufficient_message["regret_match"], $num1 . $num2 . "-" . $num3 . $num4, $ticket_string, $total_balance);
                        } else {
                            echo "regret <br />";
                            $message = sprintf($insufficient_message["regret"], $period_balance, $num1 . $num2 . "-" . $num3 . $num4, $ticket_string, $total_balance);
                        }
                    } else {
                        echo "shouldn't be here";
                        $message = sprintf($insufficient_message["lottery"], $period_balance, $num1 . $num2 . "-" . $num3 . $num4, $total_balance);
                    }
                }

                $messages[$i] = array(
                        'content' => $message,
                        'phone_id' => $phone_id,
                        'to_number' => $row['account']
                );
                # send the appropriate message
                curl_setopt($ch[$i], CURLOPT_POSTFIELDS, http_build_query(array(
                    'content' => $message,
                    'phone_id' => $phone_id,
                    'to_number' => $row['account'],
                ), '', '&'));
                # add the $to_add to the ledger

                if ($to_add > 0) {
                        $mysqli->query("INSERT INTO `pls_ledger` (`account`, `amount`, `time`, `refund`, `prize`) VALUES ('" . $row['account'] . "', $to_add, '" . date("Y-m-d\TH:i:s") . "', 0, 1);");
                    }
                    // TODO


                    $i++;

                    # setup ticket for next period for the regret types
                    // if ($row['treat_type'] == "regret") {
                    //     // draw numbers
                    //     $num1 = rand($draw_min, $draw_max);
                    //     $num2 = rand($draw_min, $draw_max);
                    //     $num3 = rand($draw_min, $draw_max);
                    //     $num4 = rand($draw_min, $draw_max);
                    //     // add numbers for this user 1 hour in the future
                    //     $mysqli->query("INSERT INTO `pls_ticket` (`account`, `num1`, `num2`, `num3`, `num4`, `time`) VALUES ('" . $row['account'] . "', $num1, $num2, $num3, $num4, '" . date("Y-m-d\Th:i:s", time() + (60*60)) . "');");
                    //     // encourage them to save
                    //     $message = sprintf($encourage_regret, $num1 . $num2 . "-" . $num3 . $num4);

                    //     // add to the curl queue
                    //     $ch[$i] = curl_init();
                    //     curl_setopt($ch[$i], CURLOPT_URL, 
                    //         "https://api.telerivet.com/v1/projects/$project_id/messages/outgoing");
                    //     curl_setopt($ch[$i], CURLOPT_USERPWD, "{$api_key}:");  
                    //     curl_setopt($ch[$i], CURLOPT_RETURNTRANSFER, 1);
                    //     curl_setopt($ch[$i], CURLOPT_POSTFIELDS, http_build_query(array(
                    //         'content' => $message,
                    //         'phone_id' => $phone_id,
                    //         'to_number' => $row['account'],
                    //     ), '', '&'));
                    //     $i++;
                    // }
                }

            // testing
            print_r($messages);
            
            $mh = curl_multi_init();
            for ($i = 0; $i < count($ch); $i++) {
                curl_multi_add_handle($mh, $ch[$i+1]);
                echo "added message " . $i+1;
            }

            $active = null;
            #execute the handles
            if (!$dev_env) {
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
            }


                // print_r($mh);
                // print_r($ch);

                // execute the requests simultaneously
                // $running = 0;
                // do {
                //     curl_multi_exec($mh, $running);
                // } while ($running > 0);

                //close the handles
                // if win === false => skip $ch[0]
                // if (win === false) {
                    // remove $ch[0]
                    for ($i = 1; $i < count($ch); $i++) {
                        curl_multi_remove_handle($mh, $ch[$i]);
                    }
                // } else {
                //     for ($i = 0; $i < count($ch); $i++) {
                //         curl_multi_remove_handle($mh, $ch[$i]);
                //     }

                // }

                curl_multi_close($mh);

            }
            // add the drawing to the dataset
            $mysqli->query("INSERT INTO `pls_drawing` (`time_sent`, `num1`, `num2`, `num3`, `num4`) VALUES ('" . date("Y-m-d\TH:i:s") . "', $num1, $num2, $num3, $num4);");
        }
    }
