<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.barcode = barcode>
<cfset product = epos.LoadProductByBarcode(parm.barcode)>

<cfoutput>
	<ul>
		<script>
			$(document).ready(function(e) {
				$('.epf_product_item').click(function(event) {
					deals["product"] = {
						id: $(this).attr("data-id"),
						title: $(this).attr("data-title")
					};
					dealProductContinue();
					event.preventDefault();
				});
			});
		</script>
		<span class="ul_header"></span>
		<li class="epf_product_item" data-id="#product.prodID#" data-title="#product.prodTitle#">
			<span>#product.prodTitle#</span>
			<cfif Len(product.prodUnitSize)>
				<span>#product.prodUnitSize#</span>
			</cfif>
		</li>
	</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>