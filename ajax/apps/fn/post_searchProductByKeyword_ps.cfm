<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.keyword = keyword>
<cfset products = epos.LoadProductsByKeyword(parm.keyword)>

<cfoutput>
	<ul>
		<script>
			$(document).ready(function(e) {
				$('.ps_product_item').click(function(event) {
					if (allowClick) {
						if ( $(this).hasClass("ps_product_item_active") ) {
							$(this).removeClass("ps_product_item_active");
							$(this).find('.indicator').removeClass("icon-checkmark").addClass("icon-cross");
							deselectProduct($(this).data("id"));
						} else {
							if (products.length < maxqty) {
								$(this).addClass("ps_product_item_active");
								$(this).find('.indicator').removeClass("icon-cross").addClass("icon-checkmark");
								selectProduct($(this).data("id"), $(this).data("title"));
							}
						}
					}
					event.preventDefault();
				});
			});
		</script>
		<cfloop array="#products#" index="item">
			<li class="ps_product_item" data-id="#item.prodID#" data-title="#item.prodTitle#">
				<span class="indicator icon-cross"></span>
				<span>#item.prodTitle#</span>
				<cfif Len(item.prodUnitSize)>
					<span>#item.prodUnitSize#</span>
				</cfif>
			</li>
		</cfloop>
	</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>