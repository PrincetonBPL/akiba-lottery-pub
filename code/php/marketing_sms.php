<?php
/**
 * This is the webhook url for the marketing service
 */

require_once('config.php');

// this function returns a new code used when creating a user. All codes begin with a letter.
// inspired by: http://www.webtoolkit.info/php-random-password-generator.html
function generateCode($length=6) {
    $numbers = "23456789";
    $letters = "BDGHJLMNPQRSTVWXZAEUY";
    $code = '';
    $alt = 0;
    for ($i = 0; $i < $length; $i++) {
        if ($alt == 1) {
            $code .= $numbers[rand(0,strlen($numbers)-1)];
            $alt = 0;
        } else {
            $code .= $letters[rand(0,strlen($letters)-1)];
            $alt = 1;
        }
    }
    return $code;
}

$secret = "CPUDML6H2NNTDZ37XHUWXUL9URT236RF";

if ($_POST['secret'] !== $secret){
    header('HTTP/1.1 403 Forbidden');
    echo "Invalid webhook secret";
} else {

    if ($_POST['event'] == 'incoming_message'){
        
        $from_number = $_POST['from_number'];
        $content = $_POST['content'];

        $messages = array();
        
        // split the string into the command and any notes
        $command = strtok($content," ");
        $notes = trim(substr($content,strpos($content," ")));

        // connect to the database
        $mysqli = new mysqli($host,$dbuser,$pw,$db);
        if (mysqli_connect_errno($link)){
            echo "Failed to connect to MySQL: " . mysqli_connect_error();
        }

        // Code requests
        if(stripos($command,"reg")===0 || strtolower($command)=="code"){ // register phone, $from_number, as a vendor
            // check to make sure user is not already registered
            $result = $mysqli->query("SELECT * FROM `market_vendor` WHERE `number` LIKE '" . $from_number . "'");
            $results = $result->num_rows;
            if($result->num_rows>0){ // user already has a code
                while($row = $result->fetch_assoc()){
                    $messages[] = array("content" => "Your code is " . $row['code'] . ". Reply with 'SEND ...' to send a message to your subscribers.",
                        "status_url" => "http://www.economistry.com/sms/status_sms.php");
                }
            } else {
                // create a code for this user.
                $vendor_code = generateCode(6);
                $code_is_original = false;
                while (!$code_is_original) {
                    $result = $mysqli->query("SELECT * FROM `market_vendor` WHERE `code` LIKE '" . $vendor_code . "'");
                    if($result->num_rows===0){
                        $code_is_original = true;
                    } else {
                        $vendor_code = generateCode(6);
                    }
                }

                // create entry in db
                $mysqli->query("INSERT INTO `market_vendor` (`id`,`number`,`code`) VALUES (NULL,'" . $from_number . "','" . $vendor_code . "')");
                $messages[] = array("content" => "Your code is $vendor_code. Reply with 'SEND ...' to send a message to your subscribers.",
                        "status_url" => "http://www.economistry.com/sms/status_sms.php");
            }
        } else if(stripos($command,"sub")===0){ // subscribe to vendor with the given code
            // subscribe
            $vendor_code = strtok(" "); // get the next token
            // check to see if the code exists
            $result = $mysqli->query("SELECT * FROM `market_vendor` WHERE `code` LIKE '" . $vendor_code . "'");
            if($result->num_rows>0){
                // code exists
                $mysqli->query("INSERT INTO `market_client` (`id`,`number`,`code`) VALUES (NULL,'" . $from_number . "','" . $vendor_code . "')");
                $messages[] = array("content" => "Congratulations! You will now receive announcements from vendor " . $vendor_code . ". Reply 'UNSUBSCRIBE " . $vendor_code . "' to stop receiving announcements.",
                        "status_url" => "http://www.economistry.com/sms/status_sms.php");
            } else {
                // there is no such code
                $messages[] = array("content" => "Sorry this code is not active. Please see your vendor to request an updated code.",
                        "status_url" => "http://www.economistry.com/sms/status_sms.php");
            }
        } else if(stripos($command,"unsub")===0){ // unsubscribe from vendor with the given code
            // subscribe
            $vendor_code = strtok(" "); // get the next token
            // check to see if the code exists
            $result = $mysqli->query("SELECT * FROM `market_vendor` WHERE `code` LIKE '" . $vendor_code . "'");
            if($result->num_rows>0){
                // code exists
                $mysqli->query("DELETE FROM `market_client` WHERE `number` LIKE '" . $from_number . "' AND `code` LIKE '" . $vendor_code . "'");
                $messages[] = array("content" => "You will no longer receive announcements from vendor " . $vendor_code . ". Reply 'SUBSCRIBE " . $vendor_code . "' to begin receiving announcements again.",
                        "status_url" => "http://www.economistry.com/sms/status_sms.php");
            } else {
                // there is no such code
                $messages[] = array("content" => "Sorry this code is not active. Please see your vendor to request an updated code.",
                        "status_url" => "http://www.economistry.com/sms/status_sms.php");
            }
        } else if(strtolower($command)=="send"){ // send message to subscribers
            // check to see if there are any subscribers to this vendor
            $result = $mysqli->query("SELECT `market_vendor`.`code`, `market_client`.`number` FROM `market_vendor`,`market_client` WHERE `market_vendor`.`number` LIKE '" . $from_number . "' AND `market_vendor`.`code` = `market_client`.`code`");
            if($result->num_rows>0){
                // create an array of the phone numbers to send the message to
                //$number_list = array();
                while ($row = $result->fetch_assoc()) {
                    $messages[] = array("content" => $notes, "to_number" => $row['number'],
                        "status_url" => "http://www.economistry.com/sms/status_sms.php");
                }

                // return a reply indicating success
                $messages[] = array("content" => "Your announcement was sent to " . $result->num_rows . " subscribers.",
                        "status_url" => "http://www.economistry.com/sms/status_sms.php");

            } else {
                // no subscribers
                $messages[] = array("content" => "Sorry, you do not have any subscribers to send your announcement.",
                        "status_url" => "http://www.economistry.com/sms/status_sms.php");
            }
            

        }

        header("Content-Type: application/json");
        echo json_encode(array(
            'messages' => $messages
        ));
        
    }    
}