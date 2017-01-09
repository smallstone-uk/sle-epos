<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.userID = session.user.id>
<cfset userPrefs = epos.LoadUserPreferences(parm)>
	
<cfdirectory
	directory = "#application.site.basedir#images\wallpapers\thumbs"
    action = "list"
    listInfo = "all"
    name = "bgList"
    recurse = "no"
    sort = "datelastmodified DESC"
    type = "all">

<cfoutput>
	<script>
		$(document).ready(function(e) {
			var allowClick = true;
			var #ToScript(userPrefs, "user")#;
			
			$('.user_prefs').htmlRemove(function(target) {
				if (!target.is($('.user_prefs')) && !target.is($('.user_prefs').find('*'))) {
					$('.header_user').css("background-color", "");
				}
			});
			
			$('.accent_list li[style="background-color:' + user.empaccent + ';"]').addClass("accent_ticked");
			$('.bg_list li[data-bg="' + user.empbackground + '"]').addClass("bg_ticked");
			
			$('.accent_list li').click(function(event) {
				var obj = $(this);
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
								$('.accent_list li').removeClass("accent_ticked");
								obj.addClass("accent_ticked");
							}
						});
					}
				});
			});
			
			$('.upf_changePin').click(function(event) {
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
			
			<!---$('.custom_color_btn').farbtastic(function(colour) {
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
			
			$('.upf_customcolor').click(function(event) {
				$('.custom_color_wrapper').slideToggle();
				event.preventDefault();
			});--->
			
			/*$('.apptab').click(function(event) {
				$('.apptab').removeClass("apptab_active");
				$(this).addClass("apptab_active");
				$('.tabpage').removeClass("tabpage_open");
				$('.tabpage[data-page="' + $(this).data("tab") + '"]').addClass("tabpage_open");
				event.preventDefault();
			});*/
			
			$('.bg_list li').click(function(event) {
				if (allowClick) {
					var bg = $(this).data("bg");
					
					$('.bg_list li').removeClass("bg_ticked");
					$(this).addClass("bg_ticked");
					
					$.ajax({
						type: "POST",
						url: "ajax/apps/fn/post_changeBackground.cfm",
						data: {"bg": bg},
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
				}
				event.preventDefault();
			});
			
			$('.bg_list').kinetic({
				cursor: "default",
				x: false,
				y: true,
				moved: function(settings) { allowClick = false; },
				stopped: function(settings) { allowClick = true; }
			});
			
			$('.upf_autologout').bigSelect(function(value) {
				$.ajax({
					type: "POST",
					url: "ajax/apps/fn/post_autoLogout.cfm",
					data: {"value_ms": value}
				});
			});
			
			$('.apptab').click(function(event) {
				$('div[role="page"]').removeClass("in out").fadeOut();
				$( $(this).attr("href") ).hide().addClass("slide in").fadeIn();
				$('.apptab').removeClass("apptab_active");
				$(this).addClass("apptab_active");
				event.preventDefault();
			});
			
			$('.upf_changeTut').touchCheckbox(function(isChecked) {
				if (isChecked) $.ajax({ type: "GET", url: "ajax/enableEPOSTutorial.cfm" });
				else $.ajax({ type: "GET", url: "ajax/disableEPOSTutorial.cfm" });
			});
			
			$('.upf_launchtill').touchCheckbox(function(isChecked) {
				if (isChecked) $.ajax({ type: "GET", url: "ajax/enableEPOSLaunchTill.cfm" });
				else $.ajax({ type: "GET", url: "ajax/disableEPOSLaunchTill.cfm" });
			});
			
			$('.timeout').bigSelect();
		});
	</script>
	<ul class="tablist">
		<li><a href="##interface" class="apptab apptab_active">interface</a></li>
		<li><a href="##background" class="apptab">background</a></li>
		<li><a href="##settings" class="apptab">settings</a></li>
	</ul>
	<div role="page" id="interface" class="slide in">
		<table border="0" class="header-align-right">
			<!---<tr>
				<td>
					<div class="custom_color_wrapper" style="display:none;">
						<input type="text" class="custom_color" style="display:none;">
						<div class="custom_color_btn"></div>
					</div>
					<button class="appbtn upf_customcolor" style="float:left;">Custom Colour</button>
				</td>
			</tr>--->
			<tr>
				<td class="accent_list">
					<li class="scalebtn" style="background-color:##BD4949;" data-colour="##BD4949"></li>
					<li class="scalebtn" style="background-color:##48C7A1;" data-colour="##48C7A1"></li>
					<li class="scalebtn" style="background-color:##35A017;" data-colour="##35A017"></li>
					<li class="scalebtn" style="background-color:##DA7A1D;" data-colour="##DA7A1D"></li>
					<li class="scalebtn" style="background-color:##8B43CD;" data-colour="##8B43CD"></li>
					<li class="scalebtn" style="background-color:##B741BE;" data-colour="##B741BE"></li>
					<li class="scalebtn" style="background-color:##1776C3;" data-colour="##1776C3"></li>
					<li class="scalebtn" style="background-color:##494D61;" data-colour="##494D61"></li>
					<li class="scalebtn" style="background-color:##7CBE35;" data-colour="##7CBE35"></li>
					<li class="scalebtn" style="background-color:##2C50C2;" data-colour="##2C50C2"></li>
					<li class="scalebtn" style="background-color:##947EB0;" data-colour="##947EB0"></li>
					<li class="scalebtn" style="background-color:##930000;" data-colour="##930000"></li>
					<li class="scalebtn" style="background-color:##5F8158;" data-colour="##5F8158"></li>
					<li class="scalebtn" style="background-color:##5C7589;" data-colour="##5C7589"></li>
					<li class="scalebtn" style="background-color:##727CB0;" data-colour="##727CB0"></li>
					<li class="scalebtn" style="background-color:##FF57BD;" data-colour="##FF57BD"></li>
					<li class="scalebtn" style="background-color:##F28353;" data-colour="##F28353"></li>
					<li class="scalebtn" style="background-color:##5094CB;" data-colour="##5094CB"></li>
					<li class="scalebtn" style="background-color:##323B69;" data-colour="##323B69"></li>
					<li class="scalebtn" style="background-color:##696D76;" data-colour="##696D76"></li>
					<li class="scalebtn" style="background-color:##37947F;" data-colour="##37947F"></li>
					<li class="scalebtn" style="background-color:##B0416B;" data-colour="##B0416B"></li>
					<li class="scalebtn" style="background-color:##A65858;" data-colour="##A65858"></li>
					<li class="scalebtn" style="background-color:##333333;" data-colour="##333333"></li>
					<li class="scalebtn" style="background-color:##16608E;" data-colour="##16608E"></li>
					<li class="scalebtn" style="background-color:##519D48;" data-colour="##519D48"></li>
					<li class="scalebtn" style="background-color:##570000;" data-colour="##570000"></li>
					<li class="scalebtn" style="background-color:##A84600;" data-colour="##A84600"></li>
				</td>
			</tr>
		</table>
	</div>
	<div role="page" id="background">
		<table border="0" class="header-align-right">
			<tr>
				<td class="bg_list">
					<cfloop query="bgList">
						<li style="background-image:url( #application.site.normal#images/wallpapers/thumbs/#name# );"
							data-path="#application.site.normal#images/wallpapers/#name#"
							data-bg="#name#"
							class="scalebtn"></li>
					</cfloop>
				</td>
			</tr>
		</table>
	</div>
	<div role="page" id="settings">
		<table border="0" class="header-align-right">
			<tr>
				<th>PIN Number</th>
				<td><button class="appbtn upf_changePin" style="float:left;">Change PIN</button></td>
			</tr>
			<tr>
				<th>Show Tutorial Prompt</th>
				<td><input type="checkbox" class="appbtn upf_changeTut" style="float:right;" <cfif userPrefs.empepostutorial is 0>checked="checked"</cfif>></td>
			</tr>
			<tr>
				<th>Launch Till On Login</th>
				<td><input type="checkbox" class="appbtn upf_launchtill" style="float:right;" <cfif userPrefs.empEPOSLaunchTill eq "Yes">checked="checked"</cfif>></td>
			</tr>
			<tr>
				<th>Screensaver Timeout</th>
				<td>
					<select name="timeout" class="timeout">
						<option <cfif userPrefs.empEPOSTimeout is 300000>selected="selected"</cfif> value="300000">5 Minutes</option>
						<option <cfif userPrefs.empEPOSTimeout is 600000>selected="selected"</cfif> value="600000">10 Minutes</option>
						<option <cfif userPrefs.empEPOSTimeout is 900000>selected="selected"</cfif> value="900000">15 Minutes</option>
						<option <cfif userPrefs.empEPOSTimeout is 1800000>selected="selected"</cfif> value="1800000">30 Minutes</option>
						<option <cfif userPrefs.empEPOSTimeout is 0>selected="selected"</cfif> value="0">Never</option>
					</select>
				</td>
			</tr>
			<!---<tr>
				<th>Auto Logout</th>
				<td>
					<!---<select class="upf_autologout">
						<option value="300000" <cfif userPrefs.empAutoLogout is 300000>selected="true"</cfif>>5 Minutes</option>
						<option value="600000" <cfif userPrefs.empAutoLogout is 600000>selected="true"</cfif>>10 Minutes</option>
						<option value="900000" <cfif userPrefs.empAutoLogout is 900000>selected="true"</cfif>>15 Minutes</option>
						<option value="1800000" <cfif userPrefs.empAutoLogout is 1800000>selected="true"</cfif>>30 Minutes</option>
						<option value="0" <cfif userPrefs.empAutoLogout is 0>selected="true"</cfif>>Never</option>
					</select>--->
					<select class="upf_autologout">
						<option value="5000" <cfif userPrefs.empAutoLogout is 5000>selected="true"</cfif>>5 Seconds</option>
						<option value="10000" <cfif userPrefs.empAutoLogout is 10000>selected="true"</cfif>>10 Seconds</option>
						<option value="0" <cfif userPrefs.empAutoLogout is 0>selected="true"</cfif>>Never</option>
					</select>
				</td>
			</tr>--->
		</table>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>