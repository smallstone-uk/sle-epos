<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.splash_user').click(function(event) {
				var employee = $(this).data("id");
				$.virtualNumpad({
					autolength: 4,
					wholenumber: true,
					callback: function(pin) {
						$.ajax({
							type: "POST",
							url: "ajax/login.cfm",
							data: {
								"employee": employee,
								"pin": pin
							},
							success: function(data) {
								var response = data.trim();
								if (response == "true") {
									window.location = "#parm.url#epos2";
								} else {
									$.msgBox("Invalid Login", "error");
								}
							}
						});
					}
				});
				event.preventDefault();
			});
			
			$('.user_login_list').center("left");
			$('.splash_time').currentTime();
		});
	</script>
	<div class="splash">
		<ul class="user_login_list">
			<cfloop array="#epos.LoadEmployees()#" index="item">
				<li data-id="#item.empID#" class="splash_user">#item.empFirstName# #Left(item.empLastName, 1)#</li>
			</cfloop>
		</ul>
		<div class="splash_time">#LSTimeFormat(Now(), "HH:mm")#</div>
		<div class="splash_date_day">#LSDateFormat(Now(), "dddd")#</div>
		<div class="splash_date_monthyear">#LSDateFormat(Now(), "dd mmmm")#</div>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>