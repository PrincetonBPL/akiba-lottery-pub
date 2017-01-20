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
    $data[] = array("account", "amount", "time", "refund", "prize", "period");

    // load drawing array
    $drawing = array();
    while($draw_row = $draw_result->fetch_assoc()) {
        $drawing[] = $draw_row;
    }
    
    for ($i = 0; $i < count($drawing); $i++) {
        if ($i == 0) { // first drawing
            $query = "SELECT `pls_ledger`.*, `pls_subject`.`first_drawing_id` FROM `pls_ledger` LEFT JOIN `pls_subject` ON `pls_ledger`.`account` = `pls_subject`.`account` WHERE `time` < '" . $drawing[0]['time_sent'] . "';";
        } elseif ($i == count($drawing) - 1) {
            $query = "SELECT `pls_ledger`.*, `pls_subject`.`first_drawing_id` FROM `pls_ledger` LEFT JOIN `pls_subject` ON `pls_ledger`.`account` = `pls_subject`.`account` WHERE `time` >= '" . $drawing[$i-1]['time_sent'] . "';";
        } else {
            $query = "SELECT `pls_ledger`.*, `pls_subject`.`first_drawing_id` FROM `pls_ledger` LEFT JOIN `pls_subject` ON `pls_ledger`.`account` = `pls_subject`.`account` WHERE `time` < '" . $drawing[$i]['time_sent'] . "' AND `time` >= '" . $drawing[$i-1]['time_sent'] . "';";
        }

        $drawing_id = $drawing[$i]['id'];

        $ledger_result = $mysqli->query($query);
        if ($ledger_result->num_rows > 0) {
            while ($ledger_row = $ledger_result->fetch_assoc()) {
                $user_period = $drawing_id + 1 - $ledger_row['first_drawing_id'];
                // csv version
                $data[] = array($ledger_row['account'], $ledger_row['amount'], $ledger_row['time'], $ledger_row['refund'], $ledger_row['prize'], $user_period);
            }
        }
    }

    // print footer
    //echo "</table></html>";
    // csv version (from http://stackoverflow.com/questions/3933668/convert-array-into-csv)

    header("Content-type: text/csv");
    header("Content-Disposition: attachment; filename=ledger_report_" . date('mdy') . ".csv");
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
