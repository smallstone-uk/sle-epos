<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<link rel="stylesheet" type="text/css" href="css/jquery-ui.css">
	<title>Day Report</title>
	<script src="js/jquery-1.11.1.min.js"></script>
	<script type="text/javascript">
		$(document).ready(function() {
			$('#quicksearch').on("keyup",function() {
				var srch=$(this).val();
				var hidetotals = false;
				$('.searchrow').each(function() {
					var id=$(this).attr("data-prodID");
					var str=$(this).attr("data-title");
					
					if (str.toLowerCase().indexOf(srch.toLowerCase()) == -1) {
						$(this).hide();
						hidetotals = true;
					} else {
						$(this).show();
					}
					
				});
				if (hidetotals) $('#pagetotals').hide()
					else $('#pagetotals').show();
			});
		});
	</script>
</head>
<body>
<cfoutput>
	<cfsetting requesttimeout="900">
	<cfset parm = {}>
	<cfset parm.datasource = application.site.datasource1>
	<cfobject component="#application.site.codePath#" name="ecfc">
	<cfobject component="code/epos" name="ep">
	<cfset dates = ecfc.GetDates(parm)>
	<cfif StructKeyExists(session,"till")>
		<cfset parm.reportDateFrom = session.till.prefs.reportDate>
	<cfelse>
		<cfset parm.reportDateFrom = Now()>
	</cfif>
	<cfset parm.reportDateTo = Now()>
	<cfif StructKeyExists(form,"reportDateFrom")>
		<cfflush interval="20">
		<p>Starting the report...</p>
			<cfset sysTime = GetTickCount()>
			<cfset parm.reportDateFrom = form.reportDateFrom>
			<cfset epos = ecfc.LoadEPOSTotals(parm)>
			<cfset tickNow = GetTickCount()>
			<p>#tickNow - sysTime#ms Load EPOS totals...</p>
		
		<cfset sysTime = GetTickCount()>
		<cfquery name="QItemSum2" datasource="#parm.datasource#">
			SELECT pcatGroup, prodCatID,prodEposCatID, eiClass,eiType, pgTitle,pgNomGroup, nomTitle, SUM(eiNet) AS net, SUM(eiVAT) as vat, Count(*) AS itemCount
			FROM `tblEPOS_Items`
			INNER JOIN tblEPOS_Header ON ehID = eiParent
			INNER JOIN tblProducts ON prodID = eiProdID
			INNER JOIN tblProductCats ON pcatID = prodCatID
			INNER JOIN tblProductGroups ON pgID = pcatGroup
			INNER JOIN tblNominal ON pgNomGroup = nomCode
			WHERE DATE( ehTimeStamp ) = '#form.reportDateFrom#'
			GROUP by pgNomGroup
		</cfquery>
		<cfset tickNow = GetTickCount()>
		<p>#tickNow - sysTime#ms Load group summary...</p>
		<!---<cfdump var="#QItemSum2#" label="QItemSum2" expand="false">--->

	</cfif>
	<div>
		<form method="post" enctype="multipart/form-data">
			Report Date:
			<select name="reportDateFrom" id="reportDate">
				<option value="">Select date...</option>
				<cfloop array="#dates.recs#" index="item">
				<option value="#item.value#" <cfif parm.reportDateFrom eq item.value> selected</cfif>>#item.title#</option>
				</cfloop>
			</select>
			<input type="checkbox" name="fixTotals" value="1" />Repair Till Totals
			<input type="submit" name="btnGo" value="Go">
		</form>
	</div>
</cfoutput>
</body>
</html>