<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.form = form>
<cfset products = epos.LoadProductsByCategory(parm.form.catID)>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.products_item').click(function(event) {
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
								credit: ( dataAttributes.cashonly == 1 ) ? 0 : value,
								cash: ( dataAttributes.cashonly == 1 ) ? value : 0
							}));
						}
					});
				}
				event.preventDefault();
			});
		});
	</script>
	<div class="products">
		<ul class="products_list">
			<cfloop array="#products#" index="item">
				<cfif val(item.siOurPrice) eq 0>
					<cfset ourPrice = item.prodOurPrice>
				<cfelse>
					<cfset ourPrice = item.siOurPrice>
				</cfif>
				<li
					class="products_item material-ripple"
					data-account=""
					data-addtobasket="true"
					data-btnsend="add"
					data-class="item"
					data-discount="0"
					data-discountable="#item.prodStaffDiscount#"
					data-pubid=""
					data-prodid="#item.prodID#"
					data-prodtitle="#item.prodTitle#"
					data-qty="1"
					data-type="prod-#item.prodID#"
					data-prodClass="#item.prodClass#"
					data-vcode="#session.vat['#DecimalFormat(item.prodVatRate)#']#"
					data-vrate="#item.prodVatRate#"
					data-cashonly="#item.prodCashOnly#"
					data-prodsign="#item.prodSign#"
					data-itemclass="#item.epcKey#"
					<cfif item.prodCashOnly is 1>
						data-cash="#ourPrice#"
						data-credit="0"
					<cfelse>
						data-credit="#ourPrice#"
						data-cash="0"
					</cfif>
				>
					<span><strong>#item.prodTitle#</strong><cfif item.prodCashOnly eq 1><br />(Cash Only)</cfif></span>
					<span>
						<cfif ourPrice gt 0>
							&pound;#DecimalFormat(ourPrice)#
						<cfelse>
							Manual Price
						</cfif>
					</span>
				</li>
			</cfloop>
		</ul>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
		output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>
