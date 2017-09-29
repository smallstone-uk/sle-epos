<cftry>
	<cfobject component="#application.site.codePath#" name="ecfc">
	<cfset parm = {}>
	<cfset parm.datasource = ecfc.GetDataSource()>
	<cfset ecfc.LoadDeals(parm)>
	
	<cfoutput>
		<table>
			<tr>
				<th>Club</th>
				<th>Deal Title</th>
				<th>Deal Type</th>
				<th>Qty</th>
				<th>Amount</th>
				<th>Starts</th>
				<th>Ends</th>
				<th>Type</th>
			</tr>
		<cfloop array="#session.dealOrder#" index="key">
			<cfset deal = StructFind(session.dealdata,key)>
			<tr>
				<td>#deal.ercTitle#</td>
				<td align="left">#deal.edTitle#</td>
				<td>#deal.edDealType#</td>
				<td>#deal.edQty#</td>
				<td>&pound;#deal.edAmount#</td>
				<td>#LSDateFormat(deal.edStarts,"ddd dd-mmm-yy")#</td>
				<td>#LSDateFormat(deal.edEnds,"ddd dd-mmm-yy")#</td>
				<td>#deal.edType#</td>
			</tr>
		</cfloop>
		</table>
	</cfoutput>	

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="" expand="yes" format="html" 
		output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>
