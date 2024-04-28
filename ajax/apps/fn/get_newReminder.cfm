<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset bookmarks = epos.LoadBookmarks()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('textarea[name="r_desc"]').virtualKeyboard();
			$('input[name="r_time"]').virtualTime();
			$('input[name="r_date"]').virtualDate();
			
			$('.NewReminderForm').submit(function(event) {
				$.ajax({
					type: "POST",
					url: "ajax/apps/fn/post_newReminder.cfm",
					data: $(this).serialize(),
					success: function(data) {
						loadAlerts(function() {
							$('.sidepanel_page_back').click();
							$('.ai_first').addClass("flash");
						});
					}
				});
				event.preventDefault();
			});
			
			window.pickBookmark = function(title, time) {
				$('textarea[name="r_desc"]').val(title);
				$('input[name="r_time"]').val(time);
				
				setTimeout(function() {
					$('.sidepanel_expansion').fadeOut();
				}, 1000);
			}
			
			$('.nrf_books').click(function(event) {
				$.ajax({
					type: "GET",
					url: "ajax/apps/fn/get_bookmarksForNew.cfm",
					success: function(data) {
						$.sidepanel.expand({
							content: data
						});
					}
				});
				event.preventDefault();
			});
			
			$('.r_recur').touchCheckbox(function(isChecked) {
				$('input[name="r_date"]').prop( "disabled", (isChecked) ? true : false );
			});
		});
	</script>
	<span class="title">New Reminder</span>
	<form method="post" enctype="multipart/form-data" class="NewReminderForm">
		<button class="appbtn hollow nrf_books">Choose from Bookmarks</button>
		<span class="apphr">OR</span>
		<textarea name="r_desc" class="appfld" placeholder="Enter your own reminder description"></textarea>
		<input type="text" name="r_time" class="appfld" placeholder="Reminder Time (HH:MM)" style="margin-left: 65px;width: 314px !important;">
		<input type="text" name="r_date" class="appfld" placeholder="Reminder Date (DD/MM/YYYY)" style="margin-left: 65px;width: 314px !important;" data-past="false" data-future="true">
		<span class="appfldnote">
			<span>Recur every day</span>
			<input type="checkbox" name="r_recur" class="r_recur appchk">
		</span>
		<input type="submit" value="Create" class="appbtn">
	</form>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>