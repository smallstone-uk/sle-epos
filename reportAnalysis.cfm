<!DOCTYPE html PUBLIC "-//W3C//Dth XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>Report Analysis</title>
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<script src="js/jquery-1.11.1.min.js"></script>
</head>
<cfobject component="#application.site.codePath#" name="ecfc">
<cfparam name="reportDateFrom" default="#Now()#">
<cfparam name="reportDateTo" default="#Now()#">
<cfparam name="reportHourFrom" default="0">
<cfparam name="reportMinFrom" default="0">
<cfparam name="reportHourTo" default="23">
<cfparam name="reportMinTo" default="59">
<cfparam name="reportMode" default="">
<cfset startHour = 6>
<cfset endHour = 20>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset dates = ecfc.GetDates(parm)>

<cfif StructKeyExists(form,"reportDateFrom") AND len(form.reportDateFrom) gt 0>
	<cfset parm.reportDateFrom = form.reportDateFrom>
	<cfset parm.reportDateTo = form.reportDateTo>
	<cfif len(form.reportDateTo) IS 0><cfset parm.reportDateTo = form.reportDateFrom></cfif>
	<cfset parm.reportHourFrom = form.reportHourFrom>
	<cfset parm.reportMinFrom = form.reportMinFrom>
	<cfset parm.reportHourTo = form.reportHourTo>
	<cfset parm.reportMinTo = form.reportMinTo>
	<cfquery name="QItemAnalysis" datasource="#parm.datasource#" result="QItemAnalysisResult">
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
		AND HOUR(ehTimeStamp) >= '#parm.reportHourFrom#'
		AND HOUR(ehTimeStamp) <= '#parm.reportHourTo#'
		AND MINUTE(ehTimeStamp) >= '#parm.reportMinFrom#'
		AND MINUTE(ehTimeStamp) <= '#parm.reportMinTo#'
		AND eiClass LIKE 'sale'
		<cfif len(reportMode)>AND ehMode LIKE '#reportMode#'</cfif>
        GROUP BY groupTitle, catTitle, prodTitle, siUnitSize, eiNet, hh
	</cfquery>
	<!---<cfdump var="#QItemAnalysis#" label="QItemAnalysis" expand="false">--->
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
				<select name="reportMode" id="reportMode">
					<option value="reg" <cfif reportMode eq "reg"> selected</cfif>>Reg Mode</option>
					<option value="rfd" <cfif reportMode eq "rfd"> selected</cfif>>Refund Mode</option>
					<option value="wst" <cfif reportMode eq "wst"> selected</cfif>>Waste Mode</option>
				</select>
				<br />
				Time From:
				<select name="reportHourFrom" id="reportHourFrom">
					<option value="">Select hour...</option>
					<cfloop from="0" to="23" index="item">
						<option value="#item#" <cfif reportHourFrom eq item> selected</cfif>>#NumberFormat(item,"00")#</option>
					</cfloop>
				</select>
				<select name="reportMinFrom" id="reportMinFrom">
					<option value="">Select minute...</option>
					<cfloop from="0" to="59" index="item">
						<option value="#item#" <cfif reportMinFrom eq item> selected</cfif>>#NumberFormat(item,"00")#</option>
					</cfloop>
				</select>
				Time To:
				<select name="reportHourTo" id="reportHourTo">
					<option value="">Select hour...</option>
					<cfloop from="0" to="23" index="item">
						<option value="#item#" <cfif reportHourTo eq item> selected</cfif>>#NumberFormat(item,"00")#</option>
					</cfloop>
				</select>
				<select name="reportMinTo" id="reportMinTo">
					<option value="">Select minute...</option>
					<cfloop from="0" to="59" index="item">
						<option value="#item#" <cfif reportMinTo eq item> selected</cfif>>#NumberFormat(item,"00")#</option>
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
			<cfset totValue = 0>
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
				<cfset block.net = -eiNet>
				<cfset block.gross = -(eiNet + eiVAT)>
				
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
					<th>Price</th>
					<cfloop from="#startHour#" to="#endHour#" index="i">
						<th width="20" align="center">#i#</th>
					</cfloop>
					<th>Total<br />Qty</th>
					<th>Avg/<br />Week</th>
					<th>Total</th>
				</tr>
				
				<cfloop array="#productArray#" index="prodrec">
					<cfset theProduct = StructFind(products,prodrec)>
					<tr>
						<td>#theProduct.groupTitle#</td>
						<td>#theProduct.catTitle#</td>
						<td><a href="http://tweb.sle-admin.co.uk/productStock6.cfm?product=#prodrec#" target="_blank">#theProduct.prodTitle#</a></td>
						<td>#theProduct.siUnitSize#</td>
						<td align="right">&pound;#DecimalFormat(theProduct.gross)#</td>
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
						<cfset lineValue = lineTotal * val(theProduct.gross)>
						<cfset totValue += lineValue>
						<td align="center">#lineTotal#</td>
						<td>#avgText#</td>
						<td align="right">&pound;#DecimalFormat(lineValue)#</td>
					</tr>
				</cfloop>

				<cfset grandTotal = 0>
				<tr>
					<th colspan="5">Totals</th>
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
					<th>&pound;#DecimalFormat(totValue)#</th>
				</tr>
				<tr>
					<th colspan="5">Average</th>
					<cfloop from="#startHour#" to="#endHour#" index="i">
						<cfif StructKeyExists(totals,i)>
							<cfset hourTotal = StructFind(totals,i)>
							<th>#DecimalFormat(hourTotal / dayRange)#</th>
						<cfelse>
							<th></th>
						</cfif>
					</cfloop>
					<th></th>
					<th></th>
					<th></th>
				</tr>
				<tr>
					<th colspan="21" align="right">Average per day </th>
					<th align="right">&pound;#DecimalFormat(totValue / dayRange)#</th>
				</tr>
			</table>
		</cfoutput>
	</cfif>
</body>
</html>
