<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset deals = epos.LoadAllDeals(parm)>

<cfoutput>
	<table width="100%" border="1">
		<tr>
			<th>ID</th>
			<th>Title</th>
			<th>Starts</th>
			<th>Ends</th>
			<th>Type</th>
			<th>Amount</th>
			<th>Qty</th>
			<th>Status</th>
		</tr>
		<cfloop array="#deals#" index="item">
			<tr>
				<td>#item.header.edID#</td>
				<td>#item.header.edTitle#</td>
				<td>#item.header.edStarts#</td>
				<td>#item.header.edEnds#</td>
				<td>#item.header.edType#</td>
				<td>#item.header.edAmount#</td>
				<td>#item.header.edQty#</td>
				<td>#item.header.edStatus#</td>
			</tr>
			<cfloop array="#item.items#" index="row">
				<tr>
					<td>#row.#</td>
				</tr>
			</cfloop>
		</cfloop>
	</table>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>