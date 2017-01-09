<cfoutput>
	<script>
		$(document).ready(function(e) {
			window.numpadDecimal = "";
			
			$('.virtual_numpad').find('*').addClass("disable-select");
			$('.virtual_numpad').css("left", Math.max(0, (($(window).width() - $('.virtual_numpad').outerWidth()) / 2) + $(window).scrollLeft()) + "px");
			$('.vkn_digit').click(function(event) {
				var digit = $(this).html();
				var maxLength = window.vkn_maxLength;
				
				if (maxLength < 0) {
					window.numpadDecimal += digit;
				} else {
					if (window.numpadDecimal.length < maxLength) {
						window.numpadDecimal += digit;
					}
				}
				
				var value = (window.wholenumber) ? window.numpadDecimal : tillFormat(window.numpadDecimal);
				$('.vkn_text').val(value);
				
				if (value.length == maxLength) $('.vkn_enter').click();
			});
			
			$('.vkn_clear').click(function(event) {
				$('.vkn_text').val("");
				window.numpadDecimal = "";
			});
			
			$(document).keypress(function(event) {
				if (event.which == 13) {
					event.preventDefault();
					$('.vkn_enter').click();
				}
			});
		});
	</script>
	<div class="virtual_numpad">
		<input type="text" class="vkn_text" id="vkn_text_id" />
		<button class="vkn_close">X</button>
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
</cfoutput>