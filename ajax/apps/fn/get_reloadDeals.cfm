<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.edf_dealitem').touchHold([
				{
					text: "edit",
					action: function(a, e) {
						$.ajax({
							type: "POST",
							url: "ajax/apps/fn/get_editDeal.cfm",
							data: {"dealID": a.id},
							success: function(data) {
								$.sidepanel(data, 700);
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
								url: "ajax/apps/fn/post_delDeal.cfm",
								data: {"dealID": a.id},
								success: function(data) {
									e.remove();
									$.appMsg("Deal Deleted Successfully");
								}
							});
						});
					}
				}
			]);
		});
	</script>
	<ul>
		<cfloop array="#session.epos_frame.deals#" index="item">
			<li class="edf_dealitem" data-id="#item.edID#">#item.edTitle#</li>
		</cfloop>
	</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>