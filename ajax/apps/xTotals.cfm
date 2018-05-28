<cftry>
	<cfif NOT StructKeyExists(session,"till")>
		Your session has timed out, please log-in again.
		<cfexit>
	</cfif>
	<cfoutput>
		<div id="xreading3" class="totalPanel">
			<div class="header">Till Header</div>
			<table class="tableList" border="1">
				<tr>
					<th>DESCRIPTION</th>
					<th width="70" align="right">DR</th>
					<th width="70" align="right">CR</th>
				</tr>
				<cfset drTotal = 0>
				<cfset crTotal = 0>
				<cfset loopcount = 0>
				<cfset keys = ListSort(StructKeyList(session.till.header,","),"text","ASC",",")>
				<cfloop list="#keys#" index="fld">
					<tr>
						<td>#fld#</td>
						<td align="right">
							<cfif session.till.header[fld] gt 0>
								<cfset drTotal += session.till.header[fld]>
								#DecimalFormat(session.till.header[fld])#
							</cfif>
						</td>
						<td align="right">
							<cfif session.till.header[fld] lt 0>
								<cfset crTotal -= session.till.header[fld]>
								#DecimalFormat(session.till.header[fld] * -1)#
							</cfif>
						</td>
					</tr>
				</cfloop>
				<tr>
					<td><strong>Totals</strong></td>
					<td align="right"><strong>#DecimalFormat(drTotal)#</strong></td>
					<td align="right"><strong>#DecimalFormat(crTotal)#</strong></td>
				</tr>
			</table>
		</div>
	
		<div id="xreading4" class="totalPanel">
			<div class="header">Till Totals</div>
			<table class="tableList" border="1">
				<tr>
					<th>DESCRIPTION</th>
					<th width="70" align="right">DR</th>
					<th width="70" align="right">CR</th>
				</tr>
				<cfset drTotal = 0>
				<cfset crTotal = 0>
				<cfset loopcount = 0>
				<cfset keys = ListSort(StructKeyList(session.till.total,","),"text","ASC",",")>
				<cfloop list="#keys#" index="fld">
					<tr>
						<td>#fld#</td>
						<td align="right">
							<cfif session.till.total[fld] gt 0>
								<cfset drTotal += session.till.total[fld]>
								#DecimalFormat(session.till.total[fld])#
							</cfif>
						</td>
						<td align="right">
							<cfif session.till.total[fld] lt 0>
								<cfset crTotal -= session.till.total[fld]>
								#DecimalFormat(session.till.total[fld] * -1)#
							</cfif>
						</td>
					</tr>
				</cfloop>
				<tr>
					<td><strong>Totals</strong></td>
					<td align="right"><strong>#DecimalFormat(drTotal)#</strong></td>
					<td align="right"><strong>#DecimalFormat(crTotal)#</strong></td>
				</tr>
			</table>
		</div>
		<div style="clear:both"></div>
	</cfoutput>
	
<cfcatch type="any">
	<cfset writeDumpToFile(cfcatch)>
</cfcatch>
</cftry>
