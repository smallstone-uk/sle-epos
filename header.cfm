<!---28/04/2024--->
<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.userLevel = session.user.eposLevel>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			
			$('.header_exit').click(function(event) {
				$.confirmation("Are you sure you want to exit to the start screen?", function() {
					$.ajax({
						type: "POST",
						url: "ajax/exitToHome.cfm",
						data: {},
						success: function(data) {
							if (data.trim() == "false") {
								sound('error2');
								$.msgBox("You cannot exit during a transaction. Please finish the transaction first.");
							} else {
								$('.content').fadeOut(500, function() {
									$('.content').html("");
								});
			
								$.get("ajax/loadHomeScreen.cfm", function(data) {
									$('.home_screen_content').html(data);
								});
							}
						}

//			$('.header_exit').click(function(event) {
//				$.confirmation("Are you sure you want to exit to the start screen?", function() {
//					$('.content').fadeOut(500, function() {
//						$('.content').html("");
//					});
//
//					$.get("ajax/loadHomeScreen.cfm", function(data) {
//						$('.home_screen_content').html(data);
					});
				});
				event.preventDefault();
			});
			
			$('.header_logout').click(function(event) {
				$.confirmation("Are you sure you want to logout?", function() {
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
				});
				event.preventDefault();
			});
			
			activeTab = function(a) {
				$('.header_tabs li').removeClass("active");
				$(a).addClass("active");
			}
			
			$('.header_tabs li').click(function(event) {
				var obj = $(this);
				var page = obj.data("page");
				
				switch (page)
				{
					case "refund":
						$.confirmation("Are you sure you want to enter refund mode?", function() {
							$.ajax({
								type: "POST",
								url: "ajax/switchMode.cfm",
								data: {"mode": "rfd"},
								success: function(data) {
									if (data.trim() == "true") {
										sound('question');
										$('.backoffice').hide();
										$.loadBasket();
										$.msgBox("You are now in refund mode!");
										activeTab(obj);
										$.ajax({
											type: "GET",
											url: "ajax/getStyleOveride.cfm",
											success: function(data) {
												$('.style_overide').html(data);
											}
										});
									} else {
										sound('error2');
										$.msgBox("You cannot switch modes during a transaction.");
									}
								}
							});
						});
					break;
					case "waste":
						$.confirmation("Are you sure you want to enter waste mode?", function() {
							$.ajax({
								type: "POST",
								url: "ajax/switchMode.cfm",
								data: {"mode": "wst"},
								success: function(data) {
									if (data.trim() == "true") {
										sound('question');
										$('.backoffice').hide();
										$.loadBasket();
										$.msgBox("You are now in waste mode!");
										activeTab(obj);
										$.ajax({
											type: "GET",
											url: "ajax/getStyleOveride.cfm",
											success: function(data) {
												$('.style_overide').html(data);
											}
										});
									} else {
										sound('error2');
										$.msgBox("You cannot switch modes during a transaction.");
									}
								}
							});
						});
					break;
					case "register":
						$.ajax({
							type: "POST",
							url: "ajax/switchMode.cfm",
							data: {"mode": "reg"},
							success: function(data) {
								if (data.trim() == "true") {
									sound('added');
									$('.backoffice').hide();
									$.loadBasket();
									$.msgBox("You are now in register mode!");
									activeTab(obj);
									$.ajax({
										type: "GET",
										url: "ajax/getStyleOveride.cfm",
										success: function(data) {
											$('.style_overide').html(data);
										}
									});
								} else {
									sound('error2');
									$.msgBox("You cannot switch modes during a transaction.");
								}
							}
						});
					break;
					case "staff":
						$.ajax({
							type: "POST",
							url: "ajax/switchStaff.cfm",
							data: {"bool": true},
							success: function(data) {
								if (data.trim() == "YES") {
									sound('question');
									$('.backoffice').hide();
									$.loadBasket();
									$.msgBox("You are now in staff mode!");
									activeTab(obj);
								} else {
									sound('question');
									$('.backoffice').hide();
									$.loadBasket();
									$.msgBox("Staff mode cancelled");
									activeTab(obj);									
								}
							}
						});
					break;
				}
			});
			
			$('.header_time').currentTime();
			
			$('.header_user').click(function(event) {
				var obj = $(this);
				var offsetRight = $(window).innerWidth() - (obj.offset().left + obj.outerWidth());
				$.ajax({
					type: "GET",
					url: "ajax/loadUserPrefs.cfm",
					success: function(data) {
						$('.content').prepend(data);
						
						$('.user_prefs').css({
							"right": offsetRight,
							"top": "75px"
						});
						
						obj.css("background-color", "##444 !important");
					}
				});
				event.preventDefault();
			});

			$('##hti_home').click(function(event) {
				$.ajax({
					type: "GET",
					url: "ajax/loadHome.cfm",
					success: function(data) {
						$('.categories_viewer').html(data);
					}
				});

				event.preventDefault();
			});

			$('##hti_manualcats').click(function(event) {
				$.ajax({
				    type: 'POST',
				    url: 'ajax/loadManualCategories.cfm',
				    data: {},
				    success: function(data) {
				    	$('.categories_viewer').html(data);
				    }
				});

				event.preventDefault();
			});

			$('##hti_search').click(function(event) {
				$.virtualKeyboard({
					callback: function(value) {
						if (value.length > 0) {
							$.ajax({
								type: "POST",
								url: "ajax/productPostSearchForm.cfm",
								data: {"title": value},
								success: function(data) {
									$('.categories_viewer').html(data);
								}
							});
						}
					}
				});

				event.preventDefault();
			});

			$('##hti_reload').click(function(event) {
				window.location.reload();
				event.preventDefault();
			});

			$('##hti_nokiosk').click(function(event) {
				window.open('#application.site.normal#', '_blank');
				window.location.href = 'http://closekiosk';
				event.preventDefault();
			});
		});
	</script>
	<cfif session.user.loggedin>
    	<cfset minAgeDate = DateAdd("yyyy",-18,Now())>
		<div class="header_brand">
			<span class="header_brand_title">
				<strong>#application.company.name#</strong>
				#LSDateFormat(Now(), "ddd dd mmm yyyy")#&nbsp;&nbsp;
				<span class="header_time">#LSTimeFormat(Now(), "HH:mm")#</span>
                <p>
					<span class="age_check">18 Age-check &nbsp; #DateFormat(minAgeDate,'dd mm yyyy')#</span>
					<span id="idleCounter">#application.settings.idleTimeout#</span>
				</p>
			</span>
		</div>
		<div class="header_toolbar">
			<ul class="header_tabs">
				<li <cfif session.basket.info.mode eq "reg">class="active"</cfif> data-page="register" data-mode="reg">Register</li>
				<li <cfif session.basket.info.mode eq "rfd">class="active"</cfif> data-page="refund" data-mode="rfd">Refund</li>
				<li <cfif session.basket.info.mode eq "wst">class="active"</cfif> data-page="waste" data-mode="wst">Waste</li>
				<li <cfif session.till.info.staff>class="active"</cfif> data-page="staff" data-mode="staff">Staff</li>
				<!---<li data-page="help">Help</li>--->
			</ul>
			<ul class="header_icons">
				<li id="hti_reload" class="material-ripple" style="font-size: 26px;"><i class="fa fa-refresh" title="refresh page"></i></li>
				<li id="hti_home" class="material-ripple"><i class="fa fa-home"style="font-size: 26px;" title="view the home page"></i></li>
				<li id="hti_search" class="material-ripple" style="font-size: 26px;" title="search for a product"><i class="fa fa-search"></i></li>
				<li id="hti_manualcats" class="material-ripple" style="font-size: 26px;" title="manual categories"><i class="fa fa-list"></i></li>
			</ul>
		</div>
		<div class="header_note_holder">
			<cfinclude template="ajax/loadHeaderNote.cfm">
		</div>
		<ul class="header_controls">
			<!--- <li>
				<a href="javascript:void(0)" class="header_logout">
					<span class="fa fa-logout"></span>
					<span>Logout</span>
				</a>
			</li> --->
			<li>
				<a href="javascript:void(0)" class="header_exit material-ripple">
					<span class="fa fa-sign-out"></span>
				</a>
			</li>
			<li class="emp_ref">
				#session.user.prefs.empFirstName# #Left(session.user.prefs.empLastName, 1)#
			</li>
		</ul>
		<!---<a href="javascript:void(0)" class="header_logout">Logout</a>
		<a href="javascript:void(0)" class="header_exit">Exit to Home</a>
		<div class="header_user">
			#session.user.firstName# #Left(session.user.lastName, 1)#
			<div class="cog"></div>
		</div>--->
	</cfif>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
		output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
	<cfdump var="#session#" label="session" expand="yes" format="html" 
		output="#application.site.dir_logs#epos\sess-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>