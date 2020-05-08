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
</cfquery>
<cfif parm.accountID gt 0>
	<cfquery name="QAccountPurchases" datasource="#parm.datasource#">
		SELECT eiParent
		FROM `tblepos_items`
		WHERE `eiAccID` = #parm.accountID#
	</cfquery>
	<cfset parm.aIDs = QuotedValueList(QAccountPurchases.eiParent,",")>
	<cfset parm.aIDs = Replace(parm.aIDs,"'","","all")>
	
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
				<option value="#eaID#" <cfif eaID eq accountID> selected</cfif>>#eaID# #eaTitle#</option>
				</cfloop>
			</select>
			<input type="submit" name="btnGo" value="Go">
		</form>
		<div style="clear:both"></div>
		<div class="totalPanel">
			<div class="header">Tran Dump</div>
			<cfset ecfc.DumpTrans(parm)>
		</div>
		<div style="clear:both"></div>
		<cfif parm.accountID gt 0>
			<table class="tableList">
				<tr>
					<th>ID</th>
					<th>Mode</th>
					<th>Type</th>
					<th>Date</th>
					<th>Amount</th>
				</tr>
				<cfset balance = 0>
				<cfloop query="QAccountPayments">
					<tr>
						<td>#ehID#</td>
						<td>#ehMode#</td>
						<td>#eiType#</td>
						<td align="right">#DateFormat(ehTimeStamp)#</td>
						<td align="right">#DecimalFormat(eiNet + eiVAT)#</td>
					</tr>
					<cfset balance += (eiNet + eiVAT)>
				</cfloop>
				<cfif balance lt 0>
					<tr>
						<th colspan="3">Account in Credit</th>
						<th align="right">#DecimalFormat(balance)#</th>
					</tr>
				<cfelse>
					<tr>
						<th colspan="3">Balance Outstanding</th>
						<th align="right">#DecimalFormat(balance)#</th>
					</tr>
				</cfif>
			</table>
			<!---<cfdump var="#QAccountPayments#" label="QAccountPayments" expand="false">--->
		</cfif>
	</cfoutput>
</body>
</html>
