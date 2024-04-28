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
		
        yesterday = new App.DayHeader().yesterday();
        if (structIsEmpty(yesterday)) {
			writeDumpToFile("unable to load previous day data");
        }
		writeDumpToFile(yesterday);
    } catch(any error) {
        writeDumpToFile(error);
    }
</cfscript>

<cftry>

<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfobject component="#application.site.codePath#" name="ecfc">
<cfif StructKeyExists(session,"till")>
	<cfset parm.reportDateFrom = session.till.prefs.reportDate>
<cfelse>
	<cfset parm.reportDateFrom = Now()>
</cfif>
<cfset parm.reportDate = parm.reportDateFrom>
<cfset epos = ecfc.LoadEPOSTotals(parm)>

<cfif StructIsEmpty(epos.accounts)>
	Nothing to show yet.
	<cfexit>
</cfif>
<cfset loc = {}>
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
		<tr>
			<th colspan="2">Cash Counted</th>
		</tr>
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
			<th colspan="2">Coin Distribution</th>
		</tr>
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
		<cfset loc.remCoins = coinTotal - lottoCoins - psCoins>
		<cfif loc.remCoins gt floatCoinLimit>
			<cfset loc.floatcoins = floatCoinLimit>
			<cfset loc.bankCoins = loc.remCoins - floatCoinLimit>
		<cfelse>
			<cfset loc.floatcoins = int((loc.remCoins*100)/500) * 5>
			<cfset loc.bankCoins = loc.remCoins - loc.floatcoins>
		</cfif>
		<tr>
			<td>Sub Total</td>
			<td align="right">#DecimalFormat(loc.remCoins)#</td>
		</tr>
		<tr>
			<td>Bank Coins</td>
			<td align="right">#loc.bankCoins#</td>
		</tr>
		<tr>
			<td>Float Coins</td>
			<td align="right">#DecimalFormat(loc.floatcoins)#</td>
		</tr>
	</table>
	<table>
		<tr>
			<th colspan="2">Till Totals</th>
		</tr>
		<cfloop collection="#epos.accounts#" item="key">
			<cfset value = StructFind(epos.accounts,key)>
			<cfif value neq 0>
				<tr>
					<td>#key#</td>
					<td align="right">#value#</td>
				</tr>
			</cfif>
		</cfloop>
	</table>
</cfoutput>
<cfcatch type="any">
	<cfdump var="#cfcatch#" label="" expand="yes" format="html"
		output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>
