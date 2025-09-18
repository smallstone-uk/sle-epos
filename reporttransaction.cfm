<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>Sales Transaction</title>
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
</head>
<cfparam name="tranID" default="533193">
<cfquery name="QTran" datasource="#application.site.datasource1#">
	SELECT tblEPOS_Items.*,ehMode, empFirstName,
	IF (eiClass='DISC',
		(SELECT edTitle FROM tblEPOS_Deals WHERE edID=eiDealID),
		IF (eiType='MEDIA',
			(SELECT pubTitle FROM tblPublication WHERE pubID=eiPubID),
			IF (eiClass='pay',
				(SELECT eaTitle FROM tblEPOS_Account WHERE eaID=eiPayID),
					(SELECT prodTitle FROM tblProducts WHERE prodID=eiProdID)
			)
		)
	) title,
	tblProducts.prodCatID, tblproductcats.pcatTitle
	FROM tblEPOS_Items
	INNER JOIN tblEPOS_Header ON ehID = eiParent
	INNER JOIN tblemployee ON empID = ehEmployee
	INNER JOIN tblProducts ON prodID=eiProdID
	INNER JOIN tblproductcats ON prodCatID=pcatID
	WHERE eiParent=#val(tranID)#
</cfquery>
<cfif QTran.recordcount eq 0>
	No record found.
	<cfexit>
</cfif>
<body>
	<table class="tableList">
	<cfoutput>
		<cfloop query="QTran">
			<cfif currentRow eq 1>
				<tr>
					<td colspan="10">
						<table width="100%" class="tableList">
							<th align="right">Transaction ID: </th><th align="left">#eiParent#</th>
							<th align="right">Mode: </th><th align="left">#ehMode#</th>
							<th align="right">Served By: </th><th align="left">#empFirstName#</th>
							<th align="right">Date: </th><th align="left">#DateFormat(eiTimeStamp,'ddd dd-mmm-yy')# #TimeFormat(eiTimeStamp,'HH:MM:SS')#</th>
						</table>
					</td>
				</tr>
				<tr>
					<th>ID</th>
					<th>Class</th>
					<th>Type</th>
					<th>Pay Type</th>
					<th>Qty</th>
					<th>Category</th>
					<th>ProdID</th>
					<th>Description</th>
					<th>DR</th>
					<th>CR</th>
				</tr>
				<cfset totNet = 0>
				<cfset totVAT = 0>
				<cfset totCR = 0>
				<cfset totDR = 0>
				<cfset totGross = 0>
			</cfif>
			<cfset lineGross = eiNet + eiVAT>
			<cfif eiClass eq 'sale'>
				<cfset totNet -= eiNet>
				<cfset totVAT -= eiVAT>
			</cfif>
			<cfset totGross += lineGross>
			<tr>
				<td>#eiID#</td>
				<td>#eiClass#</td>
				<td>#eiType#</td>
				<td>#eiPayType#</td>
				<td>#eiQty#</td>
				<td>#pcatTitle#</td>
				
				<td>
					<cfif eiType eq 'shop'>
						<a href="#application.site.url1#productStock6.cfm?product=#eiProdID#" target="_new">#eiProdID#</a>
					</cfif>
				</td>
				<td>#title#</td>
				<td align="right"><cfif lineGross gt 0><cfset totDR += eiNet + eiVAT>#DecimalFormat(eiNet + eiVAT)#</cfif></td>
				<td align="right"><cfif lineGross lt 0><cfset totCR -= eiNet + eiVAT> #DecimalFormat(-eiNet + -eiVAT)#</cfif></td>
			</tr>
		</cfloop>
		<tr>
			<th colspan="2">Net: #DecimalFormat(totNet)#</th>
			<th colspan="2">VAT: #DecimalFormat(totVAT)#</th>
			<th colspan="4"></th>
			<th>#DecimalFormat(totDR)#</th>
			<th>#DecimalFormat(totCR)#</th>
		</tr>
		<cfif abs(totDR - totCR) gt 0.01>
			<tr>
				<th colspan="9" align="right">Error: </th>
				<th>#DecimalFormat(totDR - totCR)#</th>
			</tr>
		</cfif>
	</cfoutput>
	</table>
</body>
</html>