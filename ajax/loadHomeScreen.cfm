<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset employees = epos.LoadEmployees()>
<cfset apps = epos.LoadApps()>
<cfset alerts = epos.LoadAlerts()>
<!---<cfset epos.LoadDealsIntoSession()>--->
<cfset freshLogin = ( IsDefined("freshLogin") ) ? freshLogin : false>

<cfoutput>
	<!---<script src="js/jquery-1.11.1.min.js"></script>
	<script src="js/tiles.js"></script>--->
	<script>
		$(document).ready(function(e) {
			$(document).unbind("keypress.scanBarcodeEvent");
			
			$.tiles();
			
			// Debug
			/*$('li[data-page-title="Product Manager"]').click();
			setTimeout(function() {
				$('.MethodSelectForm').fadeOut(function() {
					$('.ExistingProductForm').fadeIn(function() {
						$('.epf_method_category').click();
						$('.epf_cat_item[data-value="2"]').click();
						$.ajax({
							type: "POST",
							url: "ajax/apps/fn/get_editProduct.cfm",
							data: {"prodID": 26912},
							success: function(data) {
								$.sidepanel(data, 900);
							}
						});
					});
				});
			}, 250);*/
			
			<!---loadJSONAlerts = function() {
				$.ajax({
					type: "GET",
					url: "ajax/apps/fn/get_jsonAlerts.cfm",
					success: function(data) {
						window.epos_frame.alerts = JSON.parse(data);
						window.epos_frame.handleAlerts();
					}
				});
			}
			
			loadJSONAlerts();--->
			
			<cfif StructKeyExists(session.user.prefs, "empEPOSLaunchTill")>
				if ("#freshLogin#".toString() == "true") {
					setTimeout(function() {
						var loggedin = "#session.user.loggedin#";
						if (loggedin.trim() == "true" || loggedin.trim() == "TRUE") {
							var empTill = "#session.user.prefs.empEPOSLaunchTill#";
							if (empTill.trim().toLowerCase() == "yes") {
								launchTill();
							}
						}
					}, 1000);
				}
			</cfif>
			
			userLogin = function(employee) {
				$.virtualNumpad({
					autolength: 4,
					wholenumber: true,
					secret: true,
					callback: function(pin, methods) {
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
									$.ajax({
										type: "POST",
										url: "ajax/loadHomeScreen.cfm",
										data: {"freshLogin": true},
										success: function(data) {
											$('.home_screen_content').html(data);
										}
									});
								}
							}
						});
					}
				});
			}
			
			$('.suc_settings').click(function(event) {
				event.preventDefault();
			});
			
			$('.suc_profile').click(function(event) {
				var obj = $(this);
				$.ajax({
					type: "GET",
					url: "ajax/loadUserProfile.cfm",
					success: function(data) {
						obj.after(data);
						$('.user_profile').show();
					}
				});
				event.preventDefault();
			});
			
			launchTill = function() {
				fadeDashBoard();
				
				$('.epos-till-page')
					.addClass('slidePageInFromLeft')
					.removeClass('slidePageBackLeft')
					.show(function() {
						$.get("till.cfm", function(data) {
							window.epos_frame.isStockControl = false;
							setTimeout(function() {
								$('.content').html(data).show();
								$('.demo-wrapper').addClass("exitUp");
								setTimeout(function() {
									$('.demo-wrapper').removeClass("exitUp");
								}, 1500);
							}, 1500);
						});
					});
			}
			
			<!---$('.suc_alerts').click(function(event) {
				$.ajax({
					type: "GET",
					url: "ajax/loadAlerts.cfm",
					success: function(data) {
						$.sidepanel(data, 480, "left", false);
					}
				});
				event.preventDefault();
			});--->
			
			$('.sh_time').currentTime();
			
			<cfif StructKeyExists(session.user.prefs, "empEPOSTutorial")>
				if ("#session.user.loggedin#" == "true") {
					setTimeout(function() {
						if ("#session.user.prefs.empEPOSTutorial#" == "0") {
							$.confirmation("Would you like to take the tour?", function() {
								INTRO.init();
							}, function() {
								$.ajax({
									type: "GET",
									url: "ajax/disableEPOSTutorial.cfm"
								});
							});
						}
					}, 1500);
				}
			</cfif>
		});
	</script>
	<div class="style_overide"><cfinclude template="getStyleOveride.cfm"></div>
	<div class="content" style="display:none;"></div>
	<div class="demo-wrapper">
		<div class="s-page epos-till-page" style="color:##FFF !important;">
			<div class="icon-cart vam"></div>
		</div>
		<div class="s-page template-page">
			<link href="css/sandbox.css?a=#RandRange(102030, 908070, 'SHA1PRNG')#" rel="stylesheet" type="text/css">
			<h2 class="page-title"></h2>
			<div class="scalebtn close-button s-close-button">x</div>
			<div class="app-content"></div>
		</div>
		<div class="dashboard clearfix">
			<ul class="tiles">
				<div class="startheader">
					<span class="sh_time scalebtn">#LSTimeFormat(Now(), "HH:mm")#</span>
					<span class="sh_date scalebtn" style=" font-size:28px;">#LSDateFormat(Now(), "dd mmmm yyyy")#</span>
				</div>
				<div class="startusercontrols">
					<cfif session.user.loggedin>
						<!---<span class="scalebtn suc_alerts icon-earth <cfif ArrayLen(alerts) gt 0>suc_alerts_active</cfif>"></span>--->
						<span class="scalebtn suc_profile">#session.user.firstname# #left(session.user.lastname, 1)#</span>
						<span
							class="scalebtn suc_settings icon-cog tile"
							data-page-type="s-page"
							data-page-name="template-page"
							data-page-title="User Preferences"
							data-file="#parm.url#ajax/apps/userPreferences.cfm"
						></span>
					<cfelse>
						No one's logged in
					</cfif>
					<div class="tiny">#application.site.datasource1#</div>
				</div>
				<div class="col3 clearfix">
					<div class="colheader">Users</div>
					<cfloop array="#employees#" index="item">
						<li
							class="scalebtn tile tile-small last tile-5 <cfif item.empID is session.user.id>loggedInTile</cfif>"
							onClick="userLogin(#item.empID#);"
							data-page-type="s-page"
							data-page-name="epos-main-page"
							style="background-color:#item.empAccent#;color:##FFF;<cfif item.empID is session.user.id>border: 5px solid white;</cfif>">
							<div><p><span class="icon-user"></span>#item.empFirstName# #Left(item.empLastName, 1)#</p></div>
						</li>
					</cfloop>
				</div>
				<cfif session.user.loggedin>
					<cfif !ArrayIsEmpty(apps)>
						<div class="spacer"></div>
						<div class="col3 clearfix">
							<div class="colheader">Apps</div>
							<cfloop array="#apps#" index="item">
								<li
									class="scalebtn tile last tile-#item.appSize# tile-#item.appType# slideText#item.appAnimation#"
									data-page-type="s-page"
									data-page-name="template-page"
									data-page-title="#item.appFront#"
									<cfif Len(item.appOnClick)>onClick="#item.appOnClick#"</cfif>
									<cfif Len(item.appFile)>data-file="#parm.url#ajax/apps/#item.appFile#"</cfif>
								>
									<div><p>#item.appFront#</p></div>
									<div><p>#item.appBack#</p></div>
								</li>
							</cfloop>
						</div>
					</cfif>
				</cfif>
			</ul>
		</div>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfset writeDumpToFile(cfcatch)>
</cfcatch>
</cftry>