<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.userID = session.user.id>
<cfset reminders = {
	global = epos.LoadGlobalReminders(parm),
	local = epos.LoadLocalReminders(parm)
}>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.r_row').click(function(event) {
				$(this).find('.r_desc').slideToggle(250);
				event.preventDefault();
			});
			$('.r_completedBtn').click(function(event) {
				var id = $(this).data("id");
				var scope = $(this).data("scope");
				var status = $(this).html();
				$.ajax({
					type: "POST",
					url: "ajax/updateReminder.cfm",
					data: {
						"reminderID": id,
						"status": status,
						"remScope": scope
					},
					success: function(data) {
						loadReminders();
					}
				});
				event.preventDefault();
			});
		});
	</script>
		<ul class="reminders_local">
			<h1>Reminders for #session.user.firstName#</h1>
			<cfloop array="#reminders.local#" index="item">
				<li class="r_row <cfif item.elrStatus eq "Completed">r_row_completed</cfif>">
					<cfif item.elrStatus eq "Completed">
						<div class="r_tick"></div>
					<cfelse>
						<div class="r_time"></div>
					</cfif>
					<div class="r_subject">#item.elrSubject#</div>
					<div class="r_status">#item.elrStatus#</div>
					<cfif item.elrRecurring eq "none">
						<div class="r_end">
							<span class="r_end_note" style="font-weight:bold;">END</span>
							<cfif LSDateFormat(item.elrEnd, "yyyy-mm-dd") eq LSDateFormat(Now(), "yyyy-mm-dd")>
								Today at #LSTimeFormat(item.elrEnd, "HH:mm")#
							<cfelse>
								#LSDateFormat(item.elrEnd, "d mmm")# #LSTimeFormat(item.elrEnd, "HH:mm")#
							</cfif>
						</div>
						<div class="r_start">
							<span class="r_start_note" style="font-weight:bold;">START</span>
							<cfif LSDateFormat(item.elrStart, "yyyy-mm-dd") eq LSDateFormat(Now(), "yyyy-mm-dd")>
								Today at #LSTimeFormat(item.elrStart, "HH:mm")#
							<cfelse>
								#LSDateFormat(item.elrStart, "d mmm")# #LSTimeFormat(item.elrStart, "HH:mm")#
							</cfif>
						</div>
					<cfelse>
						<div class="r_start">
							<cfswitch expression="#item.elrRecurring#">
								<cfcase value="hourly">Every Hour</cfcase>
								<cfcase value="daily">Every Day at #LSTimeFormat(item.elrStart, "HH:mm")#</cfcase>
								<cfcase value="weekly">Every Week on #LSDateFormat(item.elrStart, "dddd")#</cfcase>
								<cfcase value="monthly">Every Month</cfcase>
								<cfcase value="yearly">Every Year</cfcase>
							</cfswitch>
						</div>
					</cfif>
					<div class="r_desc" style="display:none;">
						#item.elrDescription#<br />
						<button class="r_completedBtn" style="margin:10px 0 0 5px;width:49%;background:##777;" data-id="#item.elrID#" data-scope="local">Pending</button>
						<button class="r_completedBtn" style="margin:10px 5px 0 0;width:49%;" data-id="#item.elrID#" data-scope="local">Completed</button>
					</div>
				</li>
			</cfloop>
		</ul>
		<ul class="reminders_global">
			<h1>General Reminders</h1>
			<cfloop array="#reminders.global#" index="item">
				<li class="r_row <cfif item.egrStatus eq "Completed">r_row_completed</cfif>">
					<cfif item.egrStatus eq "Completed">
						<div class="r_tick"></div>
					<cfelse>
						<div class="r_time"></div>
					</cfif>
					<div class="r_subject">#item.egrSubject#</div>
					<div class="r_status">#item.egrStatus#</div>
					<cfif item.egrRecurring eq "none">
						<div class="r_end">
							<span class="r_end_note" style="font-weight:bold;">END</span>
							<cfif LSDateFormat(item.egrEnd, "yyyy-mm-dd") eq LSDateFormat(Now(), "yyyy-mm-dd")>
								Today at #LSTimeFormat(item.egrEnd, "HH:mm")#
							<cfelse>
								#LSDateFormat(item.egrEnd, "d mmm")# #LSTimeFormat(item.egrEnd, "HH:mm")#
							</cfif>
						</div>
						<div class="r_start">
							<span class="r_start_note" style="font-weight:bold;">START</span>
							<cfif LSDateFormat(item.egrStart, "yyyy-mm-dd") eq LSDateFormat(Now(), "yyyy-mm-dd")>
								Today at #LSTimeFormat(item.egrStart, "HH:mm")#
							<cfelse>
								#LSDateFormat(item.egrStart, "d mmm")# #LSTimeFormat(item.egrStart, "HH:mm")#
							</cfif>
						</div>
					<cfelse>
						<div class="r_start">
							<cfswitch expression="#item.egrRecurring#">
								<cfcase value="hourly">Every Hour</cfcase>
								<cfcase value="daily">Every Day at #LSTimeFormat(item.egrStart, "HH:mm")#</cfcase>
								<cfcase value="weekly">Every Week on #LSDateFormat(item.egrStart, "dddd")#</cfcase>
								<cfcase value="monthly">Every Month</cfcase>
								<cfcase value="yearly">Every Year</cfcase>
							</cfswitch>
						</div>
					</cfif>
					<div class="r_desc" style="display:none;">
						#item.egrDescription#<br />
						<button class="r_completedBtn" style="margin:10px 0 0 5px;width:49%;background:##777;" data-id="#item.egrID#" data-scope="global">Pending</button>
						<button class="r_completedBtn" style="margin:10px 5px 0 0;width:49%;" data-id="#item.egrID#" data-scope="global">Completed</button>
					</div>
				</li>
			</cfloop>
		</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>