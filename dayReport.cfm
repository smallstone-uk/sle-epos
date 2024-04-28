<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset data = epos.LoadDayReport( LSDateFormat(Now(),"yyyy-mm-dd") )>

<link href="css/basicTables.css" rel="stylesheet" type="text/css">

<cfoutput>
	<br />
	<table class="table" border="1" width="512" style="margin-top:0;">
		<caption>Day Report</caption>
		<tr>
			<th align="left">Description</th>
			<th align="center" width="75">Qty</th>
			<th align="right" width="75">Total</th>
		</tr>
		<cfset salesTotal = 0>
		<cfset cashBackTotal = 0>
		<cfloop array="#data.sales#" index="item">
			<cfset salesTotal += val(item.netSum)>
			<tr>
				<td align="left">#item.pcatTitle#</td>
				<td align="center">#item.itemCount#</td>
				<td align="right">&pound;#DecimalFormat(item.netSum)#</td>
			</tr>
		</cfloop>
		<cfloop array="#data.receipts#" index="item">
			<cfset salesTotal += val(item.netSum)>
			<cfset cashBackTotal += val(item.cashback)>
			<tr>
				<td align="left"><strong>#item.account#</strong></td>
				<td align="center"><strong>#item.count#</strong></td>
				<td align="right"><strong>&pound;#DecimalFormat(item.netSum)#</strong></td>
			</tr>
		</cfloop>
		<cfif cashBackTotal GT 0>
			<tr>
				<td align="left"><strong>CASHBACK</strong></td>
				<td align="center"><strong></strong></td>
				<td align="right"><strong>&pound;#DecimalFormat(cashBackTotal)#</strong></td>
			</tr>
		</cfif>
		<tr>
			<th colspan="2" align="right">Total</th>
			<td align="right"><strong>&pound;#DecimalFormat(salesTotal)#</strong></td>
		</tr>
	</table>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="no">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>