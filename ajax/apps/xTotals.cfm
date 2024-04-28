<cftry>
	<cfif NOT StructKeyExists(session,"till")>
		Your session has timed out, please log-in again.
		<cfexit>
	</cfif>
	<cfscript>
		dayHeader = new App.DayHeader();
		today = dayHeader.today();
	</cfscript>
	
	<cfoutput>
		<cfif !StructIsEmpty(today)>
			<cfset noteTotal = 0>
			<cfset coinTotal = 0>
			<cfset poundArray = [50,20,10,5,2,1]>
			<div id="xreading2" class="totalPanel">
				<table>
					<tr>
						<th colspan="2">Cash In Drawer</th>
					</tr>
					<cfloop array="#poundArray#" index="denom">
						<cfset dataMOD = denom * 100>
						<cfset poundFld = "dhcid_#NumberFormat(dataMOD,'0000')#">
						<cfset value = StructFind(today,poundFld)>
						<cfif denom lt 5>
							<cfset coinTotal += value>
						<cfelse>
							<cfset noteTotal += value>
						</cfif>
						<tr>
							<td>&pound;#denom#</td>
							<td align="right">#value#</td>
						</tr>
					</cfloop>
					<cfloop array="#poundArray#" index="denom">
						<cfset penceFld = "dhcid_#NumberFormat(denom,'0000')#">
						<cfset value = StructFind(today,penceFld)>
						<cfset coinTotal += value>
						<tr>
							<td>#denom#p</td>
							<td align="right">#value#</td>
						</tr>
					</cfloop>
					<tr>
						<td>Coin Total</td>
						<td align="right">#DecimalFormat(coinTotal)#</td>
					</tr>
					<tr>
						<td>Note Total</td>
						<td align="right">#DecimalFormat(noteTotal)#</td>
					</tr>
					<tr>
						<td>Cash Total</td>
						<td align="right">#DecimalFormat(noteTotal + coinTotal)#</td>
					</tr>
				</table>
			</div>
		</cfif>
		<div id="xreading3" class="totalPanel">
			<table class="tableList" border="1">
				<tr>
					<th colspan="3">Till Header</th>
				</tr>
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
			<table class="tableList" border="1">
				<tr>
					<th colspan="3">Till Totals</th>
				</tr>
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
