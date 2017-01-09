<cfoutput>
#Chr(163)#
#ASC("£")#
</cfoutput>
<!---<script src="../scripts/jquery-1.11.1.min.js"></script>
<script src="../scripts/jquery-ui.js"></script>

<cftry>
<cfsetting showdebugoutput="no">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfif StructKeyExists(url, "mode")>
	<cfset parm.tillMode = url.mode>
<cfelse>
	<cfset parm.tillMode = "reg">
</cfif>

<!---SET SIGN--->
<cfset sign = (2 * int(parm.tillMode eq "reg")) - 1>

<!---<cfoutput>Sign: #sign#<br /></cfoutput>--->

<cffunction name="RandID" access="public" returntype="numeric">
	<cfreturn RandRange(102030, 908070, 'SHA1PRNG')>
</cffunction>

<!---BASKET FRAME--->
<cfset basket = {products = {}, publications = {}, paypoint = {}, deals = {}, payments = {}}>

<!---ADD PRODUCTS--->
<cfset StructInsert(basket.products, "789456", {prod = 789456, title = "Kinder Snack Bar", price = -0.30, qty = 6})>
<cfset StructInsert(basket.products, "456789", {prod = 456789, title = "Pepsi Can", price = -0.49, qty = 3})>
<cfset StructInsert(basket.products, "123456", {prod = 123456, title = "Sandwich", price = -2.00, qty = 7})>

<!---ADD PUBLICATIONS--->
<cfset StructInsert(basket.publications, "#RandID()#-0200", {pub = RandID(), title = "Times", price = -2.00, qty = 1})>
<cfset StructInsert(basket.publications, "#RandID()#-0200", {pub = RandID(), title = "Daily Mail", price = -2.00, qty = 1})>
<cfset StructInsert(basket.publications, "#RandID()#-0560", {pub = RandID(), title = "News Account", price = -5.60, qty = 1})>

<!---ADD PAYPOINT SERVICES--->
<cfset StructInsert(basket.paypoint, "ElectricKey-1000", {title = "Electric Key", price = -10.00, qty = 1})>
<cfset StructInsert(basket.paypoint, "PhoneTopup-1000", {title = "O2 Topup", price = -10.00, qty = 1})>

<!---ADD DEALS--->
<cfset StructInsert(basket.deals, "123456", {title = "3 Sandwiches for £5", price = -5.00, targetqty = 3, prod = 123456})>
<cfset StructInsert(basket.deals, "456789", {title = "3 Pepsi Cans for £1", price = -1.00, targetqty = 3, prod = 456789})>

<!---SET THE BALANCE DUE--->
<cfset result.balanceDue = 0>

<!---CALCULATE THE LINE TOTAL & BALANCE--->
<cfloop collection="#basket.products#" item="key">
	<cfset item = StructFind(basket.products, key)>
	<cfset item.price = item.price * sign>
	<cfset item.linetotal = (item.price * item.qty)>
	<cfset result.balanceDue += item.linetotal>
</cfloop>

<cfloop collection="#basket.publications#" item="key">
	<cfset item = StructFind(basket.publications, key)>
	<cfset item.price = item.price * sign>
	<cfset item.linetotal = (item.price * item.qty)>
	<cfset result.balanceDue += item.linetotal>
</cfloop>

<cfloop collection="#basket.paypoint#" item="key">
	<cfset item = StructFind(basket.paypoint, key)>
	<cfset item.price = item.price * sign>
	<cfset item.linetotal = (item.price * item.qty)>
	<cfset result.balanceDue += item.linetotal>
</cfloop>

<cfset result.youSaved = 0>

<cfloop collection="#basket.deals#" item="key">
	<cfset deal = StructFind(basket.deals, key)>
	<cfset product = StructFind(basket.products, deal.prod)>
	<cfset product.eligibleQty = int(product.qty / deal.targetQty)>
	<cfset product.saving = -((deal.targetQty * product.price) - deal.price * sign)>
	<cfset product.dealTitle = deal.title>
	<cfset product.grossSaving = product.eligibleQty * product.saving>
	<cfset result.balanceDue += product.grossSaving>
	<cfset result.youSaved += product.grossSaving>
</cfloop>

<!---ADD PAYMENTS--->
<cfif parm.tillMode eq "reg">
	<cfset StructInsert(basket.payments, "CARD", {title = "CARD", price = 48.30})>
	<cfset StructInsert(basket.payments, "CHQ", {title = "CHEQUE", price = 5.60})>
</cfif>

<cfset StructInsert(basket.payments, "VCH", {title = "VOUCHER", price = 0.50})>

<cfset result.totalGiven = 0>
<cfset result.balanceDue = result.balanceDue>

<cfloop collection="#basket.payments#" item="key">
	<cfset item = StructFind(basket.payments, key)>
	<cfset result.totalGiven += item.price>
</cfloop>

<cfset result.changeDue = (result.balanceDue + result.totalGiven) * sign>

<style>
	body {font-family:"Courier New", Courier, monospace;}
	table {border-spacing: 0px;border-collapse: collapse;border: 1px solid #BBB;font-size: 16px;font-weight: normal;}
	table th {padding: 6px 10px;color: #000;font-weight: bold;text-transform:uppercase;}
	table td {padding: 6px 10px;border-color: #BBB;color: #000;text-transform:uppercase;}
	table[border="0"] {border:none;}
</style>

<cfoutput>
	<cfdump var="#basket#" label="basket" expand="no">
	<cfdump var="#result#" label="result" expand="no">
	<div style="margin:20px 0;">
		<table width="50%" border="0" style="margin:0 auto;">
			<tr>
				<th colspan="4">
					<img src="logo.png" width="100%" />
				</th>
			</tr>
			<tr>
				<td colspan="2" align="center">#application.company.webmaster#</td>
				<td colspan="2" align="center">#application.company.telephone#</td>
			</tr>
			<cfif parm.tillMode eq "rfd">
				<tr><td colspan="4" align="center" style="font-weight:bold;">Refund</td></tr>
			</cfif>
			<tr>
				<th colspan="4" align="right">#RandID()#</th>
			</tr>
			<tr>
				<th colspan="2" align="left">#LSDateFormat(Now(), "dd/mm/yyyy")#</th>
				<th colspan="2" align="right">#LSTimeFormat(Now(), "HH:mm")#</th>
			</tr>
			<tr>
				<th width="25" align="right">Qty</th>
				<th align="left">Product</th>
				<th width="50" align="right">Price</th>
				<th width="75" align="right">Total</th>
			</tr>
			<cfloop collection="#basket.products#" item="key">
				<cfset item = StructFind(basket.products, key)>
				<tr>
					<td align="right">#item.qty#</td>
					<td align="left">#item.title#</td>
					<td align="right">#DecimalFormat(-item.price)#</td>
					<td align="right">#DecimalFormat(-item.linetotal)#</td>
				</tr>
				<cfif StructKeyExists(item, "dealTitle")>
					<tr>
						<td align="right">#item.eligibleQty#</td>
						<td align="left">&nbsp;&nbsp;#item.dealTitle#</td>
						<td align="right">#DecimalFormat(-item.saving)#</td>
						<td align="right">#DecimalFormat(-item.grossSaving)#</td>
					</tr>
				</cfif>
			</cfloop>
			<cfloop collection="#basket.publications#" item="key">
				<cfset item = StructFind(basket.publications, key)>
				<tr>
					<td align="right">#item.qty#</td>
					<td align="left">#item.title#</td>
					<td align="right">#DecimalFormat(-item.price)#</td>
					<td align="right">#DecimalFormat(-item.linetotal)#</td>
				</tr>
			</cfloop>
			<cfloop collection="#basket.paypoint#" item="key">
				<cfset item = StructFind(basket.paypoint, key)>
				<tr>
					<td align="right">#item.qty#</td>
					<td align="left">#item.title#</td>
					<td align="right">#DecimalFormat(-item.price)#</td>
					<td align="right">#DecimalFormat(-item.linetotal)#</td>
				</tr>
			</cfloop>
			<cfif parm.tillMode eq "reg">
				<tr>
					<th align="left" colspan="3">Balance Due</th>
					<td align="right" style="font-weight:bold;">#DecimalFormat(-result.balanceDue)#</td>
				</tr>
				<cfloop collection="#basket.payments#" item="key">
					<cfset item = StructFind(basket.payments, key)>
					<tr>
						<th align="left" colspan="3">#item.title#</td>
						<td align="right" style="font-weight:bold;">#DecimalFormat(item.price)#</td>
					</tr>
				</cfloop>
				<tr>
					<th align="left" colspan="3">
						<cfif result.changeDue lt 0>
							Balance Now Due
						<cfelse>
							Change Due
						</cfif>
					</th>
					<td align="right" style="font-weight:bold;">#DecimalFormat(result.changeDue)#</td>
				</tr>
				<cfif result.youSaved gt 0>
					<tr>
						<th align="center" colspan="4">You have saved &pound;#DecimalFormat(result.youSaved)# today</th>
					</tr>
				</cfif>
			<cfelse>
				<tr>
					<th align="left" colspan="3">Refund Due</th>
					<td align="right" style="font-weight:bold;">#DecimalFormat(result.balanceDue)#</td>
				</tr>
			</cfif>
		</table>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>--->