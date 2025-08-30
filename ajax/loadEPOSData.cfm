
<cfobject component="code/reports" name="report">

<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.form = form>
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
					<th>#report.formatNum(rowClassTotal)#</th>
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
					<th>#report.formatNum(rowClassTotal)#</th>
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
					<th>#report.formatNum(rowClassTotal)#</th>
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
						<th align="right">#report.formatNum(colTotal,'0')#</th>
					</cfloop>
					<th>#report.formatNum(rowClassTotal,'0')#</th>
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
				<!---Qty<br>Net<br>VAT<br>Trade</td>--->
				<cfloop from="#srchHourFrom#" to="#srchHourTo#" index="i">
					<cfset ii = NumberFormat(i,'00')>
					<cfset slot = StructFind(item.slots,ii)>
					<td align="right">
						<table class="smallTable" border="0">
							<tr><td align="right" class="qty">#report.formatNum(slot.qty,'0')#</td></tr>
							<tr><td align="right">#report.formatNum(slot.net)#</td></tr>
							<tr><td align="right">#report.formatNum(slot.VAT)#</td></tr>
							<tr><td align="right" class="trade">#report.formatNum(slot.trade)#</td></tr>								
						</table>
						<!---<span class="qty">&nbsp;#report.formatNum(slot.qty,'0')#</span><br>
						&nbsp;#report.formatNum(slot.net)#<br>
						&nbsp;#report.formatNum(slot.VAT)#<br>
						<span class="trade">&nbsp;#report.formatNum(slot.trade)#</span>--->
					</td>
				</cfloop>
				<td align="right">
					<table class="smallTable" border="0">
						<tr><td align="right" class="qty">#report.formatNum(item.rowTotalQty,'0')#</td></tr>
						<tr><td align="right">#report.formatNum(item.rowTotalNet)#</td></tr>
						<tr><td align="right">#report.formatNum(item.rowTotalVAT)#</td></tr>
						<tr><td align="right" class="trade">#report.formatNum(item.rowTotalTrade)#</td></tr>								
					</table>
					<!---<span class="qty">&nbsp;#report.formatNum(item.rowTotalQty,'0')#</span><br>
					&nbsp;#report.formatNum(item.rowTotalNet)#<br>
					&nbsp;#report.formatNum(item.rowTotalVAT)#<br>
					<span class="trade">&nbsp;#report.formatNum(item.rowTotalTrade)#</span>--->
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
				<th>#report.formatNum(rowClassTotal)#</th>
			</tr>
			<tr>
				<th colspan="4">Check Totals</th>
				<cfloop from="#srchHourFrom#" to="#srchHourTo#" index="i">
					<cfset ii = NumberFormat(i,'00')>
					<cfset colTotal = 0>
					<cfset rowClassTotal = 0>
					<cfloop list="sale,item,pay,supp" index="itemClass" delimiters=",">
						<cfset slot = StructFind(rpt.totals,itemClass)>
						<cfset total = StructFind(slot,ii)>
						<cfset colTotal += (total.net + total.VAT)>
						<cfset rowClassTotal += (total.net + total.VAT)>
					</cfloop>
					<cfif colTotal lt 0.001><cfset colTotal = 0></cfif>
					<th align="right">#DecimalFormat(colTotal)#</th>
				</cfloop>
				<th>#DecimalFormat(rowClassTotal)#</th>
			</tr>
		<cfelse>
			<tr>
				<td colspan="8">No data found to display.</td>
			</tr>
		</cfif>
	</table>
	</cfoutput>
</cfif>

