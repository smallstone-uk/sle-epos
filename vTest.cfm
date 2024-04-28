<cftry>
<!DOCTYPE html>
<html>
<head>
<title>Virtual Input Test</title>
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<link href="css/virtualInput.css" rel="stylesheet" type="text/css">
<script src="../scripts/jquery-1.11.1.min.js"></script>
<script src="../scripts/jquery-ui.js"></script>
<script src="js/virtualInput.js"></script>
</head>

<cfoutput>
	<body id="content">
		<script>
			$(document).ready(function(e) {
				$('input[type="text"]').virtualKeyboard(function(text) {
					console.log(text);
				});
				$('input[type="number"]').virtualNumpad(function(text) {
					console.log(text);
				});
				$('.test2').click(function(event) {
					$.virtualKeyboard({
						callback: function(text) {
							console.log(text);
						}
					});
					event.preventDefault();
				});
				$('.test3').click(function(event) {
					$.virtualNumpad({
						wholenumber: true,
						autolength: 4,
						callback: function(value) {
							console.log(value);
						}
					});
					event.preventDefault();
				});
			});
		</script>
		<input type="text" name="test1" placeholder="text box 1" />
		<input type="number" name="test2" placeholder="number box 1" />
		<button class="test2">Click for Keyboard</button>
		<button class="test3">Click for Numpad</button>
	</body>
</cfoutput>
</html>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>