<!---28/04/2024--->
<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.form = form>
<cfset searchResults = epos.SearchProductByName(parm)>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.searchItem').click(function(event) {
				var obj = $(this);
				var dataAttributes = getDataAttributes( $(this) );
				if (dataAttributes.credit != 0 || dataAttributes.cash != 0) {
					$.addToBasket(dataAttributes);
				} else {
					$.virtualNumpad({
						maximum: 50,
						overide: true,
						callback: function(value) {
							$.addToBasket( getDataAttributes(obj, "plain", {
								credit: ( dataAttributes.cashonly === 1 ) ? 0 : value * dataAttributes.sign,
								cash: ( dataAttributes.cashonly === 1 ) ? value * dataAttributes.sign : 0
							}));
						}
					});
				}
				event.preventDefault();
			});
		});
	</script>
	<ul class="searchList">
		<cfif !ArrayIsEmpty(searchResults)>
			<!--- de-dupe --->
			<cfset loc.title = "">
			<cfset loc.size = "">
			<div id="div-table">
				<div id="div-table-body">
			<cfloop array="#searchResults#" index="item">
				<cfset item.prodTitle = Trim(item.prodTitle)>
				<cfset item.siUnitSize = Trim(item.siUnitSize)>
				<cfif item.prodTitle eq loc.title AND item.siUnitSize eq loc.size>
					<!--- skip product --->
				<cfelse>
					<cfif val(item.siOurPrice) eq 0>
						<cfset ourPrice = item.prodOurPrice>
					<cfelse>
						<cfset ourPrice = item.siOurPrice>
					</cfif>
					<cfif ourPrice gt 0>
						<cfset showPrice = "&pound;#DecimalFormat(ourPrice)#">
					<cfelse>
						<cfset showPrice = "Manual Price">
					</cfif>
					<li
						class="searchItem material-ripple"
						data-account=""
						data-addtobasket="true"
						data-btnsend="add"
						data-class="item"
						data-discount="0"
						data-discountable="#item.prodStaffDiscount#"
						data-pubid=""
						data-prodid="#item.prodID#"
						data-prodtitle="#item.prodTitle#"
						data-unitsize="#item.siUnitSize#"
						data-qty="1"
						data-type="prod-#item.prodID#"
						data-prodClass="#item.prodClass#"
						data-vcode="#session.vat['#DecimalFormat(item.prodVatRate)#']#"
						data-vrate="#item.prodVatRate#"
						data-cashonly="#item.prodCashOnly#"
						data-prodsign="#item.prodSign#"
						data-itemclass="#item.epcKey#"
						<cfif StructKeyExists(item,"siUnitTrade")>data-unittrade="#item.siUnitTrade#"
							<cfelse>data-unittrade="#item.prodUnitTrade#"</cfif>
						<cfif item.prodCashOnly is 1>
							data-cash="#ourPrice#"
							data-credit="0"
						<cfelse>
							data-credit="#ourPrice#"
							data-cash="0"
						</cfif>
					>
							<div class="resp-table-row">
								<div class="table-body-cell" style="float:left; width:80px;">#DateFormat(item.soDate,'dd-mmm-yy')#</div>
								<div class="table-body-middle">#Left(item.prodTitle,80)# #item.siUnitSize#
									<cfif item.prodCashOnly eq 1> (Cash Only)</cfif></div>
								<div class="table-body-cell" style="float:right; width:70px; text-align:right;">#showPrice#</div>
							</div>

<!---						<span> &nbsp; #DateFormat(item.soDate,'dd-mmm-yy')#</span>
						<span class="searchListTitle">#Left(item.prodTitle,50)# <cfif len(item.siUnitSize)>#item.siUnitSize#</cfif>
							<cfif item.prodCashOnly eq 1> (Cash Only)</cfif></span>
						<span style="float:right;">#showPrice#</span>
--->					</li>
				</cfif>
				<cfset loc.title = item.prodTitle>
				<cfset loc.size = item.siUnitSize>
			</cfloop>
						</div>
					</div>
		</cfif>
	</ul>
	#ArrayLen(searchResults)# products found.
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>