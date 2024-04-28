<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>Test</title>
	<style>
		.red {color:#FF0000;}
		.blue {color:#00F;}
		.header {background-color:#CCCCCC;}
		.tranheader {background-color:#eee;}
		.myTable {
			font-family:Arial, Helvetica, sans-serif;
			border-spacing: 0px;
			border-collapse: collapse;
			border: 1px solid #CCC;
			font-size: 14px;
		}
		.myTable th {padding: 5px; background:#eee; border-color: #ccc;}
		.myTable td {padding: 5px; border-color: #ccc;}
	</style>
</head>

<body>
<cfobject component="#application.site.codePath#" name="ecfc">

<cfoutput>
	<cfif StructIsEmpty(session.basket.deals)>
		Please add some items to the basket.
		<cfexit>
	</cfif>
<!---	<cfset ecfc.ProcessDeals()>
	<cfexit>
--->	
	
	<cfset loc = {}>
	<cfloop collection="#session.basket.shopItems#" item="loc.prodKey">
		<cfset loc.item = StructFind(session.basket.shopItems,loc.prodKey)>
		<cfset loc.item.retail = loc.item.qty * loc.item.unitPrice>
		<cfif loc.item.dealID gt 0>
			<cfset loc.dealData = StructFind(session.dealData,loc.item.dealID)>
			<cfset loc.dealRec = StructFind(session.basket.deals,loc.item.dealID)>
			<cfset ArraySort(loc.dealRec.prices,"text","ASC")>	<!--- change to DESC to optimise for customer --->
			<cfset loc.dealRec.retail = 0>
			<cfset loc.dealRec.netTotal = 0>
			<cfset loc.dealRec.dealTotal = 0>
			<cfset loc.dealRec.totalCharge = 0>
			<cfset loc.dealRec.savingGross = 0>
			<cfset loc.dealRec.groupRetail = 0>
			<cfset loc.item.dealQty = 0>
			<cfset loc.dealRec.VAT = {}>
			<cfset loc.dealRec.itemCount = 0>
			<table border="1" width="800" class="myTable">
				<tr>
					<th align="center">##</th>
					<th>Deal</th>
					<th align="right">price</th>
					<th align="right">VAT</th>
					<th align="right">net</th>
					<th align="right">retail</th>
					<th align="right">groupRetail</th>
					<th align="center">dealCount</th>
					<th align="right">dealTotal</th>
					<th align="right">totalCharge</th>
					<th align="right">saving</th>
				</tr>
				<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
					<cfset loc.dealRec.itemCount++>
					<cfset loc.item.dealTitle = "">
					<cfset loc.price = ListFirst(loc.priceKey," ")>
					<cfset loc.prodID = ListLast(loc.priceKey," ")>
					<cfset loc.item.style = "blue">
					<cfset loc.dealRec.retail += loc.price>
					<cfset loc.net = loc.price / (1 + (loc.item.vrate /100))>
					<cfset loc.dealRec.netTotal += loc.net>
					<cfif NOT StructKeyExists(loc.dealRec.VAT,loc.item.vrate)>
						<cfset StructInsert(loc.dealRec.VAT,loc.item.vrate,loc.net)>
					<cfelse>
						<cfset loc.vatRec = StructFind(loc.dealRec.VAT,loc.item.vrate)>
						<cfset StructUpdate(loc.dealRec.VAT,loc.item.vrate,loc.vatRec + loc.net)>
					</cfif>
					
					<cfset loc.dealRec.groupRetail += loc.price>
					<cfif loc.dealData.edEnds gt Now()>
						<cfif loc.dealRec.itemCount MOD loc.dealData.edQty eq 0>
							<cfset loc.item.dealQty++>
							<cfset loc.item.style = "red">
							<cfswitch expression="#loc.dealData.edDealType#">
								<cfcase value="anyfor">
									<cfset loc.dealRec.dealTotal = loc.item.dealQty * loc.dealData.edAmount>
									<cfset loc.item.dealTitle = "#loc.dealData.edTitle# &pound;#DecimalFormat(loc.dealData.edAmount)#">
								</cfcase>
								<cfcase value="twofor">
									<cfset loc.item.dealQty = int(loc.dealRec.itemCount / 2)>
									<cfset loc.dealRec.remQty = loc.dealRec.itemCount mod 2>
									<cfset loc.dealRec.dealTotal = loc.item.dealQty * loc.dealData.edAmount + (loc.dealRec.remQty * loc.price)>
									<cfset loc.item.dealTitle = "#loc.dealData.edTitle# &pound;#DecimalFormat(loc.dealData.edAmount)#">
								</cfcase>
								<cfcase value="bogof">
									<cfset loc.item.dealQty = int(loc.dealRec.itemCount / 2)>
									<cfset loc.dealRec.remQty = loc.dealRec.itemCount mod 2>
									<cfset loc.dealRec.dealTotal = (loc.item.dealQty * loc.price) + (loc.dealRec.remQty * loc.price)>
									<cfset loc.item.dealTitle = loc.dealData.edTitle>
								</cfcase>
							</cfswitch>
							<cfset loc.dealRec.groupRetail = 0>
						</cfif>
					</cfif>
					<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
					<cfset loc.dealRec.savingGross = loc.dealRec.totalCharge - loc.dealRec.retail>
					<tr class="#loc.item.style#">
						<td align="center">#loc.dealRec.itemCount#</td>
						<td>#loc.item.dealTitle#</td>
						<td align="right">#DecimalFormat(loc.price)#</td>
						<td align="right">#DecimalFormat(loc.item.vrate)#%</td>
						<td align="right">#DecimalFormat(loc.net)#</td>
						<td align="right">#DecimalFormat(loc.dealRec.retail)#</td>
						<td align="right">#DecimalFormat(loc.dealRec.groupRetail)#</td>
						<td align="center">#loc.item.dealQty#</td>
						<td align="right">#DecimalFormat(loc.dealRec.dealTotal)#</td>
						<td align="right">#DecimalFormat(loc.dealRec.totalCharge)#</td>
						<td align="right">#DecimalFormat(loc.dealRec.savingGross)#</td>
					</tr>
				</cfloop>
				<cfset loc.dealRec.savingNet = 0>
				<cfset loc.dealRec.savingVAT = 0>
				<cfloop collection="#loc.dealRec.VAT#" item="loc.vatKey">
					<cfset loc.netAmnt = StructFind(loc.dealRec.VAT,loc.vatKey)>
					<cfset loc.prop = loc.netAmnt / loc.dealRec.netTotal>
					<cfset loc.dealRec.savingNet += (loc.dealRec.savingGross * loc.prop) / (1 + (loc.vatKey /100))>
				</cfloop>
				<cfset loc.dealRec.savingVAT += loc.dealRec.savingGross - loc.dealRec.savingNet>
			</table>
			<!---<cfdump var="#loc#" label="#loc.item.dealID#" expand="no">--->
		</cfif>
	</cfloop>
</cfoutput>
</body>
</html>