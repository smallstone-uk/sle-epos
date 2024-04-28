<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<link href="css/jquery-ui.css" rel="stylesheet" type="text/css">
	<title>News Account Payments</title>
	<script src="js/jquery-1.11.1.min.js"></script>
	<script src="js/jquery-ui.js"></script>
	<script type="text/javascript">
		$(document).ready(function() {
			$('.datepicker').datepicker({dateFormat: "yy-mm-dd",changeMonth: true,changeYear: true,showButtonPanel: true, minDate: new Date(2013, 1 - 1, 1)});
		});
	</script>
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

<cfobject component="#application.site.codePath#" name="ecfc">
<cfparam name="accountID" default="10">		<!--- News account payments via till --->
<cfparam name="reportDateFrom" default="">
<cfparam name="reportDateTo" default="">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.accountID = accountID>
<cfset parm.reportDateFrom = reportDateFrom>
<cfset parm.reportDateTo = DateAdd("d",1,parm.reportDateFrom)>
<cfsetting requesttimeout="30">
<cfflush interval="200">

<cfif len(parm.reportDate) gt 0>
	<cfquery name="QAccounts" datasource="#parm.datasource#">	<!--- get parent IDs of transactions for the target product ID  --->
		SELECT eiParent
		FROM tblepos_items
		WHERE eiProdID = #parm.accountID#
	</cfquery>
	<cfset parm.aIDs = QuotedValueList(QAccounts.eiParent,",")>
	<cfset parm.aIDs = Replace(parm.aIDs,"'","","all")>		<!--- create csv list to pass on to tran dump --->
</cfif>

<cfset accountName = "">
<body>
	<cfoutput>
		<form method="post" enctype="multipart/form-data" class="noPrint">
			<input type="text" name="reportDateFrom" value="#reportDateFrom#" class="datepicker" />
			<input type="text" name="reportDateTo" value="#reportDateTo#" class="datepicker" />
			<input type="submit" name="btnGo" value="Go">
		</form>
		<div style="clear:both"></div>
		<cfif parm.accountID gt 0>
			<div class="totalPanel">
				<div class="header">Transaction Listing for #accountName#</div>
				<cfset ecfc.DumpTrans(parm)>
			</div>
			<div style="clear:both; page-break-after:always;"></div>
			<cfset drTotal = 0>
			<cfset crTotal = 0>
			<table class="tableList" width="600">
				<tr>
					<th colspan="7">Account Transactions for #accountName#</th>
				</tr>
				<tr>
					<th>ID</th>
					<th>Mode</th>
					<th>Type</th>
					<th align="right">Date</th>
					<th align="right">Debit</th>
					<th align="right">Credit</th>
					<th align="right">Balance</th>
				</tr>
				<tr>
					<th colspan="5">Totals</th>
					<th align="right">#DecimalFormat(drTotal)#</th>
					<th align="right">#DecimalFormat(crTotal)#</th>
				</tr>
			</table>
		</cfif>
	</cfoutput>
</body>
</html>
