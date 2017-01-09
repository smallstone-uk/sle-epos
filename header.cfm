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
					$('.content').fadeOut(500, function() {
						$('.content').html("");
					});

					$.get("ajax/loadHomeScreen.cfm", function(data) {
						$('.home_screen_content').html(data);
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
									$('.backoffice').hide();
									$.loadBasket();
									$.msgBox("You are now in staff mode!");
									activeTab(obj);
								} else {
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
		});
	</script>
	<cfif session.user.loggedin>
		<div class="header_brand">
			<span class="header_brand_title">
				<strong>#application.company.name#</strong><br />
				#LSDateFormat(Now(), "ddd dd mmm yyyy")#&nbsp;&nbsp;
				<span class="header_time">#LSTimeFormat(Now(), "HH:mm")#</span>
			</span>
		</div>
		<div class="header_toolbar">
			<ul class="header_tabs">
				<li <cfif session.basket.info.mode eq "reg">class="active"</cfif> data-page="register" data-mode="reg">Register</li>
				<li <cfif session.basket.info.mode eq "rfd">class="active"</cfif> data-page="refund" data-mode="rfd">Refund</li>
				<li <cfif session.till.info.staff>class="active"</cfif> data-page="staff" data-mode="staff">Staff</li>
				<!---<li data-page="help">Help</li>--->
			</ul>
			<ul class="header_icons">
				<li id="hti_home" class="material-ripple"><i class="fa fa-home"></i></li>
				<li id="hti_search" class="material-ripple" style="font-size: 32px;"><i class="fa fa-search"></i></li>
				<li id="hti_manualcats" class="material-ripple" style="font-size: 32px;"><i class="fa fa-list"></i></li>
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
</cfcatch>
</cftry>