<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('form').submit(function(event) { event.preventDefault(); });
			$('.ui-text').virtualKeyboard();
			$('.ui-date').virtualDate();
			$('.ui-number').virtualNumpad();
			
			$('.back').click(function(event) {
				var udForm = $(this).attr("data-form");
				var thisForm = $(this).parents('form');
				var prevForm = (typeof udForm != "undefined") ? $(udForm) : thisForm.prev('form');
				thisForm.fadeOut(function() {prevForm.fadeIn();});
				event.preventDefault();
			});
			
			$('.msf_new').click(function(event) {
				$('.MethodSelectForm').fadeOut(function() { $('.NewUserForm')[0].reset(); $('.NewUserForm').fadeIn(); });
				event.preventDefault();
			});
			
			$('.NewUserForm').submit(function(event) {
				$.ajax({
					type: "POST",
					url: "ajax/apps/fn/post_newUser.cfm",
					data: $('.NewUserForm').serialize(),
					success: function(data) {}
				});
				event.preventDefault();
			});
		});
	</script>
	<form method="post" enctype="multipart/form-data" class="MethodSelectForm">
		<span class="title">What will it be?</span>
		<table border="0">
			<tr>
				<td><input type="submit" value="New User" class="appbtn msf_new"></td>
				<td><input type="submit" value="Existing User" class="appbtn msf_old"></td>
			</tr>
		</table>
	</form>
	<form method="post" enctype="multipart/form-data" class="NewUserForm" style="display:none;">
		<span class="title"><span class="back icon-circle-left" data-form=".MethodSelectForm"></span>New User</span>
		<table border="0">
			<tr>
				<th align="right">First Name</th>
				<td><input type="text" class="appfld ui-text" placeholder="First Name" name="nuf_firstname"></td>
			</tr>
			<tr>
				<th align="right">Last Name</th>
				<td><input type="text" class="appfld ui-text" placeholder="Last Name" name="nuf_lastname"></td>
			</tr>
			<tr>
				<th align="right">National Insurance</th>
				<td><input type="text" class="appfld ui-text" placeholder="National Insurance" name="nuf_ni"></td>
			</tr>
			<tr>
				<th align="right">Tax Code</th>
				<td><input type="text" class="appfld ui-text" placeholder="Tax Code" name="nuf_taxcode"></td>
			</tr>
			<tr>
				<th align="right">Date of Birth</th>
				<td><input type="text" class="datefld ui-date" placeholder="DD/MM/YYYY" name="nuf_dob"></td>
			</tr>
			<tr>
				<th align="right">Rate 1</th>
				<td><input type="text" class="money ui-number" placeholder="GBP" name="nuf_rate1"></td>
			</tr>
			<tr>
				<th align="right">Rate 2</th>
				<td><input type="text" class="money ui-number" placeholder="GBP" name="nuf_rate2"></td>
			</tr>
			<tr>
				<th align="right">Rate 3</th>
				<td><input type="text" class="money ui-number" placeholder="GBP" name="nuf_rate3"></td>
			</tr>
		</table>
		<input type="submit" class="appbtn" value="Continue">
	</form>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>