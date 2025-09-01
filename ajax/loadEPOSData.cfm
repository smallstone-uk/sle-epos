
<cfobject component="code/reports" name="report">

<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.form = form>

<cfif form.srchReport eq 1>
	<cfset rpt = report.LoadSalesData(parm)>
	<cfif !StructKeyExists(rpt,"keys")>
		<cfoutput>#rpt.msg#</cfoutput>
		<!---<cfdump var="#rpt#" label="rpt" expand="false">--->
		<cfabort>
	</cfif>
	<cfif StructKeyExists(form,"srchDateFrom")>
		<!---<cfdump var="#rpt#" label="rpt" expand="false">--->
		<cfset colCount = srchHourTo - srchHourFrom + 1>
		<cfoutput>
		<table class="tableList" border="1">
			<tr>
				<th colspan="#colCount + 5#">Shop Analysis by Hour From: #srchDateFrom# &nbsp; To: #srchDateTo# &nbsp; #srchHourFrom#:00 - #srchHourTo#:00 &nbsp; (#colCount# hours)</th>
			</tr>
			<tr>
				<th align="left">Class</th>
				<th align="left">Group</th>
				<th align="left">Title</th>
				<th align="left"></th>
				<cfloop from="#srchHourFrom#" to="#srchHourTo#" index="i">
					<th align="right" width="60">#i#</th>
				</cfloop>
				<th align="right" width="60">Total</th>
			</tr>
			<cfset class = "">
			<cfloop list="#rpt.keys#" index="key" delimiters=",">
				<cfset item = StructFind(rpt.data,key)>
				<cfif item.eiClass neq class AND class neq "">
					<cfset classTotal = StructFind(rpt.totals,class)>
					<tr>
						<th colspan="4">#class# totals</th>
						<cfset rowClassTotal = 0>
						<cfloop from="#srchHourFrom#" to="#srchHourTo#" index="i">
							<cfset ii = NumberFormat(i,'00')>
							<cfset slot = StructFind(classTotal,ii)>
							<cfset slotTotal = -(slot.net + slot.VAT)>
							<cfset rowClassTotal += slotTotal>
							<th align="right">#report.formatNum(slotTotal)#</th>
						</cfloop>
						<th align="right">#report.formatNum(rowClassTotal)#</th>
					</tr>
					<cfif class eq "sale">
					<tr>
						<th colspan="4">Trade Value</th>
						<cfset rowClassTotal = 0>
						<cfloop from="#srchHourFrom#" to="#srchHourTo#" index="i">
							<cfset ii = NumberFormat(i,'00')>
							<cfset total = StructFind(classTotal,ii)>
							<cfset rowClassTotal += total.trade>
							<th align="right">#report.formatNum(total.trade)#</th>
						</cfloop>
						<th align="right">#report.formatNum(rowClassTotal)#</th>
					</tr>
					<tr>
						<th colspan="4">Profit</th>
						<cfset rowClassTotal = 0>
						<cfloop from="#srchHourFrom#" to="#srchHourTo#" index="i">
							<cfset ii = NumberFormat(i,'00')>
							<cfset total = StructFind(classTotal,ii)>
							<cfset profit = -(total.net + total.VAT + total.trade)>
							<cfset rowClassTotal += profit>
							<th align="right">#report.formatNum(profit)#</th>
						</cfloop>
						<th align="right">#report.formatNum(rowClassTotal)#</th>
					</tr>
					</cfif>
					<tr>
						<th colspan="4">Item Count</th>
						<cfset rowClassTotal = 0>
						<cfloop from="#srchHourFrom#" to="#srchHourTo#" index="i">
							<cfset ii = NumberFormat(i,'00')>
							<cfset colTotal = 0>
							<cfset slot = StructFind(rpt.totals,class)>
							<cfset total = StructFind(slot,ii)>
							<cfset colTotal += total.qty>
							<cfset rowClassTotal += total.qty>
							<cfif colTotal lt 0.001><cfset colTotal = 0></cfif>
							<th align="right">#report.formatNum(colTotal,',')#</th>
						</cfloop>
						<th align="right">#report.formatNum(rowClassTotal,',')#</th>
					</tr>
				</cfif>
				<cfset class = item.eiClass>
				<tr>
					<td>#item.eiClass#</td>
					<td>#item.pgNomGroup#</td>
					<td>#item.pgTitle#</td>
					<td class="smallTitle">
						<table class="smallTable" border="0">
							<tr><td class="qty">Qty</td></tr>
							<tr><td>Net</td></tr>
							<tr><td>VAT</td></tr>
							<tr><td class="trade">Trade</td></tr>								
						</table>
					</td>
					<cfloop from="#srchHourFrom#" to="#srchHourTo#" index="i">
						<cfset ii = NumberFormat(i,'00')>
						<cfset slot = StructFind(item.slots,ii)>
						<td align="right">
							<table class="smallTable" border="0">
								<tr><td align="right" class="qty">#report.formatNum(slot.qty,',')#</td></tr>
								<tr><td align="right">#report.formatNum(slot.net)#</td></tr>
								<tr><td align="right">#report.formatNum(slot.VAT)#</td></tr>
								<tr><td align="right" class="trade">#report.formatNum(slot.trade)#</td></tr>								
							</table>
						</td>
					</cfloop>
					<td align="right">
						<table class="smallTable" border="0">
							<tr><td align="right" class="qty">#report.formatNum(item.rowTotalQty,',')#</td></tr>
							<tr><td align="right">#report.formatNum(item.rowTotalNet)#</td></tr>
							<tr><td align="right">#report.formatNum(item.rowTotalVAT)#</td></tr>
							<tr><td align="right" class="trade">#report.formatNum(item.rowTotalTrade)#</td></tr>								
						</table>
					</td>
				</tr>
			</cfloop>
			<cfif StructKeyExists(rpt.totals,class)>
				<cfset classTotal = StructFind(rpt.totals,class)>
				<tr>
					<th colspan="4">#class# totals</th>
					<cfset rowClassTotal = 0>
					<cfloop from="#srchHourFrom#" to="#srchHourTo#" index="i">
						<cfset ii = NumberFormat(i,'00')>
						<cfset total = StructFind(classTotal,ii)>
						<cfset rowClassTotal += (total.net + total.VAT)>
						<th align="right">#report.formatNum(total.net + total.VAT)#</th>
					</cfloop>
					<th align="right">#report.formatNum(rowClassTotal)#</th>
				</tr>
				<tr>
					<th colspan="4">Check Totals</th>
					<cfset rowClassTotal = 0>
					<cfloop from="#srchHourFrom#" to="#srchHourTo#" index="i">
						<cfset ii = NumberFormat(i,'00')>
						<cfset colTotal = 0>
						<cfloop list="sale,item,pay,supp" index="itemClass" delimiters=",">
							<cfset slot = StructFind(rpt.totals,itemClass)>
							<cfset total = StructFind(slot,ii)>
							<cfset colTotal += (total.net + total.VAT)>
							<cfset rowClassTotal += (total.net + total.VAT)>
						</cfloop>
						<cfif colTotal lt 0.001><cfset colTotal = 0></cfif>
						<th align="right">#DecimalFormat(colTotal)#</th>
					</cfloop>
					<th align="right">#DecimalFormat(rowClassTotal)#</th>
				</tr>
			<cfelse>
				<tr>
					<td colspan="8">No data found to display.</td>
				</tr>
			</cfif>
		</table>
		</cfoutput>
	</cfif>
<cfelseif form.srchReport eq 2>
	<cfset rpt = report.LoadEPOSTransactions(parm)>
	<!---<cfdump var="#rpt#" label="rpt" expand="false">--->
	<cfoutput>
	<table class="tableList" border="1">
		<tr>
			<th>Group Title</th>
			<th>Category Title</th>
			<th>Nominal Group</th>
			<th>Target</th>
			<th>Product ID</th>
			<th>Product Title</th>
			<th>Net</th>
			<th>VAT</th>
			<th>Trade</th>
			<th>Profit</th>
			<th>POR%</th>
			<th>Goal</th>
			<th>Goal</th>
			<th>Diff</th>
		</tr>
		<cfset diffLog = {}>
		<cfloop query="rpt.QEPOSItems">
			<cfset profit = 0>
			<cfset POR = 0>
			<cfset legend = "normal">
			<cfif eiNet neq 0>
				<cfset profit = -(eiNet + eiTrade)>
				<cfset POR = int((profit / -eiNet) * 10000) / 100>
				<cfset goal = int((pgTarget / (100 + pgTarget)) * 100)>
				<cfset diff = POR - goal>
				<cfif diff lt -10>
					<cfset legend = "vlow">
				<cfelseif diff lt -5>
					<cfset legend = "low">
				<cfelseif diff gt 10>
					<cfset legend = "vhigh">
				<cfelseif diff gt 5>
					<cfset legend = "high">
				<cfelse>
					<cfset legend = "normal">
				</cfif>
				<cfif !StructKeyExists(diffLog,legend)>
					<cfset StructInsert(diffLog,legend,0)>
				</cfif>
				<cfset diffLog[legend] = diffLog[legend] + 1>
			</cfif>
			<tr>
				<td>#pgTitle#</td>
				<td>#pcatTitle#</td>
				<td>#pgNomGroup#</td>
				<td>#int(pgTarget)#%</td>
				<td><a href="#application.site.url1#productStock6.cfm?product=#prodID#">#prodID#</a></td>
				<td>#prodTitle#</td>
				<td>#report.formatNum(-eiNet)#</td>
				<td>#report.formatNum(-eiVAT)#</td>
				<td>#report.formatNum(eiTrade)#</td>
				<td>#report.formatNum(profit)#</td>
				<td class="#legend#">#POR#%</td>
				<td class="#legend#">#goal#%</td>
				<td class="#legend#">#legend#</td>
				<td class="#legend#">#diff#%</td>
			</tr>
		</cfloop>
	</table>
	<table class="tableList" border="1">
		<cfloop collection="#diffLog#" item="key">
			<tr>
				<td>#key#</td>
				<td>#diffLog[key]#</td>
			</tr>
		</cfloop>
	</table>
	</cfoutput>
</cfif>





















