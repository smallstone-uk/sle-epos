<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Test Printer</title>
	<script type='text/javascript' src='http://kweb.epos.co.uk/js/StarWebPrintBuilder.js'></script>
	<script type='text/javascript' src='http://kweb.epos.co.uk/js/StarWebPrintTrader.js'></script>
	<script type='text/javascript'>
		function test() {
			var url = "http://192.168.123.189/StarWebPRNT/SendMessage";
			var papertype ="";
			var blackmark_sensor ="front_side";
			var request = "";
			
			var builder = new StarWebPrintBuilder();
			request += builder.createTextElement({characterspace:0, linespace:32, codepage:'cp437', international:'usa', font:'font_a',
				 width:1, height:1, emphasis:false, underline:false, invert:false, binary:true, data:'\x9c Star Micronics\n'});
			
			var trader = new StarWebPrintTrader({url:url, papertype:papertype, blackmark_sensor:blackmark_sensor});
			trader.onReceive = function (response) { alert(response.responseText); }
			trader.onError = function (response) { alert(response.responseText); }
			trader.sendMessage({request:request});
		}
		test();
	</script>
</head>

<body>
</body>
</html>