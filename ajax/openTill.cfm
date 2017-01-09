<cftry>
<cfsetting showdebugoutput="no">

<cfoutput>	
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/2.2.0/jquery.min.js"></script>
	<script type='text/javascript' src='#application.site.normal#js/StarWebPrintBuilder.js'></script>
	<script type='text/javascript' src='#application.site.normal#js/StarWebPrintTrader.js'></script>
	
	<script type="text/javascript">
		sendMessage = function(request) {
			var url = "http://#application.printer.ip#:#application.printer.port#/StarWebPRNT/SendMessage";
			var papertype = "normal";
			var blackmark_sensor = "front_side";

			var trader = new StarWebPrintTrader({url:url, papertype:papertype, blackmark_sensor:blackmark_sensor});

			trader.onReceive = function(response) {
				var msg = '- onReceive -\n\n';
				msg += 'TraderSuccess : [ ' + response.traderSuccess + ' ]\n';
				msg += 'TraderStatus : [ ' + response.traderStatus + ',\n';
				if (trader.isCoverOpen({traderStatus:response.traderStatus})) {msg += '\tCoverOpen,\n';}
				if (trader.isOffLine({traderStatus:response.traderStatus})) {msg += '\tOffLine,\n';}
				if (trader.isCompulsionSwitchClose({traderStatus:response.traderStatus})) {msg += '\tCompulsionSwitchClose,\n';}
				if (trader.isEtbCommandExecute({traderStatus:response.traderStatus})) {msg += '\tEtbCommandExecute,\n';}
				if (trader.isHighTemperatureStop({traderStatus:response.traderStatus})) {msg += '\tHighTemperatureStop,\n';}
				if (trader.isNonRecoverableError({traderStatus:response.traderStatus})) {msg += '\tNonRecoverableError,\n';}
				if (trader.isAutoCutterError({traderStatus:response.traderStatus})) {msg += '\tAutoCutterError,\n';}
				if (trader.isBlackMarkError({traderStatus:response.traderStatus})) {msg += '\tBlackMarkError,\n';}
				if (trader.isPaperEnd({traderStatus:response.traderStatus})) {msg += '\tPaperEnd,\n';}
				if (trader.isPaperNearEnd({traderStatus:response.traderStatus})) {msg += '\tPaperNearEnd,\n';}
				msg += '\tEtbCounter = ' + trader.extractionEtbCounter({traderStatus:response.traderStatus}).toString() + ' ]\n';
			}

			trader.onError = function(response) {
				var msg = '- onError -\n\n';
				msg += '\tStatus:' + response.status + '\n';
				msg += '\tResponseText:' + response.responseText;
				console.log(msg);
			}

			trader.sendMessage({request:request});
		}
		
		onSendAscii = function() {
			var builder = new StarWebPrintBuilder();
			var request = '';

			request += builder.createInitializationElement();
			
			var loc = {
				invert: -1,
				count: 0,
				itemCount: 0,
				netTotal: 0,
				paperCharWidth: 48,
				dateNow: '#LSDateFormat(Now(), "dd/mm/yyyy")#',
				timeNow: '#LSTimeFormat(Now(), "HH:mm")#'
			};
			
			var styles = {
				heading: function(a) {
					return {
						characterspace: 0,
						emphasis: true,
						font: "font_a",
						width: 2,
						height: 2,
						data: a,
						linespace: 24,
						binary:true
					};
				},
				bold: function(a) {
					return {
						characterspace: 0,
						emphasis: true,
						font: "font_a",
						width: 1,
						height: 1,
						data: a,
						linespace: 24,
						binary:true
					};
				},
				normal: function(a) {
					return {
						characterspace: 0,
						emphasis: false,
						font: "font_a",
						width: 1,
						height: 1,
						data: a,
						linespace: 24,
						binary:true
					};
				}
			};
			
			//request += builder.createTextElement({data: '#Chr(27)##Chr(112)#011'});
            request += builder.createPeripheralElement({channel:1, on:200, off:200});
			
			sendMessage(request);
		}
		
		window.onload = function() {}
		
		$(document).ready(function(e) {
			onSendAscii();
		});
	</script>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
        output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>