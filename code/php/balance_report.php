<?php
date_default_timezone_set("Africa/Nairobi");

require_once('config_pls.php');

# connect to the database
$mysqli = new mysqli($host,$dbuser,$pw,$db);
if (mysqli_connect_errno($link)){
    echo "Failed to connect to MySQL: " . mysqli_connect_error();
die;
}


$draw_result = $mysqli->query("SELECT `id` FROM `pls_drawing` ORDER BY `id` DESC LIMIT 1;");

$data = array();

if ($draw_result->num_rows > 0) {
    // csv version
    $data[] = array("name", "phone_number", "total_balance", "survey_id", "treat_type", "current_period", "auth");

    # load drawing array
    $drawing = array();
    while($draw_row = $draw_result->fetch_assoc()) {
        $drawing_id = $draw_row['id'];
    }
    
    $query = "SELECT `name`, `account`, `survey_id`, `treat_type`, `auth`, `first_drawing_id`, sum(`amount`) AS 'balance' FROM (SELECT `pls_ledger`.`amount`, `pls_subject`.* FROM `pls_ledger` RIGHT OUTER JOIN `pls_subject` ON `pls_ledger`.`account` = `pls_subject`.`account`) AS tbl1 GROUP BY `account`";

    $ledger_result = $mysqli->query($query);
    if ($ledger_result->num_rows > 0) {
        while ($ledger_row = $ledger_result->fetch_assoc()) {
            $user_period = $drawing_id + 2 - $ledger_row['first_drawing_id'];
            # csv version
            $data[] = array($ledger_row['name'], $ledger_row['account'], $ledger_row['balance'], $ledger_row['survey_id'], $ledger_row['treat_type'], $user_period, $ledger_row['auth']);
        }
    }

    // print footer
    //echo "</table></html>";
    // csv version (from http://stackoverflow.com/questions/3933668/convert-array-into-csv)

    header("Content-type: text/csv");
    header("Content-Disposition: attachment; filename=balance_report_" . date('mdy') . ".csv");
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

