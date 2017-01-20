<?php
require_once('config_pls.php');

// connect to the database
$mysqli = new mysqli($host,$dbuser,$pw,$db);
if (mysqli_connect_errno($link)){
    echo "Failed to connect to MySQL: " . mysqli_connect_error();
die;
}


$draw_result = $mysqli->query("SELECT * FROM `pls_drawing` ORDER BY `time_sent`;");

$data = array();

if ($draw_result->num_rows > 0) {
    // csv version
    $data[] = array("ticket id", "account", "participant ticket", "winning ticket", "match type", "awarded", "period", "time");

    // load drawing array
    $drawing = array();
    while($draw_row = $draw_result->fetch_assoc()) {
        $drawing[] = $draw_row;
    }
    
    for ($i = 0; $i < count($drawing); $i++) {
        if ($i == 0) { // first drawing
            $query = "SELECT `pls_ticket`.*, `pls_subject`.`first_drawing_id` FROM `pls_ticket` LEFT JOIN `pls_subject` ON `pls_ticket`.`account` = `pls_subject`.`account` WHERE `time` < '" . $drawing[0]['time_sent'] . "';";
        } else {
            $query = "SELECT `pls_ticket`.*, `pls_subject`.`first_drawing_id` FROM `pls_ticket` LEFT JOIN `pls_subject` ON `pls_ticket`.`account` = `pls_subject`.`account` WHERE `time` < '" . $drawing[$i]['time_sent'] . "' AND `time` >= '" . $drawing[$i-1]['time_sent'] . "';";
        }

        $drawing_id = $drawing[$i]['id'];

        $ticket_result = $mysqli->query($query);
        if ($ticket_result->num_rows > 0) {
            while ($tickets_row = $ticket_result->fetch_assoc()) {
                // reset match indicators
                $match_type = 0;
                if ((int)$tickets_row['num1'] == (int)$drawing[$i]['num1'] && (int)$tickets_row['num2'] == (int)$drawing[$i]['num2'] && (int)$tickets_row['num3'] == (int)$drawing[$i]['num3'] && (int)$tickets_row['num4'] == (int)$drawing[$i]['num4']) {
                    $match_type = 4;
                } elseif ((int)$tickets_row['num1'] == (int)$drawing[$i]['num1'] && (int)$tickets_row['num2'] == (int)$drawing[$i]['num2']) {
                    $match_type = 2;
                } elseif ((int)$tickets_row['num1'] == (int)$drawing[$i]['num1'] || (int)$tickets_row['num2'] == (int)$drawing[$i]['num2']) {
                    $match_type = 1;
                }

                $user_period = $drawing_id + 2 - $tickets_row['first_drawing_id'];
                // csv version
                $data[] = array($tickets_row['id'], $tickets_row['account'], (int)$tickets_row['num1'] . (int)$tickets_row['num2'] . (int)$tickets_row['num3'] . (int)$ticket_row['num4'], (int)$drawing[$i]['num1'] . (int)$drawing[$i]['num2'] . (int)$drawing[$i]['num3'] . (int)$drawing[$i]['num4'], $match_type, $tickets_row['awarded'], $user_period, $tickets_row['time']);
            }
        }
    }

    // print footer
    //echo "</table></html>";
    // csv version (from http://stackoverflow.com/questions/3933668/convert-array-into-csv)

    header("Content-type: text/csv");
    header("Content-Disposition: attachment; filename=ticket_report_" . date('mdy') . ".csv");
    header("Pragma: no-cache");
    header("Expires: 0");

    $outputBuffer = fopen("php://output", "w");
    foreach($data as $val) {
        fputcsv($outputBuffer, $val);
    }
    fclose($outputBuffer);

} else {
    echo "No drawings";
}

