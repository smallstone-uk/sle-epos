<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset cats = new App.User(session.user.id).getEPOSCategories()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.categories_item').click(function(event) {
				var file = $(this).data("file");
				var id = $(this).data("id");
				var url = (file.length > 0) ? "ajax/" + file : "ajax/productsByCategory.cfm";
				var title = $(this).data("title");
				if (title.trim() == "Suppliers") {
				//	$.ifBasketEmpty(function() {
						$.ajax({
							type: "POST",
							url: url,
							data: {
								"title": title,
								"catID": id,
								"file": file
							},
							success: function(data) {
								$('.categories_viewer').html(data);
							}
						});
				//	}, function() { $.msgBox("You cannot pay a supplier whilst in the middle of a transaction"); });
				} else {
					$.ajax({
						type: "POST",
						url: url,
						data: {
							"title": title,
							"catID": id,
							"file": file
						},
						success: function(data) {
							$('.categories_viewer').html(data);
						}
					});
				}
			});
		});
	</script>
	<div class="categories_viewer">
		<cfinclude template="ajax/loadHome.cfm">
	</div>
	<div class="categories">
		<ul class="categories_list">
			<cfloop array="#cats#" index="item">
				<li data-id="#item.epcID#" data-file="#item.epcFile#" class="categories_item material-ripple" data-title="#item.epcTitle#">
					<span>#item.epcTitle#</span>
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
