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
				$('.epf_product_item').touchHold([
					{
						text: "edit",
						action: function(a, e) {
							$.ajax({
								type: "POST",
								url: "ajax/apps/fn/get_editProduct.cfm",
								data: {"prodID": a.id},
								success: function(data) {
									$.sidepanel(data);
								}
							});
						}
					},
					{
						text: "delete",
						action: function(a, e) {
							$.confirmation(function() {
								$.ajax({
									type: "POST",
									url: "ajax/apps/fn/post_delProduct.cfm",
									data: {"prodID": a.id},
									success: function(data) {
										e.remove();
										$('.ul_header').after('<span class="ul_header">If a product has been deleted but still appears, contact the administrator.</span>');
									}
								});
							});
						}
					}
				]);
			});
		</script>
		<span class="ul_header">We searched for #parm.keyword#...</span>
		<cfloop array="#products#" index="item">
			<li class="epf_product_item" data-id="#item.prodID#">
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