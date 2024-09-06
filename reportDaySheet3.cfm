<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<link rel="stylesheet" type="text/css" href="css/jquery-ui.css">
	<title>Day Report 3</title>
	<script src="common/scripts/common.js"></script>
	<script src="js/jquery-1.11.1.min.js"></script>
	<script src="js/jquery-ui-1.10.3.custom.min.js"></script>
	<script src="js/jquery.dcmegamenu.1.3.3.js"></script>
	<script src="js/accounts.js" type="text/javascript"></script>
</head>

<cfobject component="code/epos15" name="ecfc">
<cfobject component="code/reports" name="rep">
<cfflush interval="20">
<cfsetting requesttimeout="900">
<cfoutput>
	<cfset parm = {}>
	<cfset parm.form = form>
	<cfset parm.datasource = application.site.datasource1>
	<cfset parm.url = application.site.normal>
	<cfset dates = ecfc.GetDates(parm)>
	<cfif StructKeyExists(session,"till")>
		<cfset parm.reportDateFrom = session.till.prefs.reportDate>
	<cfelse>
		<cfset parm.reportDateFrom = Now()>
	</cfif>
	<cfset parm.reportDateTo = Now()>
	<cfdump var="#parm#" label="parm" expand="false">
	
	<cfif StructKeyExists(form,"reportDateFrom")>
		<cfset parm.tranID = rep.LoadTransaction(parm)>
		<cfset data1 = rep.LoadData(parm)>
		<cfdump var="#data1#" label="data1" expand="false">
	</cfif>

	<body>
		<div>
			<form method="post" enctype="multipart/form-data" id="account-form">
				Report Date:
				<select name="reportDateFrom" id="reportDate">
					<option value="">Select date...</option>
					<cfloop array="#dates.recs#" index="item">
					<option value="#item.value#" <cfif parm.reportDateFrom eq item.value> selected</cfif>>#item.title#</option>
					</cfloop>
				</select>
				<input type="checkbox" name="fixTotals" value="1" />Repair Till Totals?
				<input type="checkbox" name="grossMode" value="1" checked="checked" />Gross Mode?
				<input type="submit" name="btnGo" value="Go">
			</form>
		</div>
	</body>
</cfoutput>
</html>
