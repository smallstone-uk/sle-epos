<cftry>
<cfsetting showdebugoutput="no">
<cfobject component="#application.site.codePath#" name="e">
<cfset parm = {}>

<cfoutput>
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/2.2.0/jquery.min.js"></script>
	<script type='text/javascript' src='#getUrl("js/StarWebPrintBuilder.js")#'></script>
	<script type='text/javascript' src='#getUrl("js/StarWebPrintTrader.js")#'></script>
	
	<script type="text/javascript">
		nf = function(a, b) {
			if (typeof a != "undefined") {
				var d = (a.length <= 0) ? 0 : (a.toString().match(/[^+\-,."'\d]/gi) != null) ? a.toString().replace(/[^+\-,."'\d]/gi, "") : a;
				var dStr = d.toString();
				numberWithCommas = function(c) {
					var parts = c.toString().split(".");
					parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
					return parts.join(".");
				}
				var result = {
					num: parseFloat((d.toString()).replace(/,/g, "")),
					str: numberWithCommas((parseFloat((d.toString()).replace(/,/g, ""))).toFixed(2)),
					abs: Math.abs(parseFloat((d.toString()).replace(/,/g, "")).toFixed(2)),
					abs_num: Math.abs(parseFloat((d.toString()).replace(/,/g, "")).toFixed(2)),
					abs_str: numberWithCommas(Math.abs(parseFloat((d.toString()).replace(/,/g, ""))).toFixed(2))
				};
				switch (b) {
					case "abs_num":	return result.abs_num;	break;
					case "abs_str":	return result.abs_str;	break;
					case "num":		return result.num;		break;
					case "str":		return result.str;		break;
					case "all":		return result;			break;
					default:		return result.str;		break;
				}
			}
		}
		
		sendMessage = function(request) {
			var url = "http://#application.printer.ip#:#application.printer.port#/StarWebPRNT/SendMessage";
			var papertype = "normal";
			var blackmark_sensor = "front_side";

			var trader = new StarWebPrintTrader({url:url, papertype:papertype, blackmark_sensor:blackmark_sensor});

			trader.onReceive = function(response) {
				var msg = '- onReceive -\n\n';
				msg += 'TraderSuccess : [ ' + response.traderSuccess + ' ]\n';
				msg += 'TraderStatus : [ ' + response.traderStatus + ',\n';
				if (trader.isCoverOpen            ({traderStatus:response.traderStatus})) {msg += '\tCoverOpen,\n';}
				if (trader.isOffLine              ({traderStatus:response.traderStatus})) {msg += '\tOffLine,\n';}
				if (trader.isCompulsionSwitchClose({traderStatus:response.traderStatus})) {msg += '\tCompulsionSwitchClose,\n';}
				if (trader.isEtbCommandExecute    ({traderStatus:response.traderStatus})) {msg += '\tEtbCommandExecute,\n';}
				if (trader.isHighTemperatureStop  ({traderStatus:response.traderStatus})) {msg += '\tHighTemperatureStop,\n';}
				if (trader.isNonRecoverableError  ({traderStatus:response.traderStatus})) {msg += '\tNonRecoverableError,\n';}
				if (trader.isAutoCutterError      ({traderStatus:response.traderStatus})) {msg += '\tAutoCutterError,\n';}
				if (trader.isBlackMarkError       ({traderStatus:response.traderStatus})) {msg += '\tBlackMarkError,\n';}
				if (trader.isPaperEnd             ({traderStatus:response.traderStatus})) {msg += '\tPaperEnd,\n';}
				if (trader.isPaperNearEnd         ({traderStatus:response.traderStatus})) {msg += '\tPaperNearEnd,\n';}
				msg += '\tEtbCounter = ' + trader.extractionEtbCounter({traderStatus:response.traderStatus}).toString() + ' ]\n';
				console.log(msg);
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
			
			var styles = {	//"cp857",
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
					//	codepage: "cp437",
					//	international: "uk"
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
				//		codepage: "cp437",
				//		international: "uk"
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
					//	codepage: "cp1252",
					//	international: "uk"
					};
				}
			};
			
			var align = {
				lr: function(a, b) {
                    console.log(a, b);
					var spacesStr = ("                                                                                                                                      ")
						.slice(0, Math.abs((Math.ceil(loc.paperCharWidth - (a.length + b.length)))));
					return a + spacesStr + b;
				},
				rlr: function(a, b, c) {
                    console.log(a, b, c);
					if (a.length < 3 && a != "-")
						a = (("                                                                      ").slice(0, Math.abs((3 - a.length)))).concat(a);
					
					var spacesStr = ("                                                                                                                                      ")
						.slice(0, Math.abs((Math.ceil(loc.paperCharWidth - (5 + b.length + c.length)))));
					
					if (a == "-") a = "   ";
					if (c == "-") c = "  ";
					
					return (a + "  " + b + spacesStr + c);
				}
			};
			
			var curlen = 0;
			
			#e.ShowBasket("js")#
			
			request += builder.createTextElement({data: '\n'});
			request += builder.createTextElement({data: '\n'});
			
			request += builder.createCutPaperElement({feed:true});
			sendMessage(request);
		}
		
		window.onload = function() {}
		
		$(document).ready(function(e) {
			onSendAscii();
		});
	</script>
	
	<cfset e.ClearBasket()>
</cfoutput>

<cfcatch type="any">
	<cfset writeDumpToFile(cfcatch)>
</cfcatch>
</cftry>
