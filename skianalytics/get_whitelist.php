<?php

$username="";
$password="";
$database="";

$secret="";

mysql_connect("5.1.88.84",$username,$password);
@mysql_select_db($database) or die( "Unable to select database");

if (!(isset($_POST["data"]) or isset($_POST["steamid"])))
{ 
	echo "None set";
	error_log("Not set");
	return; 
}

$data = json_decode($_POST["data"], true);
$steamid = mysql_real_escape_string($_POST["steamid"]);
echo $steamid;
$userid = 0;
$uresult = mysql_query("SELECT id FROM `players` WHERE `steamid`='$steamid'") or die(mysql_error());;
if (mysql_num_rows($uresult) == 1) { 
	$urecord = mysql_fetch_array($uresult);
	$userid = $urecord['id'];
} else {
	echo "User not found";
	error_log("User not found");
	return;
}

foreach ($data as $item) {
	print_r($item);
	$name = mysql_real_escape_string($item["name"]);
	$type = mysql_real_escape_string($item["dtype"]);
	$value = mysql_real_escape_string($item["value"]);
	$path = mysql_real_escape_string($item["path"]);
	$func = mysql_real_escape_string($item["func"]);

	$result = mysql_query("SELECT id FROM `ac_detections` WHERE type='$type' and `value`='$value'") or die(mysql_error());;

	if (mysql_num_rows($result) != 0) { 
		$record = mysql_fetch_array($result);	
		$detectid = $record['id'];
		mysql_query("INSERT into ac_userlog(userid, detectionid, status, date_added) 
			VALUES('$userid', '$detectid', '1', UTC_TIMESTAMP())") or die(mysql_error());;
	} else {
		mysql_query("INSERT into ac_detections(name, type, value, path, func, status, gamemode, date_added)
			VALUES('$name', '$type', '$value', '$path', '$func', '1', '1', UTC_TIMESTAMP())") or die(mysql_error());;
		$detectid = mysql_insert_id();
		mysql_query("INSERT into ac_userlog(userid, detectionid, status, date_added) 
			VALUES('$userid', '$detectid', '1', UTC_TIMESTAMP())") or die(mysql_error());;
	}
}
?>
