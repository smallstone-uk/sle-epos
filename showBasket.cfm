<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Show Basket</title>
</head>
<cfobject component="code/epos" name="epos">
<cfset parms = epos.ValidateBasket(false)>
<cfif StructKeyExists(session.epos_frame,"basket")>
	<cfset balanceDue = 0>
	<cfset basket = session.epos_frame.basket>
</cfif>

<cfset epos.CalculateAccountTotals()>

<body>
<cftry>
	<cfoutput>
		<table>
			<cfloop array="#parms.requiredKeys#" index="section">#section#
				<cfset struccy = StructFind(basket, section)>
				<cfif NOT ListFind("account,payment",section,",")>
				<!---<cfif LCase(section) neq "payment">--->
                    <cfloop collection="#struccy#" item="key">
                        <cfset item = StructFind(struccy, key)>
                        <cfset checkQty = ( StructKeyExists(item, "qty") ) ? val(item.qty) : 1>
                        <cfset checkPrice = ( StructKeyExists(item, "price") ) ? val(item.price) : item.value>
                        <cfset item.lineTotal = val(checkQty) * val(checkPrice)>
                        <cfset balanceDue = balanceDue - item.lineTotal>
                        <cfset cashOnly = StructKeyExists(item,"cashonly") AND item.cashonly>
                        <tr class="basket_item" data-index="#item.index#" data-type="#section#">
                            <td align="left">#item.title#<cfif cashOnly> <strong>(Cash Only)</strong></cfif></td>
                            <td align="right">#checkQty#</td>
                            <td align="right">&pound;#DecimalFormat(-checkPrice)#</td>
                            <td align="right">&pound;#DecimalFormat(-item.lineTotal)#</td>
                        </tr>
                    </cfloop>
				<cfelseif section eq "payment">
					<cfloop collection="#struccy#" item="key">
                        <cfset item = StructFind(struccy, key)>
						<tr>
							<td>#item.title#</td>
							<td>#item.value#</td>
						</tr>
					</cfloop>
                </cfif>
			</cfloop>
            <tr><td colspan="3">Sub Total</td><td align="right">&pound;#DecimalFormat(balanceDue)#</td></tr>
            <cfloop collection="#basket.payment#" item="key">
				<cfset item = StructFind(basket.payment, key)>
				<cfset balanceDue = balanceDue - item.value>
				<cfif UCase(item.title) neq "PRIZE">
					<tr class="basket_payment" data-index="#LCase(item.title)#" data-type="payment" style="font-size: 18px;">
						<th align="left" colspan="3">#item.title#</td>
						<td align="right" style="font-weight:bold;">&pound;#DecimalFormat(item.value)#</td>
					</tr>
				<cfelse>
					<cfset containsPrize = true>
				</cfif>
			</cfloop>
            <tr><td colspan="3"><cfif balanceDue lt 0>Change Due<cfelse>Balance Due</cfif></td><td align="right">&pound;#DecimalFormat(balanceDue)#</td></tr>
		</table>
	</cfoutput>
<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
	output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>

</body>
</html>
<cfdump var="#session.epos_frame#" label="session.epos_frame" expand="yes">
<cfdump var="#session#" label="session" expand="no">