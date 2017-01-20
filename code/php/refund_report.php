<?php
require_once('config_pls.php');

// connect to the database
$mysqli = new mysqli($host,$dbuser,$pw,$db);
if (mysqli_connect_errno($link)){
    echo "Failed to connect to MySQL: " . mysqli_connect_error();
die;
}


$result = $mysqli->query("SELECT * FROM `pls_ledger` WHERE `refund` = 1 AND `refund_sent` = 0 ORDER BY `time`;");

$data = array();

if ($result->num_rows > 0) {
    // csv version
    $data[] = array("id", "account", "amount", "time", "refund", "refund_sent", "prize");

    // load drawing array
    while($row = $result->fetch_assoc()) {
        $data[] = array(
            $row['id'],
            $row['account'],
            $row['amount'],
            $row['time'],
            $row['refund'],
            $row['refund_sent'],
            $row['prize'],
        );
    }

    header("Content-type: text/csv");
    header("Content-Disposition: attachment; filename=refund_report_" . date('mdy') . ".csv");
    header("Pragma: no-cache");
    header("Expires: 0");

    $outputBuffer = fopen("php://output", "w");
    foreach($data as $val) {
        fputcsv($outputBuffer, $val);
    }
    fclose($outputBuffer);

} else {
    echo "No unsent refunds";
}
