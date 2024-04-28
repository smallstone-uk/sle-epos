<cfoutput>
	<script>
		$(document).ready(function(e) {
			var shiftOn = false;
			var capsOn = false;
			var caretPos = 0;
			
			$('.virtual_keyboard').find('*').addClass("disable-select");
			$('.virtual_keyboard span').mouseup(function() {
				var keyPressed = $(this);
				var key_special = $(this).data("special");
				var key_inactive = $(this).data("inactive");
				var key_function = $(this).data("function");
				
				if (typeof key_special == "undefined" && typeof key_inactive == "undefined") {
					var origText = $(this).html();
					var newText = origText.replace(/&amp;/g, "&");
					newText = newText.replace(/&lt;/g, "<");
					newText = newText.replace(/&gt;/g, ">");
					insertAtCaret(window.vkField.id, newText);
					shiftOn = false;
					if (!capsOn) {
						$('.vk_letter').each(function(i, e) {$(e).html( $(e).html().toLowerCase() );});
						$('.vk_number').each(function(i, e) {$(e).html($(e).data("normal"));});
						$('.vk_symbol').each(function(i, e) {$(e).html($(e).data("normal"));});
						$('span').removeClass("vk_key_active");
					}
					
					caretPos = getCaretPosition(document.getElementById(window.vkField.id));
					setCaretPosition(window.vkField.id, caretPos);
				} else {
					switch(key_function)
					{
						case "backspace":
							var pos = getCaretPosition(document.getElementById(window.vkField.id));
							var text = window.vkField.obj.val();
							var strLength = text.length;
							var startStr = text.substring(0, (pos - 1));
							var endStr = text.substring(pos, strLength);
							var newText = startStr + endStr;
							caretPos = pos;
							window.vkField.obj.val(newText);
							caretPos = (pos - 1);
							setCaretPosition(window.vkField.id, caretPos);
							break;
						case "enter":
							break;
						case "capslock":
							if (!shiftOn) {
								var tempCapsOn = false;
								$('.vk_letter').each(function(i, e) {
									var upper = $(e).html().toUpperCase();
									var lower = $(e).html().toLowerCase();
									if (capsOn) {
										$(e).html(lower);
										tempCapsOn = false;
										$('span[data-function="capslock"]').removeClass("vk_key_active");
									} else {
										$(e).html(upper);
										tempCapsOn = true;
										$('span[data-function="capslock"]').addClass("vk_key_active");
									}
								});
								capsOn = tempCapsOn;
							}
							break;
						case "shift":
							if (!capsOn) {
								var tempOn = false;
								$('.vk_letter').each(function(i, e) {
									var upper = $(e).html().toUpperCase();
									var lower = $(e).html().toLowerCase();
									if (shiftOn) {
										$(e).html(lower);
										$('span[data-function="shift"]').removeClass("vk_key_active");
										tempOn = false;
									} else {
										$(e).html(upper);
										tempOn = true;
										$('span[data-function="shift"]').addClass("vk_key_active");
									}
								});
								$('.vk_number').each(function(i, e) {
									var key_normal = $(e).data("normal");
									var key_shift = $(e).data("shift");
	
									if (shiftOn) {
										$(e).html(key_normal);
									} else {
										$(e).html(key_shift);
									}
								});
								$('.vk_symbol').each(function(i, e) {
									var key_normal = $(e).data("normal");
									var key_shift = $(e).data("shift");
	
									if (shiftOn) {
										$(e).html(key_normal);
									} else {
										$(e).html(key_shift);
									}
								});
								shiftOn = tempOn;
							}
							break;
					}
				}
			});
			
			var repeatBackspace = null;
			$('span[data-function="backspace"]').bind("mousedown", function() {
				var me = $(this);
				window.touchtime = setTimeout(function() {
					window.touchhold = true;
					repeatBackspace = setInterval(function() {
						var pos = getCaretPosition(document.getElementById(window.vkField.id));
						var text = window.vkField.obj.val();
						var strLength = text.length;
						var startStr = text.substring(0, (pos - 1));
						var endStr = text.substring(pos, strLength);
						var newText = startStr + endStr;
						caretPos = pos;
						window.vkField.obj.val(newText);
						caretPos = (pos - 1);
						setCaretPosition(window.vkField.id, caretPos);
					}, 100);
				}, 750);
			}).bind('mouseup mouseleave', function() {
				clearTimeout(window.touchtime);
				clearInterval(repeatBackspace);
			});
			
			$('.virtual_keyboard').htmlClick(function() {
				if (window.isKeyboardOpen) {
					$('.dim').fadeOut(500, function() {$('.dim').remove()});
					$('.virtual_keyboard').animate({
						"bottom": "-1000px"
					}, 500, "easeInOutCubic");
					window.isKeyboardOpen = false;
				}
			});
			
			$(document).keypress(function(event) {
				if (event.which == 13) {
					event.preventDefault();
					$('.vk_enter').click();
				}
			});
		});
	</script>
	<div class='virtual_keyboard'>
		<div class="vk_1">
			<span class="vk_symbol" data-shift="¬" data-normal="`">`</span>
			<span class="vk_number" data-shift="!" data-normal="1">1</span>
			<span class="vk_number" data-shift='"' data-normal="2">2</span>
			<span class="vk_number" data-shift="£" data-normal="3">3</span>
			<span class="vk_number" data-shift="$" data-normal="4">4</span>
			<span class="vk_number" data-shift="%" data-normal="5">5</span>
			<span class="vk_number" data-shift="^" data-normal="6">6</span>
			<span class="vk_number" data-shift="&" data-normal="7">7</span>
			<span class="vk_number" data-shift="*" data-normal="8">8</span>
			<span class="vk_number" data-shift="(" data-normal="9">9</span>
			<span class="vk_number" data-shift=")" data-normal="0">0</span>
			<span class="vk_symbol" data-shift="_" data-normal="-">-</span>
			<span class="vk_symbol" data-shift="+" data-normal="=">=</span>
			<span class='vk_backspace' data-special="true" data-function="backspace">Backspace</span>
		</div>
		<div class="vk_2">
			<span class="vk_tab vk_inactive" data-inactive="true">Tab</span>
			<span class="vk_letter">q</span>
			<span class="vk_letter">w</span>
			<span class="vk_letter">e</span>
			<span class="vk_letter">r</span>
			<span class="vk_letter">t</span>
			<span class="vk_letter">y</span>
			<span class="vk_letter">u</span>
			<span class="vk_letter">i</span>
			<span class="vk_letter">o</span>
			<span class="vk_letter">p</span>
			<span class="vk_symbol" data-shift="{" data-normal="[">[</span>
			<span class="vk_symbol" data-shift="}" data-normal="]">]</span>
			<span class="vk_enter" data-special="true" data-function="enter">Enter</span>
		</div>
		<div class="vk_3">
			<span class="vk_capslock" data-special="true" data-function="capslock">Caps Lock</span>
			<span class="vk_letter">a</span>
			<span class="vk_letter">s</span>
			<span class="vk_letter">d</span>
			<span class="vk_letter">f</span>
			<span class="vk_letter">g</span>
			<span class="vk_letter">h</span>
			<span class="vk_letter">j</span>
			<span class="vk_letter">k</span>
			<span class="vk_letter">l</span>
			<span class="vk_symbol" data-shift=":" data-normal=";">;</span>
			<span class="vk_symbol" data-shift="@" data-normal="'">'</span>
			<span class="vk_symbol vk_hash" data-shift="~" data-normal="##">##</span>
		</div>
		<div class="vk_4">
			<span class="vk_shift_1" data-special="true" data-function="shift">Shift</span>
			<span class="vk_symbol" data-shift="|" data-normal="\">\</span>
			<span class="vk_letter">z</span>
			<span class="vk_letter">x</span>
			<span class="vk_letter">c</span>
			<span class="vk_letter">v</span>
			<span class="vk_letter">b</span>
			<span class="vk_letter">n</span>
			<span class="vk_letter">m</span>
			<span class="vk_symbol" data-shift="<" data-normal=",">,</span>
			<span class="vk_symbol" data-shift=">" data-normal=".">.</span>
			<span class="vk_symbol" data-shift="?" data-normal="/">/</span>
			<span class="vk_shift_2" data-special="true" data-function="shift">Shift</span>
		</div>
		<div class="vk_5">
			<span class="vk_inactive" data-inactive="true">Ctrl</span>
			<span class="vk_inactive" data-inactive="true">&nbsp;</span>
			<span class="vk_inactive" data-inactive="true">Alt</span>
			<span class='vk_space'> </span>
			<span class="vk_inactive" data-inactive="true">Alt Gr</span>
			<span class="vk_inactive" data-inactive="true">&nbsp;</span>
			<span class="vk_inactive" data-inactive="true">&nbsp;</span>
			<span class="vk_inactive" data-inactive="true">Ctrl</span>
		</div>
	</div>
</cfoutput>