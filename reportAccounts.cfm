<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<title>EPOS Accounts</title>
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

<cfobject component="#application.site.codePath#" name="ecfc">
<cfparam name="accountID" default="0">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.accountID = accountID>
<cfset parm.reportDate = ''>
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
		FROM `tblepos_items`
		WHERE `eiAccID` = #parm.accountID#
	</cfquery>
	<cfset parm.aIDs = QuotedValueList(QAccountPurchases.eiParent,",")>
	<cfset parm.aIDs = Replace(parm.aIDs,"'","","all")>		<!--- create csv list to pass on to tran dump --->
	
	<cfquery name="QAccountPayments" datasource="#parm.datasource#">
		SELECT *
		FROM `tblepos_items`
		INNER JOIN tblepos_header ON ehID = eiParent
		WHERE eiType IN ('ACCPAY','ACCINDW')
		AND `eiAccID` = #parm.accountID#
		ORDER BY ehTimeStamp
	</cfquery>
</cfif>

<body>
	<cfoutput>
		<form method="post" enctype="multipart/form-data">
			Choose Account:
			<select name="accountID" id="accountID">
				<option value="">Select account...</option>
				<cfloop query="QAccountNames">
				<option value="#eaID#" <cfif eaID eq accountID> selected</cfif>>#eaTitle#</option>
				</cfloop>
			</select>
			<input type="submit" name="btnGo" value="Go">
		</form>
		<div style="clear:both"></div>
		<cfif parm.accountID gt 0>
			<div class="totalPanel">
				<div class="header">Transaction Listing</div>
				<cfset ecfc.DumpTrans(parm)>
			</div>
			<div style="clear:both; page-break-after:always;"></div>
			<table class="tableList">
				<tr>
					<th colspan="6">Account Transactions</th>
				</tr>
				<tr>
					<th>ID</th>
					<th>Mode</th>
					<th>Type</th>
					<th>Date</th>
					<th>Debit</th>
					<th>Credit</th>
				</tr>
				<cfset balance = 0>
				<cfset drTotal = 0>
				<cfset crTotal = 0>
				<cfloop query="QAccountPayments">
					<cfset lineTotal = eiNet + eiVAT>
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
					</tr>
					<cfset balance += (lineTotal)>
				</cfloop>
				<tr>
					<th colspan="4">Totals</th>
					<th align="right">#DecimalFormat(drTotal)#</th>
					<th align="right">#DecimalFormat(crTotal)#</th>
				</tr>
				<cfif balance lt 0>
					<tr>
						<th colspan="5">Account in Credit</th>
						<th align="right">#DecimalFormat(balance)#</th>
					</tr>
				<cfelse>
					<tr>
						<th colspan="5">Balance Outstanding</th>
						<th align="right">#DecimalFormat(balance)#</th>
					</tr>
				</cfif>
			</table>
			<!---<cfdump var="#QAccountPayments#" label="QAccountPayments" expand="false">--->
		</cfif>
	</cfoutput>
</body>
</html>
