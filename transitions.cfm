<!doctype html>
<html>
<head>
<title>Clock Face</title>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<link href="css/epos.css?#randNum#" rel="stylesheet" type="text/css">
<link href="css/virtualInput.css?#randNum#" rel="stylesheet" type="text/css">
<script src="js/jquery-1.11.1.min.js?#randNum#"></script>
<script src="js/jquery-ui.js?#randNum#"></script>
<script src="js/epos.js"></script>
<script src="js/virtualInput.js"></script>
</head>

<body>
	<script>
		$(document).ready(function(e) {
			var hour = $('.cf_hour');
			var minute = $('.cf_minute');
			var dragging = false;
			var offset = hour.offset();
			
			minute.mousedown(function(event) {
				dragging = true;
			});
			
			$(document).mouseup(function(event) {
				dragging = false;
			});
			
			$(document).mousemove(function(event) {
				if (dragging) {
					var center_x = (offset.left) + (minute.width() / 2);
					var center_y = (offset.top) + (minute.height() / 2);
					var mouse_x = event.pageX; var mouse_y = event.pageY;
					var radians = Math.atan2(mouse_x - center_x, mouse_y - center_y);
					
					var hour_val = ( getRotationDegrees(hour) < 0 ) ? (getRotationDegrees(hour) / 30) + 12 : getRotationDegrees(hour) / 30;
					var min_val = ( getRotationDegrees(minute) < 0 ) ? (getRotationDegrees(minute) / 6) + 60 : getRotationDegrees(minute) / 6;
					
					var min_degree = (radians * (180 / Math.PI) * -1) + 90;
					var hour_degree = hour_val * 30 + (min_val / 2);
					
					minute.css('-moz-transform', 'rotate(' + min_degree + 'deg)');
					minute.css('-webkit-transform', 'rotate(' + min_degree + 'deg)');
					minute.css('-o-transform', 'rotate(' + min_degree + 'deg)');
					minute.css('-ms-transform', 'rotate(' + min_degree + 'deg)');
					
					hour.css('-moz-transform', 'rotate(' + hour_degree + 'deg)');
					hour.css('-webkit-transform', 'rotate(' + hour_degree + 'deg)');
					hour.css('-o-transform', 'rotate(' + hour_degree + 'deg)');
					hour.css('-ms-transform', 'rotate(' + hour_degree + 'deg)');
					
					var hour_val = ( getRotationDegrees(hour) < 0 ) ? (getRotationDegrees(hour) / 30) + 12 : getRotationDegrees(hour) / 30;
					var min_val = ( getRotationDegrees(minute) < 0 ) ? (getRotationDegrees(minute) / 6) + 60 : getRotationDegrees(minute) / 6;
					
					$('.deg').html( Math.floor(hour_degree) + ":" + Math.floor(min_degree) );
					$('.result').html( zeroPad(Math.floor(hour_val), 2) + ":" + zeroPad(Math.floor(min_val), 2) );
				}
			});
		});
	</script>
	<div class="virtual_time" style="padding:50px;">
		<div class="clock_face" style="background-image:url(../images/clockface.png);">
			<div class="clock_hands">
				<div class="cf_hour">
					<div class="top"></div>
				</div>
				<div class="cf_minute">
					<div class="top"></div>
				</div>
			</div>
		</div>
	</div>
	<div class="deg"></div>
	<div class="result"></div>
</body>
</html>