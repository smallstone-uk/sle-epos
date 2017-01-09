<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<title>Day Report</title>
</head>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfobject component="#application.site.codePath#" name="ecfc">
<cfset dates = ecfc.GetDates(parm)>
<cfif StructKeyExists(session,"till")>
	<cfset parm.reportDate = session.till.prefs.reportDate>
<cfelse>
	<cfset parm.reportDate = Now()>
</cfif>

<cfif StructKeyExists(form,"reportDate")>
	<cfset parm.reportDate = form.reportDate>
	<cfset epos = ecfc.LoadEPOSTotals(parm)>
	<cfquery name="QItemSummary" datasource="#parm.datasource#">
		SELECT pcatGroup, prodCatID,prodEposCatID, eiClass, eiType, pgTitle, SUM(eiNet) AS net, SUM(eiVAT) as vat, Count(*) AS itemCount
		FROM `tblEPOS_Items`
		INNER JOIN tblEPOS_Header ON ehID = eiParent
		INNER JOIN tblProducts ON prodID = eiProdID
		INNER JOIN tblProductCats ON pcatID = prodCatID
		INNER JOIN tblProductGroups ON pgID = pcatGroup
		WHERE DATE( ehTimeStamp ) = '#form.reportDate#'
		GROUP by eiClass, eiType, pgTitle,prodEposCatID
	</cfquery>
</cfif>
<body>
	<cfoutput>
		<div>
			<form method="post" enctype="multipart/form-data">
				Report Date: 
				<select name="reportDate" id="reportDate">
					<option value="">Select date...</option>
					<cfloop array="#dates.recs#" index="item">
						<option value="#item.value#" <cfif parm.reportDate eq item.value> selected</cfif>>#item.title#</option>
					</cfloop>
				</select>
				<input type="submit" name="btnGo" value="Go">
			</form>
		</div>
		<cfif StructKeyExists(form,"reportDate")>
			<div id="xreading3" class="totalPanel">
				<div class="header">Shop Daysheet Summary</div>
				<table width="500" class="tableList" border="1">
					<tr>
						<th>Group</th>
						<th>Title</th>
						<th>Class</th>
						<th>Type</th>
						<th align="right">DR</th>
						<th align="right">CR</th>
						<th align="right">Count</th>
					</tr>
					<cfset crtotal = 0>
					<cfset drtotal = 0>
					<cfset vatTotal = 0>
					<cfset countTotal = 0>
					<cfloop query="QItemSummary">
						<cfset countTotal += itemCount>
						<cfset vatTotal += vat>
						<cfset gross = net + vat>
						<cfif gross gt 0><cfset drtotal += gross>
							<cfelse><cfset crtotal += gross></cfif>
						<tr>
							<td>#pcatGroup#</td>
							<td>#pgTitle#</td>
							<td>#eiClass#</td>
							<td>#eiType#</td>
							<td align="right"><cfif gross gt 0>#DecimalFormat(net)#</cfif></td>
							<td align="right"><cfif gross lt 0>#DecimalFormat(-net)#</cfif></td>
							<td align="right">#itemCount#</td>
						</tr>
					</cfloop>
						<tr>
							<td></td>
							<td>SALES VAT TOTAL</td>
							<td></td>
							<td></td>
							<td align="right"><cfif vatTotal gt 0>#DecimalFormat(vatTotal)#</cfif></td>
							<td align="right"><cfif vatTotal lt 0>#DecimalFormat(-vatTotal)#</cfif></td>
							<td></td>
						</tr>
						<tr>
							<th align="right" colspan="4">Totals</th>
							<th align="right">#DecimalFormat(drtotal)#</th>
							<th align="right">#DecimalFormat(-crtotal)#</th>
							<th align="right">#countTotal#</th>
						</tr>
						<cfif abs(drtotal + crtotal) gt 0.001>
							<tr>
								<th align="right" colspan="4">Error</th>
								<th></th>
								<th align="right">#DecimalFormat(drtotal + crtotal)#</th>
								<th></th>
							</tr>
						</cfif>
				</table>
			</div>
			<div id="xreading4" class="totalPanel">
				<div class="header">Till Totals</div>
				<table class="tableList" border="1">
					<tr>
						<th>DESCRIPTION</th>
						<th width="70" align="right">DR</th>
						<th width="70" align="right">CR</th>
					</tr>
					<cfset drTotal = 0>
					<cfset crTotal = 0>
					<cfset loopcount = 0>
					<cfset keys = ListSort(StructKeyList(epos.accounts,","),"text","ASC",",")>
					<cfloop list="#keys#" index="fld">
						<tr>
							<td>#fld#</td>
							<td align="right">
								<cfif epos.accounts[fld] gt 0>
									<cfset drTotal += epos.accounts[fld]>
									#DecimalFormat(epos.accounts[fld])#
								</cfif>
							</td>
							<td align="right">
								<cfif epos.accounts[fld] lt 0>
									<cfset crTotal -= epos.accounts[fld]>
									#DecimalFormat(epos.accounts[fld] * -1)#
								</cfif>
							</td>
						</tr>
					</cfloop>
					<tr>
						<td><strong>Totals</strong></td>
						<td align="right"><strong>#DecimalFormat(drTotal)#</strong></td>
						<td align="right"><strong>#DecimalFormat(crTotal)#</strong></td>
					</tr>
				</table>
			</div>
			<div style="clear:both"></div>
			<div class="totalPanel">
				<div class="header">Tran Dump</div>
					<cfset parm = {}>
					<cfset parm.reportDate = form.reportDate>
					<cfset ecfc.DumpTrans(parm)>
			</div>
			<div style="clear:both"></div>
		</cfif>
	</cfoutput>
</body>
</html>