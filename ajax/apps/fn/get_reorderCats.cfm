<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset cats = epos.LoadCategoriesForEmployeeMin()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			var items = [];
			$('.reordercatlist').sortable({
				update: function(event, ui) {
					items = [];
					$('.reordercatlist').find('li').each(function(i, e) {
						items.push({
							id: $(e).attr("data-id"),
							order: i
						});
					});
					$.ajax({
						type: "POST",
						url: "ajax/apps/fn/post_reorderCats.cfm",
						data: {"items": JSON.stringify(items)},
						success: function(data) {}
					});
				}
			});
		});
	</script>
	<ul class="applist reordercatlist">
		<cfloop array="#cats#" index="item">
			<li class="applistitem epf_cat_orderitem" data-id="#item.epcID#">
				<span class="icon-menu epf_cat_ordericon"></span>
				#item.epcTitle#
			</li>
		</cfloop>
	</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>