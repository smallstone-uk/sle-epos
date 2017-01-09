<cftry>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfheader name="Access-Control-Allow-Origin" value="http://lweb.shortlanesendstore.co.uk" />

<script src="../scripts/jquery-1.11.1.min.js"></script>
<script src="../scripts/jquery-ui.js"></script>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			zeroPad = function(num, places) {
				var zero = places - num.toString().length + 1;
				return Array(+(zero > 0 && zero)).join("0") + num;
			}
			lenny = function() {
				var timer1 = null;
				var total_ms1 = 0;
				$.ajax({
					type: "GET",
					url: "http://lweb.shortlanesendstore.co.uk/epos2/ajax/returnDataForSpeedTest.cfm",
					beforeSend: function() {
						timer1 = setInterval(function() {
							total_ms1 += 100;
							minutes = (total_ms1 / 1000 / 60) << 0,
							seconds = (total_ms1 / 1000) % 60;
							$('.lenny').html("Timer: " + minutes + ":" + zeroPad(seconds.toFixed(), 2));
						}, 100);
					},
					success: function(data) {
						clearInterval(timer1);
						minutes = (total_ms1 / 1000 / 60) << 0,
						seconds = (total_ms1 / 1000) % 60;
						$('.lenny').html("Timer: " + minutes + ":" + zeroPad(seconds.toFixed(), 2));
					}
				});
			}
			thomas = function() {
				var timer2 = null;
				var total_ms2 = 0;
				$.ajax({
					type: "GET",
					url: "http://tweb.shortlanesendstore.co.uk/epos2/ajax/returnDataForSpeedTest.cfm",
					beforeSend: function() {
						timer2 = setInterval(function() {
							total_ms2 += 100;
							minutes = (total_ms2 / 1000 / 60) << 0,
							seconds = (total_ms2 / 1000) % 60;
							$('.thomas').html("Timer: " + minutes + ":" + zeroPad(seconds.toFixed(), 2));
						}, 100);
					},
					success: function(data) {
						clearInterval(timer2);
						minutes = (total_ms2 / 1000 / 60) << 0,
						seconds = (total_ms2 / 1000) % 60;
						$('.thomas').html("Timer: " + minutes + ":" + zeroPad(seconds.toFixed(), 2));
					}
				});
			}
		});
	</script>
	<button onClick="lenny();thomas();">Start Both</button>
	<br />
	<br />
	<button onClick="lenny();">Lenny</button>&nbsp;&nbsp;<span class="lenny">Request not sent</span>
	<br />
	<br />
	<button onClick="thomas();">Thomas</button>&nbsp;&nbsp;<span class="thomas">Request not sent</span>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>