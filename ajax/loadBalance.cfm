<cftry>
<cfset loc = {}>
<cfset loc.thisBasket = (session.till.isTranOpen) ? session.basket : session.till.prevtran>
<cfif StructIsEmpty(loc.thisBasket)>
	<!--- nothing to show --->
	<cfexit>
</cfif>
<cfoutput>
	<cfset loc.metaTitle = "Balance Due from Customer">
	<cfset loc.metaValue = decimalFormat(0.00)>
	<cfset loc.metaClass = "bmeta_dueto">
	<cfif loc.thisBasket.info.itemcount gt 0>
		<cfif loc.thisBasket.info.mode eq "reg">
			<cfif loc.thisBasket.info.canClose>
				<cfif loc.thisBasket.total.balance lte 0.001>
					<cfset loc.metaTitle = "Change">
					<cfset loc.metaValue = decimalFormat(-loc.thisBasket.info.change)>
					<cfset loc.metaClass = (loc.metaValue eq 0) ? "bmeta_dueto" : "bmeta_changeto">
				<cfelse>
					<cfset loc.metaTitle = "Balance Due from Customer">
					<cfset loc.metaValue = decimalFormat(loc.thisBasket.total.balance)>
					<cfset loc.metaClass = "bmeta_duefrom">
				</cfif>
			<cfelse>
				<cfif loc.thisBasket.total.balance gt 0.001>
					<cfset loc.metaTitle = "Balance Due from Customer">
					<cfset loc.metaValue = decimalFormat(loc.thisBasket.total.balance)>
					<cfset loc.metaClass = "bmeta_duefrom">
				<cfelse>
					<cfset loc.metaTitle = "Balance Due to Customer">
					<cfset loc.metaValue = decimalFormat(loc.thisBasket.total.balance)>
					<cfset loc.metaClass = "bmeta_dueto">
				</cfif>
			</cfif>
		<cfelse>
			<cfif loc.thisBasket.total.balance lte 0>
				<cfset loc.metaTitle = "Balance Due to Customer">
				<cfset loc.metaValue = decimalFormat(loc.thisBasket.total.balance)>
				<cfset loc.metaClass = "bmeta_dueto">
			<cfelse>
				<cfset loc.metaTitle = "Balance Due from Customer">
				<cfset loc.metaValue = decimalFormat(loc.thisBasket.total.balance)>
				<cfset loc.metaClass = "bmeta_duefrom">
			</cfif>
		</cfif>
	</cfif>

	<div class="basket_meta #loc.metaClass#">
		<div class="bmeta_balancedue">
			<span class="bmeta_heading">#loc.metaTitle#</span>
			<span class="bmeta_value">#loc.metaValue#</span>
		</div>

		<div class="bmeta_sub">
			<span class="bmetasub_itemcount">
				#loc.thisBasket.info.itemCount# items
			</span>

			<cfif not loc.thisBasket.tranID is 0>
				<span class="bmetasub_tranref">
					###loc.thisBasket.tranID#
				</span>
			</cfif>
		</div>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="" expand="yes" format="html" 
		output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>

