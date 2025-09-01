<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>Shop Analysis by Hour</title>
	<link href="css/main3.css" rel="stylesheet" type="text/css">
	<link rel="stylesheet" type="text/css" href="css/chosen.css" rel="stylesheet" />
	<link rel="stylesheet" type="text/css" href="css/jquery-ui-1.10.3.custom.min.css" />
	<script src="js/jquery-1.11.1.min.js" type="text/javascript"></script>
	<script src="js/jquery-ui-1.10.3.custom.min.js" type="text/javascript"></script>
	<script src="js/chosen.jquery.js" type="text/javascript"></script>
	<script type="text/javascript">
		function LoadData(form,result) {
			console.log($(form).serialize());
			$.ajax({
				type: 'POST',
				url: 'ajax/loadEPOSData.cfm',
				data: $(form).serialize(),
				beforeSend:function(){
					$(result).html("<img src='images/loading_2.gif' class='loadingGif' style='float:none;'>&nbsp;Loading data...");
				},
				success:function(data){
					$(result).html(data);
				}
			});
		}
		$(document).ready(function() {
			$('.datepicker').datepicker({dateFormat: "dd-mm-yy",changeMonth: true,changeYear: true,showButtonPanel: true, minDate: new Date(2013, 1 - 1, 1)});
			$('#btnGo').click(function(e) {
				e.preventDefault(); // stop form submission
				LoadData("#srchForm","#result");
			});
		});
	</script>
	<style>
		.negativeNum {color:#FF0000}
		.qty {color:#FF00FF}
		.trade {color:#0000FF}
		.smallTitle {font-size:12px;}
		.smallTable {border-collapse:collapse;}
		.smallTable tr {height:14px; white-space: nowrap;}
		.smallTable td {height:14px; line-height:14px}
	</style>
</head>

<body>
<cfobject component="#application.site.codePath#" name="ecfc">
<cfobject component="code/reports" name="report">
<cfparam name="reportMode" default="reg">
<cfparam name="srchHourFrom" default="6">
<cfparam name="srchHourTo" default="19">

<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<div>
	<cfoutput>
		<div class="noPrint">
			<form method="post" name="srchForm" id="srchForm" enctype="multipart/form-data">
				<table class="tableList" border="1">
					<tr>
						<td>Report From:</td>
						<td><input type="text" name="srchDateFrom" id="srchDateFrom" class="datepicker" size="10" autoComplete="off"  /></td>
						<td>Report To:</td>
						<td><input type="text" name="srchDateTo" id="srchDateTo" class="datepicker" size="10" autocomplete="off"  /></td>
						<td>
							<select name="reportMode" id="reportMode">
								<option value="" <cfif reportMode eq ""> selected</cfif>>Any Mode</option>
								<option value="reg" <cfif reportMode eq "reg"> selected</cfif>>Reg Mode</option>
								<option value="rfd" <cfif reportMode eq "rfd"> selected</cfif>>Refund Mode</option>
								<option value="wst" <cfif reportMode eq "wst"> selected</cfif>>Waste Mode</option>
							</select>
						</td>
					</tr>
					<tr>
						<td>Time From:</td>
						<td>
							<select name="srchHourFrom" id="srchHourFrom">
								<option value="">Select hour...</option>
								<cfloop from="0" to="23" index="item">
									<option value="#item#" <cfif srchHourFrom eq item> selected</cfif>>#NumberFormat(item,"00")#</option>
								</cfloop>
							</select>
						</td>
						<td>Time To:</td>
						<td>
							<select name="srchHourTo" id="srchHourTo">
								<option value="">Select hour...</option>
								<cfloop from="0" to="23" index="item">
									<option value="#item#" <cfif srchHourTo eq item> selected</cfif>>#NumberFormat(item,"00")#</option>
								</cfloop>
							</select>	
						</td>
						<td><input type="submit" name="btnGo" id="btnGo" value="Go"></td>
					</tr>
				</table>
			</form>
		</div>
	</cfoutput>
	<div id="result"></div>
</div>

</body>
</html>