<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			loadReminders = function() {
				$.ajax({
					type: "GET",
					url: "ajax/loadReminders.cfm",
					success: function(data) {
						$('.reminders').html(data);
					}
				});
			}
			
			loadReminders();
		});
	</script>
	<div class="reminders"></div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>