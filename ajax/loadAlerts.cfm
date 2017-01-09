<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset alerts = epos.LoadAlerts()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$(document).on("click", ".alert_item", function(event) {
				$(this).toggleClass("alert_item_active");
			});
			
			loadAlerts = function(a) {
				$.ajax({
					type: "GET",
					url: "ajax/apps/fn/get_alerts.cfm",
					success: function(data) {
						$('.alerts').html(data);
						if (typeof a == "function") a();
					}
				});
			}
			
			loadOldAlerts = function() {
				$.ajax({
					type: "GET",
					url: "ajax/apps/fn/get_oldAlerts.cfm",
					success: function(data) {
						$('.alerts').html(data);
					}
				});
			}
			
			loadAlerts();
			
			$(document).on("click", ".ac_item", function(event) {
				switch ( $(this).data("method") )
				{
					case "new":
						$.ajax({
							type: "GET",
							url: "ajax/apps/fn/get_newReminder.cfm",
							success: function(data) {
								$.sidepanel.next(data);
							}
						});
						break;
					case "flag":
						var alts = [];
						$('.alert_item_active').each(function(i, e) { alts.push( $(e).data("id") ); });
						$.ajax({
							type: "POST",
							url: "ajax/apps/fn/post_flagAlerts.cfm",
							data: {"alerts": JSON.stringify(alts)},
							success: function(data) {
								loadAlerts();
							}
						});
						break;
					case "past":
						loadOldAlerts();
						break;
					case "bookmarks":
						$.ajax({
							type: "GET",
							url: "ajax/apps/fn/get_bookmarks.cfm",
							success: function(data) {
								$.sidepanel.next(data);
							}
						});
						break;
				}
				event.preventDefault();
			});
		});
	</script>
	<div class="alert_controls">
		<ul>
			<li class="ac_item scalebtn" data-method="new"><span class="icon-alarm"></span></li>
			<li class="ac_item scalebtn" data-method="flag"><span class="icon-flag"></span></li>
			<li class="ac_item scalebtn" data-method="past"><span class="icon-history"></span></li>
			<li class="ac_item scalebtn" data-method="bookmarks"><span class="icon-bookmarks"></span></li>
		</ul>
	</div>
	<ul class="alerts"></ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>