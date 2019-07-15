<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<title>EPOS Accounts</title>
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
		WHERE eiType = 'ACCPAY'
		AND `eiAccID` = #parm.accountID#
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
		<cfif parm.accountID gt 0><cfdump var="#QAccountPayments#" label="QAccountPayments" expand="false"></cfif>
	</cfoutput>
</body>
</html>
