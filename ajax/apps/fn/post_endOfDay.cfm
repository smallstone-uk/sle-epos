<cfscript>
    try {
        // If no value was passed, default it to 0.00
        for (field in form) {
            if (isValid("string", form[field]) && form[field] == '') {
                form[field] = 0.00;
            }
        }

        dayHeader = {};
        today = new App.DayHeader().today();

        if (structIsEmpty(today)) {
            // Create a new record for today
            dayHeader = new App.DayHeader().save(form);
        } else {
            // Update the existing record for today
            dayHeader = new App.DayHeader(today.dhID).save(form);
        }
    } catch(any error) {
        writeDumpToFile(error);
    }
</cfscript>

<cftry>

<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfobject component="#application.site.codePath#" name="ecfc">
<cfif StructKeyExists(session,"till")>
	<cfset parm.reportDate = session.till.prefs.reportDate>
<cfelse>
	<cfset parm.reportDate = Now()>
</cfif>
<cfset epos = ecfc.LoadEPOSTotals(parm)>
<!---<cfdump var="#epos#" label="epos" expand="false">--->
<cfset lottoTotal = epos.accounts.lottery + epos.accounts.scratchcard + epos.accounts.lprize + epos.accounts.sprize>
<cfif lottoTotal lt 0>
	<cfset lottoCoins = (((lottoTotal * 100) MOD 500) / 100) * -1>
<cfelse>
	<cfset lottoCoins = 0>
</cfif>
<cfset psCoins = (((epos.accounts.paystation * 100) MOD 500) / 100) * -1>
<cfoutput>
	<cfset floatCoinLimit = 70>
	<cfset noteTotal = 0>
	<cfset coinTotal = 0>
	<cfset poundArray = [50,20,10,5,2,1]>
	<table>
		<cfloop array="#poundArray#" index="denom">
			<cfset dataMOD = denom * 100>
			<cfset poundFld = "dhcid_#NumberFormat(dataMOD,'0000')#">
			<cfset value = StructFind(dayHeader,poundFld)>
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
			<cfset value = StructFind(dayHeader,penceFld)>
			<cfset coinTotal += value>
			<tr>
				<td>#denom#p</td>
				<td align="right">#value#</td>
			</tr>
		</cfloop>
		<tr>
			<td>News Vouchers</td>
			<td align="right">#epos.accounts.voucher#</td>
		</tr>
		<tr>
			<td>Coupons</td>
			<td align="right">#epos.accounts.cpn#</td>
		</tr>
		<tr>
			<td>Cash Total</td>
			<td align="right">#DecimalFormat(noteTotal + coinTotal)#</td>
		</tr>
		<tr>
			<td>Cash INDW</td>
			<td align="right">#epos.accounts.cashINDW#</td>
		</tr>
		<tr>
			<td>Difference</td>
			<td align="right">#DecimalFormat(noteTotal + coinTotal - epos.accounts.cashINDW)#</td>
		</tr>
	</table>
	<table>
		<tr>
			<td>Coin Total</td>
			<td align="right">#coinTotal#</td>
		</tr>
		<tr>
			<td>Lottery Coins</td>
			<td align="right">#DecimalFormat(lottoCoins)#</td>
		</tr>
		<tr>
			<td>PayStation Coins</td>
			<td align="right">#DecimalFormat(psCoins)#</td>
		</tr>
		<cfset remCoins = coinTotal - lottoCoins - psCoins>
		<cfset bankCoins = ((remCoins * 100) MOD 500) / 100>
		<cfset floatcoins = remCoins - bankCoins>
		<cfif floatcoins gt floatCoinLimit>
			<cfset floatcoins = floatCoinLimit>
			<cfset bankCoins = remCoins - floatcoins>
		</cfif>
		<tr>
			<td>Sub Total</td>
			<td align="right">#DecimalFormat(remCoins)#</td>
		</tr>
		<tr>
			<td>Bank Coins</td>
			<td align="right">#bankCoins#</td>
		</tr>
		<tr>
			<td>Float Coins</td>
			<td align="right">#DecimalFormat(floatcoins)#</td>
		</tr>
	</table>
	<table>
		<tr>
			<td>Cheques Received</td>
			<td align="right">#epos.accounts.chqINDW#</td>
		</tr>
		<tr>
			<td>Card INDW</td>
			<td align="right">#epos.accounts.cardINDW#</td>
		</tr>
		<tr>
			<td>Suppliers Paid</td>
			<td align="right">#epos.accounts.supplier#</td>
		</tr>
		<tr>
			<td>TOTAL RECEIPTS</td>
			<td align="right">TBA</td>
		</tr>
	</table>

    <!--- Summary View
    <cfset writeDump(dayHeader)> --->
</cfoutput>
	<!--- code --->
<cfcatch type="any">
	<cfdump var="#cfcatch#" label="" expand="yes" format="html" 
		output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>
