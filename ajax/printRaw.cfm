<cftry>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.content = content>

<cfoutput>
	<script type="text/javascript" src="#parm.url#js/deployJava.js"></script>
	<script>
		function qzReady() {
			window["qz"] = document.getElementById('qz');
			if (qz) {
				try {} catch(err) {
					alert("ERROR:  \nThe applet did not load correctly.  Communication to the " + 
					"applet has failed, likely caused by Java Security Settings.  \n\n" + 
					"CAUSE:  \nJava 7 update 25 and higher block LiveConnect calls " + 
					"once Oracle has marked that version as outdated, which " + 
					"is likely the cause.  \n\nSOLUTION:  \n  1. Update Java to the latest " + 
					"Java version \n          (or)\n  2. Lower the security " + 
					"settings from the Java Control Panel.");
				}
			}
		}
		function notReady() {
			if (!isLoaded()) {
				return true;
			} else if (!qz.getPrinter()) {
				alert('Please select a printer first by using the "Detect Printer" button.');
				return true;
			}
			return false;
		}
		function isLoaded() {
			if (!qz) {
				alert('Error:\n\n\tPrint plugin is NOT loaded!');
				return false;
			} else {
				try {
					if (!qz.isActive()) {
						alert('Error:\n\n\tPrint plugin is loaded but NOT active!');
						return false;
					}
				} catch (err) {
					alert('Error:\n\n\tPrint plugin is NOT loaded properly!');
					return false;
				}
			}
			return true;
		}
		function qzDonePrinting() {
			if (qz.getException()) {
				alert('Error printing:\n\n\t' + qz.getException().getLocalizedMessage());
				qz.clearException();
				return; 
			}
			alert('Successfully sent print data to "' + qz.getPrinter() + '" queue.');
		}
		function findPrinter(name) {
			var printername = "zebra";
			if (isLoaded()) {
				qz.findPrinter(printername);
				window['qzDoneFinding'] = function() {
					var printer = qz.getPrinter();
					alert(printer !== null ? 'Printer found: "' + printer + 
					'" after searching for "' + printername + '"' : 'Printer "' + 
					printername + '" not found.');
					window['qzDoneFinding'] = null;
				}
			}
		}
		function printEPL() {
			if (notReady()) { return; }
				qz.append('#parm.content#');            
				window['qzDoneAppending'] = function() {
					qz.append('\nP1,1\n');
					qz.print();
					window['qzDoneAppending'] = null;
				}
		}
		function getPath() {
			var path = window.location.href;
			return path.substring(0, path.lastIndexOf("/")) + "/";
		}
		
		findPrinter();
		printEPL();
	</script>
	<applet id="qz" archive="./qz-print.jar" name="QZ Print Plugin" code="qz.PrintApplet.class" width="55" height="55">
		<param name="jnlp_href" value="qz-print_jnlp.jnlp">
		<param name="cache_option" value="plugin">
		<param name="disable_logging" value="false">
		<param name="initial_focus" value="false">
	</applet>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>