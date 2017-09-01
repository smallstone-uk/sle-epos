<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>Product Deals</title>
</head>

<body>
<cfquery name="QProductDeals" datasource="#application.site.datasource1#">
	SELECT edID,edTitle,edStarts,edEnds,edDealType,ediMinQty,ediMaxQty,prodID,prodTitle,prodOurPrice,siOurPrice
	FROM tblEPOS_Deals
	INNER JOIN tblEPOS_DealItems ON ediParent=edID
	INNER JOIN tblProducts ON ediProduct=prodID
	LEFT JOIN tblStockItem ON prodID = siProduct
	AND tblStockItem.siID = (
		SELECT MAX( siID )
		FROM tblStockItem
		WHERE prodID = siProduct )
	WHERE `edEnds` > '2016-09-01'
	AND `edStatus` = 'Active'
	ORDER BY edID,prodTitle
</cfquery>

<table>
<cfoutput query="QProductDeals">
	<tr>
		<td>#edID#</td>
		<td>#edTitle#</td>
		<td>#LSDateFormat(edStarts)#</td>
		<td>#LSDateFormat(edEnds)#</td>
		<td>#edDealType#</td>
		<td>#ediMinQty#</td>
		<td>#ediMaxQty#</td>
		<td>#prodID#</td>
		<td>#prodTitle#</td>
		<td>#prodOurPrice#</td>
		<td>#siOurPrice#</td>
	</tr>
</cfoutput>
</table>
</body>
</html>