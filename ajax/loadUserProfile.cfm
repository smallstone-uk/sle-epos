<cftry>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.userID = session.user.id>

<cfoutput>
	<div class="user_profile">
		<script>
			$(document).ready(function(e) {
				$('.user_profile').htmlRemove();
				
				$('li[data-method="logout"]').click(function(event) {
					$.ajax({
						type: "GET",
						url: "ajax/logout.cfm",
						success: function(data) {
							$('.content').fadeOut(500, function() {
								$('.content').html("");
							});
							$.get("ajax/loadHomeScreen.cfm", function(data) {
								$('.home_screen_content').html(data);
							});
						}
					});
					event.preventDefault();
				});
				
				$('li[data-method="esplogout"]').click(function(event) {
					$.ajax({
						type: "GET",
						url: "ajax/logout.cfm",
						success: function(data) {
							window.location = "#parm.url#";
						}
					});
					event.preventDefault();
				});
			});
		</script>
		<ul>
			<li class="scalebtn" data-method="logout">Logout</li>
			<li class="scalebtn" data-method="esplogout">Especially Logout</li>
		</ul>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>