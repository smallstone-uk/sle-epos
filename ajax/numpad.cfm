<cftry>
<cfset parm = {}>
<cfset parm.url = application.site.normal>
<cfset settings = form>

<cfoutput>
	<div class="vn_bigwrapper">
		<script>
			$(document).ready(function(e) {
				var numpadDecimal = "";
				
				var #ToScript(settings, "jSettings")#;
				var vnfield = $('input[data-index="#settings.index#"]');
				var vnfieldid = "#settings.field#";
				var $field = $("##" + vnfieldid);
				
				$('.virtual_numpad').find('*').addClass("disable-select");

				$('.vkn_digit').click(function(event) {
					var digit = $(this).html();
					var maxlength = jSettings.maxlength;
					
					if (maxlength < 0) {
						numpadDecimal += digit;
					} else {
						if (numpadDecimal.length < maxlength) {
							numpadDecimal += digit;
						}
					}
					
					var value = (jSettings.wholenumber == "true") ? numpadDecimal : tillFormat(numpadDecimal);

					$field.val(value);
					
					if (jSettings.autolength > -1) {
						if (value.length == jSettings.autolength) $('.vkn_enter').click();
					}
				});
				
				$('.vkn_clear').click(function(event) {
					$field.val("");
					numpadDecimal = "";
				});
				
				$(document).keypress(function(event) {
					if (event.which == 13) {
						event.preventDefault();
						$('.vkn_enter').click();
					}
				});
				
				$('.vkn_enter').click(function(event) {
					$('.dim').fadeOut(500, function() {$('.dim').remove();});
					$('.virtual_numpad').animate({
						"bottom": "-1000px"
					}, 500, "easeInOutCubic", function() {
						$('.vn_bigwrapper').remove();
						$field.removeAttr("data-spawned");
					});
				});
			});
		</script>
		<div class="virtual_numpad">
			<div class="vkn_1">
				<span class="vkn_digit">7</span>
				<span class="vkn_digit">8</span>
				<span class="vkn_digit">9</span>
			</div>
			<div class="vkn_2">
				<span class="vkn_digit">4</span>
				<span class="vkn_digit">5</span>
				<span class="vkn_digit">6</span>
			</div>
			<div class="vkn_3">
				<span class="vkn_digit">1</span>
				<span class="vkn_digit">2</span>
				<span class="vkn_digit">3</span>
			</div>
			<div class="vkn_4">
				<span class="vkn_digit">0</span>
				<span class="vkn_digit">00</span>
				<span class="vkn_clear">C</span>
			</div>
			<div class="vkn_5">
				<span class="vkn_enter">Enter</span>
			</div>
		</div>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>