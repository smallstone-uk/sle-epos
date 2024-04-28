<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset cats = epos.LoadCategoriesForEmployeeMin()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.ps_cat_item').click(function(event) {
				var id = $(this).data("id"),
					title = $(this).data("title");
				$.ajax({
					type: "POST",
					url: "ajax/apps/fn/post_loadProductsInCat.cfm",
					data: {
						"id": id,
						"title": title
					},
					success: function(data) {
						$('.ps_main').html(data);
					}
				});
				event.preventDefault();
			});
		});
	</script>
	<ul>
		<cfloop array="#cats#" index="item">
			<cfif !Len(item.epcFile)>
				<li class="ps_cat_item" data-id="#item.epcID#" data-title="#item.epcTitle#">
					<span>#item.epcTitle#</span>
				</li>
			</cfif>
		</cfloop>
	</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>