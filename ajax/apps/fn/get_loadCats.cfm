<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset cats = epos.LoadCategoriesForEmployeeMin()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.epf_cat_item_2').touchHold([
				{
					text: "edit",
					action: function(a, e) {
						$.virtualKeyboard({
							value: a.text,
							callback: function(newTitle) {
								$.ajax({
									type: "POST",
									url: "ajax/apps/fn/post_editCat.cfm",
									data: {
										"catID": a.id,
										"catTitle": newTitle
									},
									success: function(data) {
										e.html(newTitle).attr("data-text", newTitle);
										$.appMsg("Category updated successfully.");
									}
								});
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
								url: "ajax/apps/fn/post_delCat.cfm",
								data: {"catID": a.id},
								success: function(data) {
									e.remove();
									$.appMsg("Category deleted successfully.");
								}
							});
						});
					}
				}
			]);
		});
	</script>
	<ul class="applist">
		<cfloop array="#cats#" index="item">
			<li class="applistitem epf_cat_item_2" data-id="#item.epcID#" data-text="#item.epcTitle#">
				<span class="icon-folder epf_cat_ordericon"></span>
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