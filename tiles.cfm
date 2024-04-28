<!DOCTYPE html>
<html>
<head>
<title>EPOS</title>
</head>

<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset employees = epos.LoadEmployees()>

<cfoutput>
	<body>
		<link rel="stylesheet" href="css/sandbox.css">
		<link rel="stylesheet" href="css/demo-styles.css" />
		<link rel="stylesheet" href="icomoon/style.css" />
		<script>
			$(document).ready(function(e) {
				$.get("ajax/loadHomeScreen.cfm", function(data) {
					$('.home_screen_content').html(data);
				});
				$('*').addClass("disable-select");
			});
		</script>
		<div class="home_screen_content"></div>
	</body>
</cfoutput>
</html>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>