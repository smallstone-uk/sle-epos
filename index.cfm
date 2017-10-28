<cftry>

<!---<cfabort>--->

<!DOCTYPE html>
<html>
<head>
<title>EPOS</title>
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<script src="js/jquery-1.11.1.min.js"></script>

<!--QZ Print Applet-->
<!---<script type="text/javascript" src="js/3rdparty/deployJava.js"></script>--->
<script type="text/javascript" src="js/3rdparty/jquery-1.10.2.js"></script>
<!---<script type="text/javascript" src="js/qz-websocket.js"></script>--->

<cfoutput>
	<!--Core Styles-->
	<cfset randNum = RandRange(102030, 908070, 'SHA1PRNG')>
	<link href="css/jquery-ui.css" rel="stylesheet" type="text/css">
	<link href="css/jquery.mobile.css" rel="stylesheet" type="text/css">
	<link href="css/epos.css" rel="stylesheet" type="text/css">
	<link href="css/grid.css" rel="stylesheet" type="text/css">
	<link href="css/virtualInput.css" rel="stylesheet" type="text/css">
	<link href="css/sections.css" rel="stylesheet" type="text/css">
	<!---<link href="css/sandbox.css" rel="stylesheet" type="text/css">--->
	<link href="css/demo-styles.css" rel="stylesheet" type="text/css">
	<link href="css/farbtastic.css" rel="stylesheet" type="text/css">
	<link href="css/touchCheckbox.css" rel="stylesheet" type="text/css">
	<link href="css/bigSelect.css" rel="stylesheet" type="text/css">
	<link href="icomoon/style.css" rel="stylesheet" type="text/css">
	<link href="css/ripple.min.css" rel="stylesheet" type="text/css">

	<!--Core Scripts-->
	<!---<script src="js/blockContext.js"></script>--->
	<script src="js/jquery-ui.js"></script>
	<script src="js/jquery.mobile.js"></script>
	<script src="js/mousestop.min.js"></script>
	<script src="js/jquery-barcode.js"></script>
	<script src="js/tiles.js"></script>
	<script src="js/epos.js"></script>
	<script src="js/virtualInput.js"></script>
	<script src="js/sections.js"></script>
	<script src="js/farbtastic.js"></script>
	<script src="js/touchCheckbox.js"></script>
	<script src="js/bigSelect.js"></script>
	<script src="js/touchSelect.js"></script>
	<script src="js/jquery.kinetic.min.js"></script>
	<script src="js/jquery.backstretch.min.js"></script>
	<script src="js/jquery.touchSwipe.js"></script>
	<script src="js/jquery.zoomooz.min.js"></script>
	<script src="js/intro.js"></script>
	<script src="js/vue.js"></script>
	<script src="js/vue-resource.js"></script>
	<!--- <script src="js/ripple.min.js"></script> --->
	<script src="https://use.fontawesome.com/d9f3e22a05.js"></script>

	<!--- Include all product group event scripts --->
	<script>window.events = {};</script>
	<cfset usedEvents = []>
	<cfloop array="#new App.ProductGroup().all()#" index="pGroup">
		<cfif FileExists("#getBaseDir('Events/#pGroup.pgClassname#.js')#") AND NOT arrayContains(usedEvents, pGroup.pgClassname)>
			<script src="Events/#pGroup.pgClassname#.js"></script>
			<script>
				window.events.#lCase(pGroup.pgClassname)# = new #pGroup.pgClassname#();
			</script>
			<cfset arrayAppend(usedEvents, pGroup.pgClassname)>
		</cfif>
	</cfloop>
	</head>

	<cfobject component="code/epos" name="epos">
	<!---<cfobject component="code/epos2" name="epos2">--->
	<cfset parm = {}>
	<cfset parm.datasource = application.site.datasource1>
	<cfset parm.url = application.site.normal>
	<!---<cfset epos.LoadDealsIntoSession()>--->
	<cfset employees = epos.LoadEmployees()>

	<body id="qz-status">
		<!---<cfinclude template="qzScripts.cfm">--->
		<script>
			$(document).ready(function(e) {
				$.get("ajax/loadHomeScreen.cfm", function(data) {
					$('.home_screen_content').html(data);
					$('*').addClass("disable-select");
				});

				<cfif StructKeyExists(session.user.prefs, "empBackground")>
					var loggedin = "#session.user.loggedin#";
					if (loggedin.trim().toLowerCase() == "true") {
						var screensaver = null, timeout = 900000, isOpen = false;

						requeue = function() {
							screensaver = setTimeout(function() {
								isOpen = true;

								$('body').prepend(
									'<div class="ss_wrapper anim_slidein in">'+
										'<div class="screensaver_dim"></div>'+
										'<span class="ss_time">#LSTimeFormat(Now(), "HH:mm")#</span>'+
										'<span class="ss_date">#LSDateFormat(Now(), "d mmm yyyy")#</span>'+
										'<div class="screensaver" style="background-image:url(../images/wallpapers/#session.user.prefs.empBackground#);"></div>'+
									'</div>'
								);

								$('.ss_time').currentTime();
							}, timeout);
						}

						$(document).bind("mousemove", function(event) {
							clearTimeout(screensaver);
							if (!isOpen) requeue();
						});

						$(document).bind("mousedown", function(event) {
							clearTimeout(screensaver);
							$('.ss_wrapper').removeClass("anim_slidein").addClass("anim_slideout");
							setTimeout(function() { $('.ss_wrapper').remove(); }, 1000);
							isOpen = false;
							requeue();
						});
					}
				</cfif>
			});
		</script>
		<span id="version"></span>
		<input id="printer" type="text" value="zebra" size="15" style="display:none;">
		<cfinclude template="datePicker2.cfm">
		<div class="hidden"></div>
		<div class="printable"></div>
		<div class="home_screen_content"></div>
	</body>
</cfoutput>
</html>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>
