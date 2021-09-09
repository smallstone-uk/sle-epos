<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<link href="css/jquery-ui.css" rel="stylesheet" type="text/css">
	<title>EPOS Accounts</title>
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
<cfparam name="accountID" default="0">
<cfparam name="reportDate" default="">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.accountID = accountID>
<cfset parm.reportDate = reportDate>
<cfsetting requesttimeout="30">
<cfflush interval="200">
<cfquery name="QAccountNames" datasource="#parm.datasource#">
	SELECT *
	FROM `tblepos_account`
	WHERE `eaMenu` = 'Yes'
	ORDER BY eaTitle
</cfquery>

<cfif parm.accountID gt 0>
	<cfquery name="QAccountPurchases" datasource="#parm.datasource#">	<!--- get parent ID of payment transactions for the account holder  --->
		SELECT eiParent
		FROM tblepos_items
		WHERE (`eiPayID` = #parm.accountID#	OR `eiAccID` = #parm.accountID#)
	</cfquery>
	<cfset parm.aIDs = QuotedValueList(QAccountPurchases.eiParent,",")>
	<cfset parm.aIDs = Replace(parm.aIDs,"'","","all")>		<!--- create csv list to pass on to tran dump --->
	
	<cfquery name="QAccountPayments" datasource="#parm.datasource#">
		SELECT *
		FROM `tblepos_items`
		INNER JOIN tblepos_header ON ehID = eiParent
		WHERE eiType IN ('ACCPAY','ACCINDW')
		AND (`eiPayID` = #parm.accountID#
			OR `eiAccID` = #parm.accountID#)
		<!---AND `eiAccID` = #parm.accountID#--->
		AND DATE(ehTimeStamp) >= '#parm.reportDate#'
		ORDER BY ehTimeStamp
	</cfquery>
	<cfquery name="loc.QSalesBFwd" datasource="#parm.datasource#">
		SELECT eiAccID, SUM(eiNet) AS Net
		FROM tblepos_items
		WHERE eiAccID = #parm.accountID#
		AND DATE(eiTimestamp) < '#parm.reportDate#'
		GROUP BY eiAccID
	</cfquery>
</cfif>

<cfset accountName = "">
<body>
	<cfoutput>
		<form method="post" enctype="multipart/form-data" class="noPrint">
			Choose Account:
			<select name="accountID" id="accountID">
				<option value="">Select account...</option>
				<cfloop query="QAccountNames">
					<cfset selectMe = "">
					<cfif eaID eq accountID>
						<cfset accountName = eaTitle>
						<cfset selectMe = " selected">
					</cfif>
					<option value="#eaID#"#selectMe#>#eaTitle#</option>
				</cfloop>
			</select>
			<input type="text" name="reportDate" value="#reportDate#" class="datepicker" />
			<input type="submit" name="btnGo" value="Go">
		</form>
		<div style="clear:both"></div>
		<cfif parm.accountID gt 0>
			<div class="totalPanel">
				<div class="header">Transaction Listing for #accountName#</div>
				<cfset ecfc.DumpTrans(parm)>
			</div>
			<div style="clear:both; page-break-after:always;"></div>
			<cfset balance = val(loc.QSalesBFwd.Net)>
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
					<th colspan="6">Brought Forward</th>
					<th align="right">#DecimalFormat(balance)#</th>
				</tr>
				<cfloop query="QAccountPayments">
					<cfset lineTotal = eiNet + eiVAT>
					<cfset balance += lineTotal>
					<tr>
						<td><a href="reporttransaction.cfm?tranID=#ehID#" target="trandetail">#ehID#</a></td>
						<td>#ehMode#</td>
						<td>#eiType#</td>
						<td align="right">#DateFormat(ehTimeStamp)#</td>
						<cfif lineTotal gte 0>
							<cfset drTotal += lineTotal>
							<td align="right">#DecimalFormat(lineTotal)#</td>
							<td align="right"></td>
						<cfelse>
							<cfset crTotal -= lineTotal>
							<td align="right"></td>
							<td align="right">#DecimalFormat(-lineTotal)#</td>
						</cfif>
						<td align="right">#DecimalFormat(balance)#</td>
					</tr>
				</cfloop>
				<tr>
					<th colspan="5">Totals</th>
					<th align="right">#DecimalFormat(drTotal)#</th>
					<th align="right">#DecimalFormat(crTotal)#</th>
				</tr>
				<cfif balance lt 0>
					<tr>
						<th colspan="5">Account in Credit</th>
						<th align="right">#DecimalFormat(balance)#</th>
						<th align="right"></th>
					</tr>
				<cfelse>
					<tr>
						<th colspan="6">Balance Outstanding</th>
						<th align="right">#DecimalFormat(balance)#</th>
					</tr>
				</cfif>
				<th></th>
			</table>
			<!---<cfdump var="#QAccountPayments#" label="QAccountPayments" expand="false">--->
		</cfif>
	</cfoutput>
</body>
</html>
