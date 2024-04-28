<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset slides = epos.LoadIntroSlides()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.il_item').click(function(event) {
				var obj = $(this);
				$.ajax({
					type: "POST",
					url: "ajax/delIntroSlide.cfm",
					data: { "id": obj.data("id") },
					success: function(data) {
						obj.remove();
						$('.INTRO_tooltip, .INTRO_OutlineBox').remove();
					}
				});
			});
		});
	</script>
	<ul class="intro_list">
		<cfloop array="#slides#" index="item">
			<li class="il_item" data-id="#item.id#" style="cursor:not-allowed;">#Left(item.text, 50)#...</li>
		</cfloop>
	</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>