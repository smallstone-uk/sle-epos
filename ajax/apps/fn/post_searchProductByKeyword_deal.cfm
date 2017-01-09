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
		<span class="ul_header">We searched for #parm.keyword#...</span>
		<cfloop array="#products#" index="item">
			<li class="epf_product_item" data-id="#item.prodID#" data-title="#item.prodTitle#">
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