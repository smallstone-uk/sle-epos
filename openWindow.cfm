<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>Open Window</title>
		<script src="js/jquery-1.11.1.min.js"></script>
		<script>
			$(document).ready(function() {
				function openWindow()	{
					var strWindowFeatures = "location=yes,width=480,height=320,scrollbars=0,status=0,titlebar=0,alwaysLowered=1,top=5,left=5,close=0";
					var URL = "openWindowContent.cfm";
					var win = window.open(URL, "customer", strWindowFeatures);
				}
				openWindow();
			});
		</script>
</head>

<body>

</body>
</html>
