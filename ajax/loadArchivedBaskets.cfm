<cftry>
<cfset parm = {}>
<cfset parm.url = application.site.normal>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.archive_item').click(function(event) {
				var key = $(this).html();
				$.ajax({
					type: "POST",
					url: "ajax/openArchive.cfm",
					data: {"key": key},
					success: function(data) {
						window.location = "#parm.url#epos2";
					}
				});
				event.preventDefault();
			});
		});
	</script>
	<ul class="archive_list">
		<cfloop collection="#session.epos_archive#" item="key">
			<li class="archive_item">#key#</li>
		</cfloop>
	</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>