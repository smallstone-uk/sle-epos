<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.userID = session.user.id>
<cfset userPrefs = epos.LoadUserPreferences(parm)>

<cfoutput>
	<div class="user_prefs">
		<script>
			$(document).ready(function(e) {
				var #ToScript(userPrefs, "user")#;
				
				$('.user_prefs').htmlRemove(function(target) {
					if (!target.is($('.user_prefs')) && !target.is($('.user_prefs').find('*'))) {
						$('.header_user').css("background-color", "");
					}
				});
				
				$('.accent_list li[style="background-color:' + user.empaccent + ';"]').addClass("accent_ticked");
				
				$('.accent_list li').click(function(event) {
					$('.accent_list li').removeClass("accent_ticked");
					$(this).addClass("accent_ticked");
					var colour = $(this).data("colour");
					
					$.ajax({
						type: "POST",
						url: "ajax/setAccentColour.cfm",
						data: {
							"employee": user.empid,
							"colour": colour
						},
						success: function(data) {
							$.ajax({
								type: "GET",
								url: "ajax/getStyleOveride.cfm",
								success: function(data) {
									$('.style_overide').html(data);
								}
							});
						}
					});
				});
				
				$('.user_prefs_changePin').click(function(event) {
					$.virtualNumpad({
						hint: "Enter your current pin number",
						autolength: 4,
						wholenumber: true,
						callback: function(old_pin) {
							setTimeout(function() {
								$.virtualNumpad({
									hint: "Enter your new pin number",
									autolength: 4,
									wholenumber: true,
									callback: function(pin_1) {
										setTimeout(function() {
											$.virtualNumpad({
												hint: "Re-enter your new pin number",
												autolength: 4,
												wholenumber: true,
												callback: function(pin_2) {
													if (pin_1 == pin_2) {
														$.ajax({
															type: "POST",
															url: "ajax/updatePin.cfm",
															data: {
																"oldpin": old_pin,
																"newpin": pin_1
															},
															success: function(data) {
																var result = data.toJava();
																var msgType = (Number(result.error) == 1) ? "error" : "success";
																$.msgBox(result.msg, msgType);
															}
														});
													}
												}
											});
										}, 1000);
									}
								});
							}, 1000);
						}
					});
					event.preventDefault();
				});
				
				$('.custom_color_btn').farbtastic(function(colour) {
					$.ajax({
						type: "POST",
						url: "ajax/setAccentColour.cfm",
						data: {
							"employee": user.empid,
							"colour": colour
						},
						success: function(data) {
							$.ajax({
								type: "GET",
								url: "ajax/getStyleOveride.cfm",
								success: function(data) {
									$('.style_overide').html(data);
								}
							});
						}
					});
				});
				
				$('.user_prefs_customcolor').click(function(event) {
					$('.custom_color_wrapper').slideToggle();
					event.preventDefault();
				});
			});
		</script>
		<span class="user_prefs_row">
			<h1>Interface Colour</h1>
			<ul class="accent_list">
				<div class="custom_color_wrapper" style="display:none;">
					<input type="text" class="custom_color" style="display:none;">
					<div class="custom_color_btn"></div>
				</div>
				<button class="user_prefs_customcolor" style="width: 240px;margin: 0 3px 5px 0;">Custom Colour</button>
				<li style="background-color:##BD4949;" data-colour="##BD4949"></li>
				<li style="background-color:##48C7A1;" data-colour="##48C7A1"></li>
				<li style="background-color:##35A017;" data-colour="##35A017"></li>
				<li style="background-color:##DA7A1D;" data-colour="##DA7A1D"></li>
				<li style="background-color:##8B43CD;" data-colour="##8B43CD"></li>
				<li style="background-color:##B741BE;" data-colour="##B741BE"></li>
				<li style="background-color:##1776C3;" data-colour="##1776C3"></li>
				<li style="background-color:##494D61;" data-colour="##494D61"></li>
				<li style="background-color:##7CBE35;" data-colour="##7CBE35"></li>
				<li style="background-color:##2C50C2;" data-colour="##2C50C2"></li>
				<li style="background-color:##947EB0;" data-colour="##947EB0"></li>
				<li style="background-color:##930000;" data-colour="##930000"></li>
				<li style="background-color:##5F8158;" data-colour="##5F8158"></li>
				<li style="background-color:##5C7589;" data-colour="##5C7589"></li>
				<li style="background-color:##727CB0;" data-colour="##727CB0"></li>
				<li style="background-color:##FF57BD;" data-colour="##FF57BD"></li>
				<li style="background-color:##F28353;" data-colour="##F28353"></li>
				<li style="background-color:##5094CB;" data-colour="##5094CB"></li>
				<li style="background-color:##323B69;" data-colour="##323B69"></li>
				<li style="background-color:##696D76;" data-colour="##696D76"></li>
				<li style="background-color:##37947F;" data-colour="##37947F"></li>
				<li style="background-color:##B0416B;" data-colour="##B0416B"></li>
				<li style="background-color:##A65858;" data-colour="##A65858"></li>
				<li style="background-color:##333333;" data-colour="##333333"></li>
				<li style="background-color:##16608E;" data-colour="##16608E"></li>
				<li style="background-color:##519D48;" data-colour="##519D48"></li>
				<li style="background-color:##570000;" data-colour="##570000"></li>
				<li style="background-color:##A84600;" data-colour="##A84600"></li>
			</ul>
		</span>
		<span class="user_prefs_row">
			<h1>PIN Number</h1>
			<button class="user_prefs_changePin">Change PIN</button>
		</span>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>