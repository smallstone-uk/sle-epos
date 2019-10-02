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

<cfif StructKeyExists(form,"reportDateFrom") AND len(form.reportDateFrom) gt 0>
	<cfset parm.reportDateFrom = form.reportDateFrom>
	<cfset parm.reportDateTo = form.reportDateTo>
	<cfif len(form.reportDateTo) IS 0><cfset parm.reportDateTo = form.reportDateFrom></cfif>
	<cfquery name="QItemAnalysis" datasource="#parm.datasource#">
		SELECT prodID,prodCatID,prodEposCatID,prodTitle, siUnitSize, eiClass,eiType,eiNet,eiVAT, 
			ehID, ehTimeStamp, DATE(ehTimeStamp) AS yymmdd, HOUR(ehTimeStamp) AS hh, COUNT(*) AS recCount,
            (SELECT pcatTitle FROM tblProductCats WHERE pcatID = prodCatID) AS catTitle,
            (SELECT pgTitle FROM tblProductGroups INNER JOIN tblProductCats on pcatGroup=pgID WHERE pcatID = prodCatID) AS groupTitle
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
        GROUP BY groupTitle, catTitle, prodTitle, siUnitSize, hh
	</cfquery>
<cfelse>
	<p>Please select start date.</p>
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
					<option value="#item.value#" <cfif reportDateFrom eq item.value> selected</cfif>>#DateFormat(item.value,'ddd dd-mmm-yy')#</option>
					</cfloop>
				</select>
				Report To:
				<select name="reportDateTo" id="reportDateTo">
					<option value="">Select date...</option>
					<cfloop array="#dates.recs#" index="item">
					<option value="#item.value#" <cfif reportDateTo eq item.value> selected</cfif>>#DateFormat(item.value,'ddd dd-mmm-yy')#</option>
					</cfloop>
				</select>
				<input type="submit" name="btnGo" value="Go">
			</form>
			</div>
		</cfoutput>
	</div>
	<cfif StructKeyExists(variables,"QItemAnalysis")>
		<cfoutput>
			<cfset DayRange = parm.reportDateTo - parm.reportDateFrom + 1>
			<cfset currProd = 0>
			<cfset totCount = 0>
			<cfset products = {}>
			<cfset productArray = []>
			<cfset block = {}>
			<cfset totals = {}>
			<cfloop query="QItemAnalysis">
				<cfset block = {}>
				<cfset block.groupTitle = groupTitle>
				<cfset block.catTitle = catTitle>
				<cfset block.prodTitle = prodTitle>
				<cfset block.siUnitSize = siUnitSize>
				
				<cfif !StructKeyExists(products,prodID)>
					<cfset StructInsert(products,prodID,block)>
					<cfset ArrayAppend(productArray,prodID)>
				</cfif>
				<cfset theProduct = StructFind(products,prodID)>
				<cfif !StructKeyExists(theProduct,hh)>
					<cfset StructInsert(theProduct,hh,recCount)>
				</cfif>
			</cfloop>
			
			<table class="tableList" border="1">
				<tr>
					<th colspan="29">From: #DateFormat(parm.reportDateFrom,"ddd dd-mmm-yy")# To: #DateFormat(parm.reportDateTo,"ddd dd-mmm-yy")# #DayRange# Days</th>
				</tr>
				<tr>
					<th>Group</th>
					<th>Category</th>
					<th>Product</th>
					<th>Size</th>
					<cfloop from="#startHour#" to="#endHour#" index="i">
						<th width="20" align="center">#i#</th>
					</cfloop>
					<th>Total</th>
					<th>Avg/<br />Week</th>
				</tr>
				
				<cfloop array="#productArray#" index="prodrec">
					<cfset theProduct = StructFind(products,prodrec)>
					<tr>
						<td>#theProduct.groupTitle#</td>
						<td>#theProduct.catTitle#</td>
						<td>#theProduct.prodTitle#</td>
						<td>#theProduct.siUnitSize#</td>
						<cfset lineTotal = 0>
						<cfloop from="#startHour#" to="#endHour#" index="i">
							<cfif StructKeyExists(theProduct,i)>
								<cfset theValue = StructFind(theProduct,i)>
								<cfset lineTotal += theValue>
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
						<cfif DayRange gt 6><cfset perWeek = 7><cfelse><cfset perWeek = 1></cfif>
						<cfset avg = (lineTotal / DayRange) * perWeek>
						<cfif avg lt 1><cfset avgText = "&lt;1"><cfelse><cfset avgText = DecimalFormat(avg)></cfif>
						<td align="center">#lineTotal#</td>
						<td>#avgText#</td>
					</tr>
				</cfloop>

				<cfset grandTotal = 0>
				<tr>
					<th colspan="4">Totals</th>
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
					<th></th>
				</tr>

			</table>
		</cfoutput>
	</cfif>
</body>
</html>
