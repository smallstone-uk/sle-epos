<cftry>
<!DOCTYPE html>
<html>
<head>
<title>JS Sandbox</title>
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<link href="css/virtualInput.css" rel="stylesheet" type="text/css">
<script src="../scripts/jquery-1.11.1.min.js"></script>
<script src="../scripts/jquery-ui.js"></script>
<script src="js/test.js"></script>
</head>

<cfoutput>
	<body id="content">
		<script>
			$(document).ready(function(e) {
				console.log($.core());
				var obj = $.core();
				obj.shout("Test");
			});
		</script>
		<div class="box"></div>
	</body>
</cfoutput>
</html>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>