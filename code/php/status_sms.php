<?php
    $status_secret_market = 'CPUDML6H2NNTDZ37XHUWXUL9URT236RF';
    $status_secret_pls = 'MFADTXHQ29K7TECAZ2X4GGENCTLH7GXU';

    require_once('config.php');
    
    if ($_POST['secret'] !== $status_secret_market && $_POST['secret'] !== $status_secret_pls) {
        header('HTTP/1.1 403 Forbidden');
        echo "Invalid status secret";
    } else {
        if ($_POST['event'] == 'send_status') {
            //$id = $_POST['id'];
            $status = $_POST['status'];
            $error_message = $_POST['error_message'];
            $time_created = $_POST['time_created'];
            $from_number = $_POST['from_number'];
            $to_number = $_POST['to_number'];
            $content = $_POST['content'];
            
            if ($_POST['status']=="failed" || $_POST['status']=="cancelled") {
            	// connect to the database
				$mysqli = new mysqli($host,$dbuser,$pw,$db);
				if (mysqli_connect_errno($link)){
					echo "Failed to connect to MySQL: " . mysqli_connect_error();
				} else {
					$mysqli->query("INSERT INTO `errors` (`id`,`status`,`error_message`," . 
						"`from_number`,`to_number`,`content`,`time_created`) VALUES (NULL," . 
						"$status,$error_message,$from_number,$to_number,$content,NULL)");
				}

            }
        }    
    }
