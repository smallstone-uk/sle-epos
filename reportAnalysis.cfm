<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>Report Analysis</title>
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<script src="ajax/js/jquery-1.11.1.min.js"></script>
</head>
<cfobject component="#application.site.codePath#" name="ecfc">
<cfparam name="reportDateFrom" default="#Now()#">
<cfparam name="reportDateTo" default="#Now()#">
<cfset startHour = 6>
<cfset endHour = 19>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset dates = ecfc.GetDates(parm)>
<cfif StructKeyExists(form,"reportDateFrom")>
	<cfset parm.reportDateFrom = form.reportDateFrom>
	<cfset parm.reportDateTo = form.reportDateTo>
	<cfquery name="QItemAnalysis" datasource="#parm.datasource#">
		SELECT prodID,prodCatID,prodEposCatID,prodTitle, siUnitSize, eiClass,eiType,eiNet,eiVAT, 
			ehID, ehTimeStamp, DATE(ehTimeStamp) AS yymmdd, HOUR(ehTimeStamp) AS hh, COUNT(*) AS recCount,
            (SELECT pcatTitle FROM tblProductCats WHERE pcatID = prodCatID) AS catTitle
		FROM tblEPOS_Items
		INNER JOIN tblEPOS_Header ON ehID = eiParent
		INNER JOIN tblProducts ON prodID = eiProdID
		LEFT JOIN tblStockItem ON prodID = siProduct
					AND tblStockItem.siID = (
						SELECT MAX( siID )
						FROM tblStockItem
						WHERE prodID = siProduct
						AND siStatus NOT IN ("returned","inactive") )
		WHERE DATE(ehTimeStamp) >= '#parm.reportDateFrom#'
		AND DATE(ehTimeStamp) <= '#parm.reportDateTo#'
		AND eiClass = 'sale'
        GROUP BY catTitle, prodTitle, siUnitSize, hh
	</cfquery>
</cfif>
<body>
	<div>
		<cfoutput>
			<div class="noPrint">
			<form method="post" enctype="multipart/form-data">
				Report From:
				<select name="reportDateFrom" id="reportDateFrom">
					<option value="">Select date...</option>
					<cfloop array="#dates.recs#" index="item">
					<option value="#item.value#" <cfif reportDateFrom eq item.value> selected</cfif>>#item.title#</option>
					</cfloop>
				</select>
				Report To:
				<select name="reportDateTo" id="reportDateTo">
					<option value="">Select date...</option>
					<cfloop array="#dates.recs#" index="item">
					<option value="#item.value#" <cfif reportDateTo eq item.value> selected</cfif>>#item.title#</option>
					</cfloop>
				</select>
				<input type="submit" name="btnGo" value="Go">
			</form>
			</div>
		</cfoutput>
	</div>
	<cfif StructKeyExists(variables,"QItemAnalysis")>
		<cfoutput>
			<cfset DayRange = reportDateTo - reportDateFrom + 1>
			<table class="tableList" border="1">
				<tr>
					<th colspan="28">From: #DateFormat(reportDateFrom,"ddd dd-mmm-yy")# To: #DateFormat(reportDateTo,"ddd dd-mmm-yy")# #DayRange# Days</th>
				</tr>
				<tr>
					<th>Category</th>
					<th>Product</th>
					<th>Size</th>
					<cfloop from="#startHour#" to="#endHour#" index="i">
						<th width="20" align="center">#i#</th>
					</cfloop>
					<th>Total</th>
				</tr>
				<cfset currProd = 0>
				<cfset totCount = 0>
				<cfset block = {}>
				<cfset totals = {}>
				<cfloop query="QItemAnalysis">
					<cfif currProd neq 0 AND currProd neq prodID>
						<tr>
							<td>#catTitle#</td>
							<td>#prodTitle#</td>
							<td>#siUnitSize#</td>
							<cfloop from="#startHour#" to="#endHour#" index="i">
								<cfif StructKeyExists(block,i)>
									<cfset theValue = StructFind(block,i)>
									<cfif StructKeyExists(totals,i)>
										<cfset oldValue = StructFind(totals,i)>
										<cfset StructUpdate(totals,i,oldValue + theValue)>
									<cfelse>
										<cfset StructInsert(totals,i,theValue)>
									</cfif>
									<td align="center">#theValue#</td>
								<cfelse>
									<td></td>
								</cfif>
							</cfloop>
							<td align="center">#totCount#</td>
						</tr>
						<cfset block = {}>
						<cfset totCount = 0>
					</cfif>
					<cfset currProd = prodID>
					<cfset totCount += recCount>
					<cfset StructInsert(block,hh,recCount)>
				</cfloop>
				<cfset grandTotal = 0>
				<tr>
					<th colspan="3">Totals</th>
					<cfloop from="#startHour#" to="#endHour#" index="i">
						<cfif StructKeyExists(totals,i)>
							<cfset hourTotal = StructFind(totals,i)>
							<cfset grandTotal += hourTotal>
							<th>#hourTotal#</th>
						<cfelse>
							<th></th>
						</cfif>
					</cfloop>
					<th>#grandTotal#</th>
				</tr>
			</table>
		</cfoutput>
	</cfif>
</body>
</html>
