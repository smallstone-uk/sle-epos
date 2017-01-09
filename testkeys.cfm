<!DOCTYPE html>
<html>
<head>
<title>Key Test</title>
<meta name="viewport" content="width=device-width,initial-scale=1.0">

<!--Core Scripts-->
<script src="js/jquery-1.11.1.min.js"></script>
<script src="js/jquery-ui.js"></script>
</head>

	<body>
		<script>
			$(document).ready(function(e) {
				$(document).keypress(function(event) {
					$('.result').append("<br />Works");
					event.preventDefault();
				});
			});
		</script>
		<div class="result"></div>
	</body>
</html>