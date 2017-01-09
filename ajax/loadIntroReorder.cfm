<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset slides = epos.LoadIntroSlides()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.intro_list').sortable({
				stop: function(event, ui) {
					var items = [];
					
					$('.il_item').each(function(i, e) {
						items.push({
							id: $(e).data("id"),
							index: i
						});
					});
					
					$.ajax({
						type: "POST",
						url: "ajax/saveIntroOrder.cfm",
						data: { "items": JSON.stringify(items) },
						success: function(data) {}
					});
				}
			});
		});
	</script>
	<ul class="intro_list">
		<cfloop array="#slides#" index="item">
			<li class="il_item" data-id="#item.id#">#Left( REReplaceNoCase(item.text, "<strong>|<\/strong>", ""), 50 )#...</li>
		</cfloop>
	</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>