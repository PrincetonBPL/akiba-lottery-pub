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
    // print header
    //echo "<html><h1>Regret: Would have won, but did not save</h1><table><tr><td>id</td><td>account</td><td>participant ticket</td><td>winning ticket</td><td>match type</td><td>awarded</td></tr>";
    // csv version
    $data[] = array("ticket id", "account", "participant ticket", "winning ticket", "match type", "awarded");

    // load drawing array
    $drawing = array();
    while($draw_row = $draw_result->fetch_assoc()) {
        $drawing[] = $draw_row;
    }
    
    for ($i = 0; $i < count($drawing); $i++) {
        if ($i == 0) { // first drawing
            $query = "SELECT * FROM `pls_ticket` WHERE `time` < '" . $drawing[0]['time_sent'] . "';";
        } else {
            $query = "SELECT * FROM `pls_ticket` WHERE `time` < '" . $drawing[$i]['time_sent'] . "' AND `time` >= '" . $drawing[$i-1]['time_sent'] . "';";
        }

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
                if ($match_type > 0 && $tickets_row['awarded'] == 0) {
                    //echo "<tr><td>" . $tickets_row['id'] . "</td>";
                    //echo "<td>" . $tickets_row['account'] . "</td>";
                    //echo "<td>" . (int)$tickets_row['num1'] . (int)$tickets_row['num2'] . "-" . (int)$tickets_row['num3'] . (int)$ticket_row['num4'] . "</td>";
                    //echo "<td>" . (int)$drawing[$i]['num1'] . (int)$drawing[$i]['num2'] . "-" . (int)$drawing[$i]['num3'] . (int)$drawing[$i]['num4'] . "</td>";
                    //echo "<td>$match_type</td>";
                    //echo "<td>" . $tickets_row['awarded'] . "</td></tr>";
                    // csv version
                    $data[] = array($tickets_row['id'], $tickets_row['account'], (int)$tickets_row['num1'] . (int)$tickets_row['num2'] . (int)$tickets_row['num3'] . (int)$ticket_row['num4'], (int)$drawing[$i]['num1'] . (int)$drawing[$i]['num2'] . (int)$drawing[$i]['num3'] . (int)$drawing[$i]['num4'], $match_type, $tickets_row['awarded']);
                }
            }
        }
    }

    // print footer
    //echo "</table></html>";
    // csv version (from http://stackoverflow.com/questions/3933668/convert-array-into-csv)

    header("Content-type: text/csv");
    header("Content-Disposition: attachment; filename=regret_report_" . date('mdy') . ".csv");
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
