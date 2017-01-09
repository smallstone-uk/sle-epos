;(function($) {
	// AUTHOR: JAMES KINGSLEY
	var VIC = {
		globalDelay: 250,
		keyboardSpawned: false,
		numpadSpawned: false,
		setCaretPosition: function(elemId, caretPos) {
			var elem = document.getElementById(elemId);
			if (elem != null) {
				if (elem.createTextRange) {
					var range = elem.createTextRange();
					range.move('character', caretPos);
					range.select();
				} else {
					if (elem.selectionStart) {
						elem.focus();
						elem.setSelectionRange(caretPos, caretPos);
					} else {
						elem.focus();
					}
				}
			}
		},
		getCaretPosition: function(oField) {
			var iCaretPos = 0;
			if (document.selection) {
				oField.focus();
				var oSel = document.selection.createRange();
				oSel.moveStart('character', -oField.value.length);
				iCaretPos = oSel.text.length;
			} else if (oField.selectionStart || oField.selectionStart == '0') {
				iCaretPos = oField.selectionStart;
			}
			return (iCaretPos);
		},
		insertAtCaret: function(areaId, text) {
			var txtarea = document.getElementById(areaId);
			var scrollPos = txtarea.scrollTop;
			var strPos = 0;
			var br = ((txtarea.selectionStart || txtarea.selectionStart == '0') ? 
				"ff" : (document.selection ? "ie" : false ) );
			if (br == "ie") { 
				txtarea.focus();
				var range = document.selection.createRange();
				range.moveStart ('character', -txtarea.value.length);
				strPos = range.text.length;
			}
			else if (br == "ff") strPos = txtarea.selectionStart;
		
			var front = (txtarea.value).substring(0,strPos);  
			var back = (txtarea.value).substring(strPos,txtarea.value.length); 
			txtarea.value=front+text+back;
			strPos = strPos + text.length;
			if (br == "ie") { 
				txtarea.focus();
				var range = document.selection.createRange();
				range.moveStart ('character', -txtarea.value.length);
				range.moveStart ('character', strPos);
				range.moveEnd ('character', 0);
				range.select();
			}
			else if (br == "ff") {
				txtarea.selectionStart = strPos;
				txtarea.selectionEnd = strPos;
				txtarea.focus();
			}
			txtarea.scrollTop = scrollPos;
		},
		center: function(a, b, c) {
			var caller = $(a);
			caller.css("position", c || "fixed");
			
			switch(b || "both")
			{
				case "top":
					caller.css("top", Math.max(0, (($(window).height() - caller.outerHeight()) / 2) + $(window).scrollTop()) + "px");
					break;
				case "left":
					caller.css("left", Math.max(0, (($(window).width() - caller.outerWidth()) / 2) + $(window).scrollLeft()) + "px");
					break;
				case "both":
					caller.css("top", Math.max(0, (($(window).height() - caller.outerHeight()) / 2) + $(window).scrollTop()) + "px");
					caller.css("left", Math.max(0, (($(window).width() - caller.outerWidth()) / 2) + $(window).scrollLeft()) + "px");
					break;
			}
		},
		nf: function(a, b) {
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
				switch (b)
				{
					case "abs_num":	return result.abs_num;	break;
					case "abs_str":	return result.abs_str;	break;
					case "num":		return result.num;		break;
					case "str":		return result.str;		break;
					case "all":		return result;			break;
					default:		return result.str;		break;
				}
			}
		},
		tillFormat: function(a) {
			return (Number(a) / 100).toFixed(2);
		},
		containsSpace: function(str) {
			return /[\s]/.test(str);
		},
		isSymbol: function(str) {
			return /[$-/:-?{-~!""^_`\[\]]/.test(str);
		},
		isNumber: function(str) {
			return /^(\d|\.)+$/.test(str);
		},
		isBoolean: function(str) {
			if (str == "true" || str == "false") return true; else return false;
		},
		toJava: function(str) {
			var a = str;
			var result = {};
			var str = a.trim().replace(/\t/igm, "");
			var arr = str.split("@");
			for (var i = 0; i < arr.length; i++) {
				if (arr[i].length > 0) {
					var element = arr[i].split(":");
					var isNum = element[1].trim().isNumber();
					var isBool = element[1].trim().isBoolean();
					if (isNum) {
						var value = Number(element[1].trim());
					} else if (isBool) {
						if (element[1].trim() == "true") {
							var value = true;
						} else if (element[1].trim() == "false") {
							var value = false;
						}
					} else {
						var value = element[1].trim();
					}
					result[ element[0].trim() ] = value;
				}
			}
			return result;
		},
		getAttributes: function(node) {
			var d = {}, re_dataAttr = /^data\-(.+)$/;
			$.each(node.get(0).attributes, function(index, attr) {
				if (re_dataAttr.test(attr.nodeName)) {
					var key = attr.nodeName.match(re_dataAttr)[1];
					
					var isNum = VIC.isNumber(attr.value);
					var isBool = VIC.isBoolean(attr.value);
					if (isNum) {
						var value = Number(attr.value);
					} else if (isBool) {
						if (attr.value == "true") {
							var value = true;
						} else if (attr.value == "false") {
							var value = false;
						}
					} else {
						var value = attr.value;
					}
					
					d[key] = value;
				}
			});
			return d;
		},
		shakeInput: function(input) {
			var shake = null;
			var posSwitch = 0;
			var input = (input == "keyboard") ? ".virtual_keyboard" : ".virtual_numpad";
			var startLeft = $(input).offset().left;
			
			shake = setInterval(function() {
				posSwitch = (posSwitch == 0) ? 1 : 0;
				if (posSwitch == 0) {
					$(input).animate({
						left: startLeft + 15 + "px"
					}, 50, "easeInOutCubic");
				} else {
					$(input).animate({
						left: startLeft - 15 + "px"
					}, 50, "easeInOutCubic");
				}
			}, 50);
			
			setTimeout(function() {
				clearInterval(shake);
				$(input).animate({
					left: startLeft + "px"
				}, 50, "easeInOutCubic");
			}, 500);
		},
		buildKeyboard: function(settings) {
			var row_hint = (settings.hint.length > 0) ? '<div class="vk_hint">' + settings.hint + '</div>' : '';
			var row_0 = (settings.includeField) ? '<input type="text" disabled="true" name="vkTextField" class="vk_text" id="vkinput_0000" />' : '';
			
			var row_1 = '<div class="vk_1">'+
			'<span class="vk_symbol" data-shift="&#172;" data-normal="`">`</span>'+
			'<span class="vk_number" data-shift="!" data-normal="1">1</span>'+
			'<span class="vk_number" data-shift="&#8220;" data-normal="2">2</span>'+
			'<span class="vk_number" data-shift="&pound;" data-normal="3">3</span>'+
			'<span class="vk_number" data-shift="$" data-normal="4">4</span>'+
			'<span class="vk_number" data-shift="%" data-normal="5">5</span>'+
			'<span class="vk_number" data-shift="^" data-normal="6">6</span>'+
			'<span class="vk_number" data-shift="&" data-normal="7">7</span>'+
			'<span class="vk_number" data-shift="*" data-normal="8">8</span>'+
			'<span class="vk_number" data-shift="(" data-normal="9">9</span>'+
			'<span class="vk_number" data-shift=")" data-normal="0">0</span>'+
			'<span class="vk_symbol" data-shift="_" data-normal="-">-</span>'+
			'<span class="vk_symbol" data-shift="+" data-normal="=">=</span>'+
			'<span class="vk_backspace" data-special="true" data-function="backspace">Backspace</span>'+
			'</div>';
			
			var row_2 = '<div class="vk_2">'+
			'<span class="vk_tab vk_inactive" data-inactive="true">Tab</span>'+
			'<span class="vk_letter">q</span>'+
			'<span class="vk_letter">w</span>'+
			'<span class="vk_letter">e</span>'+
			'<span class="vk_letter">r</span>'+
			'<span class="vk_letter">t</span>'+
			'<span class="vk_letter">y</span>'+
			'<span class="vk_letter">u</span>'+
			'<span class="vk_letter">i</span>'+
			'<span class="vk_letter">o</span>'+
			'<span class="vk_letter">p</span>'+
			'<span class="vk_symbol" data-shift="{" data-normal="[">[</span>'+
			'<span class="vk_symbol" data-shift="}" data-normal="]">]</span>'+
			'<span class="vk_enter" data-special="true" data-function="enter">Enter</span>'+
			'</div>'
			
			var row_3 = '<div class="vk_3">'+
			'<span class="vk_capslock" data-special="true" data-function="capslock">Caps Lock</span>'+
			'<span class="vk_letter">a</span>'+
			'<span class="vk_letter">s</span>'+
			'<span class="vk_letter">d</span>'+
			'<span class="vk_letter">f</span>'+
			'<span class="vk_letter">g</span>'+
			'<span class="vk_letter">h</span>'+
			'<span class="vk_letter">j</span>'+
			'<span class="vk_letter">k</span>'+
			'<span class="vk_letter">l</span>'+
			'<span class="vk_symbol" data-shift=":" data-normal=";">;</span>'+
			'<span class="vk_symbol" data-shift="@" data-normal="&#39;">&#39;</span>'+
			'<span class="vk_symbol vk_hash" data-shift="~" data-normal="#">#</span>'+
			'</div>';
			
			var row_4 = '<div class="vk_4">'+
			'<span class="vk_shift_1" data-special="true" data-function="shift">Shift</span>'+
			'<span class="vk_symbol" data-shift="|" data-normal="\">\</span>'+
			'<span class="vk_letter">z</span>'+
			'<span class="vk_letter">x</span>'+
			'<span class="vk_letter">c</span>'+
			'<span class="vk_letter">v</span>'+
			'<span class="vk_letter">b</span>'+
			'<span class="vk_letter">n</span>'+
			'<span class="vk_letter">m</span>'+
			'<span class="vk_symbol" data-shift="<" data-normal=",">,</span>'+
			'<span class="vk_symbol" data-shift=">" data-normal=".">.</span>'+
			'<span class="vk_symbol" data-shift="?" data-normal="/">/</span>'+
			'<span class="vk_shift_2" data-special="true" data-function="shift">Shift</span>'+
			'</div>';
			
			var row_5 = '<div class="vk_5">'+
			'<span class="vk_inactive" data-inactive="true">Ctrl</span>'+
			'<span class="vk_inactive" data-inactive="true">&nbsp;</span>'+
			'<span class="vk_inactive" data-inactive="true">Alt</span>'+
			'<span class="vk_space"> </span>'+
			'<span class="vk_inactive" data-inactive="true">Alt Gr</span>'+
			'<span class="vk_inactive" data-inactive="true">&nbsp;</span>'+
			'<span class="vk_inactive" data-inactive="true">&nbsp;</span>'+
			'<span class="vk_inactive" data-inactive="true">Ctrl</span>'+
			'</div>';
			
			var html = "<div class='virtual_keyboard'>" + row_hint + row_0 + row_1 + row_2 + row_3 + row_4 + row_5 + "</div>";
			
			$('body').prepend(html);
			VIC.keyboardSpawned = true;
			VIC.center('.virtual_keyboard', 'left');
			$('.virtual_keyboard').animate({"bottom": "1%"}, VIC.globalDelay, "easeInOutCubic");
			
			var $field = $("#" + settings.field);
			if ( $field.parents('.vic_host').length > 0 ) {
				VIC.original_top = $field.parents('.vic_host').offset().top;
				var input_top = $field.offset().top;
				var vic_top = $('.virtual_keyboard').offset().top;
				var vic_height = $('.virtual_keyboard').outerHeight(true);
				var area_height = $(window).innerHeight();
				
				if (vic_top >= input_top) {
					$field.parents('.vic_host').css( "top", ( area_height - ( (vic_height * 2) - 50 ) ) );
				}
			}
			
			return html;
		},
		buildKeyboardEvents: function(settings) {
			var shiftOn = false;
			var capsOn = false;
			var caretPos = 0;
			
			var vkfield = $('input[data-index="' + settings.index + '"]');
			var vkfieldid = settings.field;
			var $field = $("#" + vkfieldid);
			
			if (settings.value.length > 0) $field.val(settings.value);
			
			$field.bind("input change", function() {
				if (typeof settings.onkey == "function") settings.onkey($field.val(), VIC);
			});
			
			$('.virtual_keyboard').find('*').addClass("disable-select");
			$('.virtual_keyboard span').bind("mouseup", function() {
				var keyPressed = $(this);
				var key_special = $(this).data("special");
				var key_inactive = $(this).data("inactive");
				var key_function = $(this).data("function");
				
				if (typeof key_special == "undefined" && typeof key_inactive == "undefined") {
					var origText = $(this).html();
					var newText = origText.replace(/&amp;/g, "&");
					newText = newText.replace(/&lt;/g, "<");
					newText = newText.replace(/&gt;/g, ">");
					
					// Only insert if settings permit
					var isSymbol = VIC.isSymbol(newText);
					var isNumber = VIC.isNumber(newText);
					var containsSpace = VIC.containsSpace(newText);
					
					if (!settings.symbols || settings.symbols == "false") if (isSymbol) newText = "";
					if (!settings.numbers || settings.numbers == "false") if (isNumber) newText = "";
					if (!settings.spaces || settings.spaces == "false") if (containsSpace) newText = "";
					VIC.insertAtCaret(vkfieldid, newText);
					
					shiftOn = false;
					if (!capsOn) {
						$('.vk_letter').each(function(i, e) {$(e).html( $(e).html().toLowerCase() );});
						$('.vk_number').each(function(i, e) {$(e).html($(e).data("normal"));});
						$('.vk_symbol').each(function(i, e) {$(e).html($(e).data("normal"));});
						$('span').removeClass("vk_key_active");
					}
					
					caretPos = VIC.getCaretPosition(document.getElementById(vkfieldid));
					VIC.setCaretPosition(vkfieldid, caretPos);
					
					if (typeof settings.onkey == "function") settings.onkey($field.val(), VIC);
				} else {
					switch(key_function)
					{
						case "backspace":
							var pos = VIC.getCaretPosition(document.getElementById(vkfieldid));
							var text = $field.val();
							var strLength = text.length;
							var startStr = text.substring(0, (pos - 1));
							var endStr = text.substring(pos, strLength);
							var newText = startStr + endStr;
							caretPos = pos;
							$field.val(newText);
							caretPos = (pos - 1);
							VIC.setCaretPosition(vkfieldid, caretPos);
							break;
						case "enter":
							if (typeof settings.callback == "function") settings.callback($field.val(), VIC);
							VIC.keyboardSpawned = false;
							//setTimeout(function() {
								VIC.center($field.parents('.vic_host'), "both", "fixed");
							//}, 100);
							$('.virtual_keyboard').animate({"bottom": "-1000px"}, VIC.globalDelay, "easeInOutCubic", function() {
								$('.virtual_keyboard').remove();
								$field.removeAttr("data-spawned");
							});
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
			var touchtime = null;
			var touchhold = null;
			
			$('span[data-function="backspace"]').bind("mousedown", function() {
				var me = $(this);
				touchtime = setTimeout(function() {
					touchhold = true;
					repeatBackspace = setInterval(function() {
						var pos = VIC.getCaretPosition(document.getElementById(vkfieldid));
						var text = $field.val();
						var strLength = text.length;
						var startStr = text.substring(0, (pos - 1));
						var endStr = text.substring(pos, strLength);
						var newText = startStr + endStr;
						caretPos = pos;
						$field.val(newText);
						caretPos = (pos - 1);
						VIC.setCaretPosition(vkfieldid, caretPos);
					}, 100);
				}, 750);
			}).bind('mouseup mouseleave', function() {
				clearTimeout(touchtime);
				clearInterval(repeatBackspace);
			});
			
			$(document).bind("mousedown.eventsGrp", function(event) {
				var target = $(event.target);
				if (!target.is($('.virtual_keyboard')) && !target.is($('.virtual_keyboard').find('*'))) {
					VIC.keyboardSpawned = false;
					VIC.center($field.parents('.vic_host'), "both", "fixed");
					$('.virtual_keyboard').animate({"bottom": "-1000px"}, VIC.globalDelay, "easeInOutCubic", function() {
						$('.virtual_keyboard').remove();
						$field.removeAttr("data-spawned");
					});
				}
			});
			
			$(document).bind("keypress", function(event) {
				if (event.which == 13) {
					event.preventDefault();
					VIC.keyboardSpawned = false;
					VIC.center($field.parents('.vic_host'), "both", "fixed");
					$('.virtual_keyboard').animate({"bottom": "-1000px"}, VIC.globalDelay, "easeInOutCubic", function() {
						$('.virtual_keyboard').remove();
						$field.removeAttr("data-spawned");
					});
				}
			});
		},
		buildNumpad: function(settings) {
			var row_hint = (settings.hint.length > 0) ? '<div class="vkn_hint">' + settings.hint + '</div>' : '';
			var row_minhint = (settings.minimum >= 0) ? '<span class="vkn_minhint">Min: ' + settings.minimum + '</span>' : '';
			var row_maxhint = (settings.maximum >= 0) ? '<span class="vkn_maxhint">Max: ' + settings.maximum + '</span>' : '';
			var row_0 = '';
			var inputType = (settings.secret) ? "password" : "text";
			
			if (settings.fields && settings.fields.length > 0) {
				for (var i = 0; i < settings.fields.length; i++) {
					row_0 += '<label class="vkn_label"><span class="vkn_labelspan">' + settings.fields[i].label + '</span>'+
					'<input type="text" disabled="true" data-int="' + i + '" name="' + settings.fields[i].name + '" class="vkn_text_arr" value="' + settings.fields[i].value + '" /></label>';
				}
			} else if (settings.includeField) {
				if (settings.overide) {
					row_0 = '<input type="' + inputType + '" disabled="true" name="vkTextField" id="vninput_0000" class="vkn_text vkn_or_short" /><span class="vkn_overide icon-lock" data-switch="1"></span>';
				} else {
					row_0 = '<input type="' + inputType + '" disabled="true" name="vkTextField" id="vninput_0000" class="vkn_text" />';
				}
			}
			
			var rows = '<div class="vkn_1">'+
			'<span class="vkn_digit">7</span>'+
			'<span class="vkn_digit">8</span>'+
			'<span class="vkn_digit">9</span>'+
			'</div>'+
			'<div class="vkn_2">'+
			'<span class="vkn_digit">4</span>'+
			'<span class="vkn_digit">5</span>'+
			'<span class="vkn_digit">6</span>'+
			'</div>'+
			'<div class="vkn_3">'+
			'<span class="vkn_digit">1</span>'+
			'<span class="vkn_digit">2</span>'+
			'<span class="vkn_digit">3</span>'+
			'</div>'+
			'<div class="vkn_4">'+
			'<span class="vkn_digit">0</span>'+
			'<span class="vkn_digit">00</span>'+
			'<span class="vkn_clear icon-arrow-left"></span>'+
			'</div>'+
			'<div class="vkn_5">'+
			'<span class="vkn_enter">Enter</span>'+
			'</div>';
			
			var html = '<div class="virtual_numpad">' + row_hint + row_minhint + row_maxhint + row_0 + rows + '</div>';
			
			$('body').prepend(html);
			VIC.numpadSpawned = true;
			VIC.center('.virtual_numpad', 'left');
			$('.virtual_numpad').animate({"bottom": "1%"}, VIC.globalDelay, "easeInOutCubic");
			
			return html;
		},
		buildDate: function(settings) {
			var row_hint = (settings.hint.length > 0) ? '<div class="vkn_hint">' + settings.hint + '</div>' : '';
			var row_0 = (settings.includeField) ? '<input type="text" disabled="true" name="vkTextField" id="vninput_0000" placeholder="DD/MM/YYYY" />' : '';
			var rows = '<div class="vkn_1">'+
			'<span class="vkn_digit">7</span>'+
			'<span class="vkn_digit">8</span>'+
			'<span class="vkn_digit">9</span>'+
			'</div>'+
			'<div class="vkn_2">'+
			'<span class="vkn_digit">4</span>'+
			'<span class="vkn_digit">5</span>'+
			'<span class="vkn_digit">6</span>'+
			'</div>'+
			'<div class="vkn_3">'+
			'<span class="vkn_digit">1</span>'+
			'<span class="vkn_digit">2</span>'+
			'<span class="vkn_digit">3</span>'+
			'</div>'+
			'<div class="vkn_4">'+
			'<span class="vkn_digit">0</span>'+
			'<span class="vkn_digit">00</span>'+
			'<span class="vkn_clear icon-arrow-left"></span>'+
			'</div>'+
			'<div class="vkn_5">'+
			'<span class="vkn_enter">Enter</span>'+
			'</div>';
			
			var html = '<div class="virtual_numpad">' + row_hint + row_0 + rows + '</div>';
			
			$('body').prepend(html);
			VIC.dateSpawned = true;
			VIC.center('.virtual_numpad', 'left');
			$('.virtual_numpad').animate({"bottom": "1%"}, VIC.globalDelay, "easeInOutCubic");
			
			return html;
		},
		buildTime: function(settings) {
			var row_hint = (settings.hint.length > 0) ? '<div class="vkn_hint">' + settings.hint + '</div>' : '';
			var row_0 = (settings.includeField) ? '<input type="text" disabled="true" name="vkTextField" id="vninput_0000" placeholder="HH:MM" />' : '';
			var rows = '<div class="vkn_1">'+
			'<span class="vkn_digit">7</span>'+
			'<span class="vkn_digit">8</span>'+
			'<span class="vkn_digit">9</span>'+
			'</div>'+
			'<div class="vkn_2">'+
			'<span class="vkn_digit">4</span>'+
			'<span class="vkn_digit">5</span>'+
			'<span class="vkn_digit">6</span>'+
			'</div>'+
			'<div class="vkn_3">'+
			'<span class="vkn_digit">1</span>'+
			'<span class="vkn_digit">2</span>'+
			'<span class="vkn_digit">3</span>'+
			'</div>'+
			'<div class="vkn_4">'+
			'<span class="vkn_digit">0</span>'+
			'<span class="vkn_digit">00</span>'+
			'<span class="vkn_clear icon-arrow-left"></span>'+
			'</div>'+
			'<div class="vkn_5">'+
			'<span class="vkn_enter">Enter</span>'+
			'</div>';
			
			var html = '<div class="virtual_numpad">' + row_hint + row_0 + rows + '</div>';
			
			$('body').prepend(html);
			VIC.dateSpawned = true;
			VIC.center('.virtual_numpad', 'left');
			$('.virtual_numpad').animate({"bottom": "1%"}, VIC.globalDelay, "easeInOutCubic");
			
			return html;
		},
		buildDateEvents: function(settings) {
			var numpadDecimal = "";
			var vnfield = $('input[data-index="' + settings.index + '"]');
			var vnfieldid = settings.field;
			var $field = $("#" + vnfieldid);
			
			$('.virtual_numpad').find('*').addClass("disable-select");
			
			$('.vkn_digit').bind("click", function(event) {
				var digit = $(this).html();
				if (numpadDecimal.length == 2) numpadDecimal += "/";
				if (numpadDecimal.length == 5) numpadDecimal += "/";
				numpadDecimal += digit;
				$field.val(numpadDecimal);
			});
			
			$('.vkn_clear').bind("click", function(event) {
				numpadDecimal = numpadDecimal.substring(0, numpadDecimal.length - 1);
				$field.val(numpadDecimal);
			});
			
			$(document).bind("mousedown.eventsGrp", function(event) {
				var target = $(event.target);
				if (!target.is($('.virtual_numpad')) && !target.is($('.virtual_numpad').find('*'))) {
					if (validateEntry()) {
						if (settings.forceCallback) if (typeof settings.callback == "function") settings.callback($field.val(), $field);
						VIC.dateSpawned = false;
						$('.virtual_numpad').animate({
							"bottom": "-1000px"
						}, VIC.globalDelay, "easeInOutCubic", function() {
							$('.virtual_numpad').remove();
							$field.removeAttr("data-spawned").removeClass("VIC_ErrorFld").blur();
						});
					}
				}
			});
			
			$(document).bind("keypress", function(event) {
				if (event.which == 13) {
					event.preventDefault();
					$('.vkn_enter').click();
				}
			});
			
			validateEntry = function() {
				var allowEnter = true;
				
				// Handle past/future
				var date_values = $field.val().split("/");
				var chosen_date = new Date(date_values[2], (date_values[1] - 1), date_values[0]);
				var current_date_abs = new Date();
				var current_date = new Date(current_date_abs.getFullYear(), current_date_abs.getMonth(), current_date_abs.getDate());
				
				if ( $field.val().length > 0 ) {
					if (!settings.future) {
						if (chosen_date > current_date) {
							VIC.shakeInput("numpad");
							allowEnter = false;
							$field.val("").addClass("VIC_ErrorFld");
							numpadDecimal = "";
						}
					}
					
					if (!settings.past) {
						if (chosen_date < current_date) {
							VIC.shakeInput("numpad");
							allowEnter = false;
							$field.val("").addClass("VIC_ErrorFld");
							numpadDecimal = "";
						}
					}
					
					// Validate month
					if (date_values[1] <= 0 || date_values[1] > 12) {
						VIC.shakeInput("numpad");
						allowEnter = false;
						$field.val("").addClass("VIC_ErrorFld");
						numpadDecimal = "";
					}
					
					// Validate day
					if (allowEnter) {
						var days_in_month1 = new Date(date_values[2], date_values[1], 0);
						var days_in_month = new Date(date_values[2], date_values[1], 0).getDate();
	
						if (date_values[0] > days_in_month || date_values[0] <= 0) {
							VIC.shakeInput("numpad");
							allowEnter = false;
							$field.val("").addClass("VIC_ErrorFld");
							numpadDecimal = "";
						}
					}
				}
				
				return allowEnter;
			}
			
			$('.vkn_enter').bind("click", function(event) {
				if (validateEntry()) {
					if (typeof settings.callback == "function") settings.callback($field.val(), VIC);
					VIC.dateSpawned = false;
					$('.virtual_numpad').animate({
						"bottom": "-1000px"
					}, VIC.globalDelay, "easeInOutCubic", function() {
						$('.virtual_numpad').remove();
						$field.removeAttr("data-spawned").removeClass("VIC_ErrorFld").blur();
					});
				}
			});
		},
		buildTimeEvents: function(settings) {
			var numpadDecimal = "";
			var vnfield = $('input[data-index="' + settings.index + '"]');
			var vnfieldid = settings.field;
			var $field = $("#" + vnfieldid);
			
			$('.virtual_numpad').find('*').addClass("disable-select");
			
			$('.vkn_digit').bind("click", function(event) {
				var digit = $(this).html();
				if (numpadDecimal.length == 2) numpadDecimal += ":";
				numpadDecimal += digit;
				$field.val(numpadDecimal);
			});
			
			$('.vkn_clear').bind("click", function(event) {
				numpadDecimal = numpadDecimal.substring(0, numpadDecimal.length - 1);
				$field.val(numpadDecimal);
			});
			
			$(document).bind("mousedown.eventsGrp", function(event) {
				var target = $(event.target);
				if (!target.is($('.virtual_numpad')) && !target.is($('.virtual_numpad').find('*'))) {
					if (validateEntry()) {
						if (settings.forceCallback) if (typeof settings.callback == "function") settings.callback($field.val(), $field);
						VIC.dateSpawned = false;
						$('.virtual_numpad').animate({
							"bottom": "-1000px"
						}, VIC.globalDelay, "easeInOutCubic", function() {
							$('.virtual_numpad').remove();
							$field.removeAttr("data-spawned").removeClass("VIC_ErrorFld").blur();
						});
					}
				}
			});
			
			$(document).bind("keypress", function(event) {
				if (event.which == 13) {
					event.preventDefault();
					$('.vkn_enter').click();
				}
			});
			
			validateEntry = function() {
				var allowEnter = true;
				
				if ( $field.val().length > 0 ) {
					var hour = VIC.nf($field.val().split(":")[0], "num");
					var minute = VIC.nf($field.val().split(":")[1], "num");
					
					if (hour > 23 || hour < 0) allowEnter = false;
					if (minute > 59 || minute < 0) allowEnter = false;
				}
				
				return allowEnter;
			}
			
			$('.vkn_enter').bind("click", function(event) {
				if (validateEntry()) {
					if (typeof settings.callback == "function") settings.callback($field.val(), VIC);
					VIC.dateSpawned = false;
					$('.virtual_numpad').animate({
						"bottom": "-1000px"
					}, VIC.globalDelay, "easeInOutCubic", function() {
						$('.virtual_numpad').remove();
						$field.removeAttr("data-spawned").removeClass("VIC_ErrorFld").blur();
					});
				}
			});
		},
		buildNumpadEvents: function(settings) {
			var numpadDecimal = "";
			var vnfield = $('input[data-index="' + settings.index + '"]');
			var vnfieldid = settings.field;
			var $field = $("#" + vnfieldid);
			var curint = 0;
			var orSwitch = true;
			var kpReturnFields = {};
			
			for (var fld in settings.fields) {
				kpReturnFields[ settings.fields[fld].name ] = $( 'input[name="' + settings.fields[fld].name + '"]' );
			}
			
			if (settings.fields && settings.fields.length > 0) {
				$field = $( 'input[name="' + settings.fields[0].name + '"]' );
				$field.addClass("vkn_activefld");
			}
			
			$('.virtual_numpad').find('*').addClass("disable-select");
			
			$('.vkn_digit').bind("click", function(event) {
				var digit = $(this).html();
				var maxlength = settings.maxlength;
				if (maxlength < 0) numpadDecimal += digit; else if (numpadDecimal.length < maxlength) numpadDecimal += digit;
				var value = (settings.wholenumber || settings.wholenumber == "true") ? numpadDecimal : VIC.tillFormat(numpadDecimal);
				$field.val(value);
				if (settings.autolength > -1) if (value.length == settings.autolength) $('.vkn_enter').click();
				settings.keypress(kpReturnFields);
			});
			
			$('.vkn_clear').bind("click", function(event) {
				numpadDecimal = numpadDecimal.substring(0, numpadDecimal.length - 1);
				var value = (settings.wholenumber || settings.wholenumber == "true") ? numpadDecimal : VIC.tillFormat(numpadDecimal);
				$field.val(value);
			});
			
			$('.vkn_overide').bind("click", function(event) {
				var me = $(this);
				if (me.attr("data-switch") == 1 || me.attr("data-switch") == "1") {
					orSwitch = false;
					me.removeClass("icon-lock");
					me.addClass("icon-unlocked");
					me.attr("data-switch", "0");
				} else {
					orSwitch = true;
					me.removeClass("icon-unlocked");
					me.addClass("icon-lock");
					me.attr("data-switch", "1");
				}
			});
			
			$('.vkn_text_arr').bind("click", function(event) {
				numpadDecimal = "";
				$field = $(this);
				$field.focus();
				curint = Number( $field.attr("data-int") );
				$('.vkn_text_arr').removeClass("vkn_activefld");
				$field.addClass("vkn_activefld");
			});
			
			serializeFields = function() {
				var struct = {};
				if (settings.fields && settings.fields.length > 0) {
					for (var i = 0; i < settings.fields.length; i++) {
						struct[ settings.fields[i].name ] = $( 'input[name="' + settings.fields[i].name + '"]' ).val();
					}
				}
				return struct;
			}
			
			$(document).bind("mousedown.eventsGrp", function(event) {
				var target = $(event.target);
				if (!target.is($('.virtual_numpad')) && !target.is($('.virtual_numpad').find('*'))) {
					if (validateEntry()) {
						if (settings.forceCallback) if (typeof settings.callback == "function") settings.callback( (settings.fields && settings.fields.length > 0) ? serializeFields() : $field.val(), $field );
						VIC.numpadSpawned = false;
						$('.virtual_numpad').animate({
							"bottom": "-1000px"
						}, VIC.globalDelay, "easeInOutCubic", function() {
							$('.virtual_numpad').remove();
							$field.removeAttr("data-spawned").removeClass("VIC_ErrorFld").blur();
						});
					}
				}
			});
			
			$(document).bind("keypress", function(event) {
				if (event.which == 13) {
					event.preventDefault();
					$('.vkn_enter').click();
				}
			});
			
			validateEntry = function() {
				var allowEnter = true;
				
				// Handle modulas
				if (settings.mod > -1) {
					var valueToTest = (settings.wholenumber || settings.wholenumber == "true") ? Math.round($field.val()) : Math.round($field.val() * 100);
					if ( Math.round(valueToTest % settings.mod) > 0 ) {
						VIC.shakeInput("numpad");
						allowEnter = false;
						$field.val("").addClass("VIC_ErrorFld");
						numpadDecimal = "";
					}
				}
				
				// Handle min and max
				if (orSwitch) {
					if (settings.minimum > -1) {
						if ($field.val() < settings.minimum) {
							VIC.shakeInput("numpad");
							allowEnter = false;
							$field.val("").addClass("VIC_ErrorFld");
							numpadDecimal = "";
						}
					}
				}
				
				if (orSwitch) {
					if (settings.maximum > -1) {
						if ($field.val() > settings.maximum) {
							VIC.shakeInput("numpad");
							allowEnter = false;
							$field.val("").addClass("VIC_ErrorFld");
							numpadDecimal = "";
						}
					}
				}
				
				if (allowEnter) return true;
			}
			
			$('.vkn_enter').bind("click", function(event) {
				if (validateEntry()) {
					if (settings.fields && settings.fields.length > 0) {
						var int = ( curint < (settings.fields.length - 1) ) ? curint + 1 : settings.fields.length - 1;
						curint = int;
						
						if ( Number( $field.attr("data-int") ) == (settings.fields.length - 1) ) {
							if (typeof settings.callback == "function") settings.callback( (settings.fields && settings.fields.length > 0) ? serializeFields() : $field.val(), $field );
							VIC.numpadSpawned = false;
							$('.virtual_numpad').animate({
								"bottom": "-1000px"
							}, VIC.globalDelay, "easeInOutCubic", function() {
								$('.virtual_numpad').remove();
								$field.removeAttr("data-spawned").removeClass("VIC_ErrorFld").blur();
							});
						}
						
						$field = $( 'input[name="' + settings.fields[int].name + '"]' );
						$field.focus();
						$('.vkn_text_arr').removeClass("vkn_activefld");
						$field.addClass("vkn_activefld");
						numpadDecimal = "";
					} else {
						if (typeof settings.callback == "function") settings.callback( (settings.fields && settings.fields.length > 0) ? serializeFields() : $field.val(), $field );
						VIC.numpadSpawned = false;
						$('.virtual_numpad').animate({
							"bottom": "-1000px"
						}, VIC.globalDelay, "easeInOutCubic", function() {
							$('.virtual_numpad').remove();
							$field.removeAttr("data-spawned").removeClass("VIC_ErrorFld").blur();
						});
					}
				}
			});
		}
	};
	$.fn.virtualKeyboard = function(callback) {
		var selector = $(this);
		
		return selector.each(function(i, e) {
			var caller = $(e);
			
			// Set Index
			var rand = Math.floor(Math.random() * 99999999) + 9999;
			caller.attr("data-index", i + rand);
			
			// Setup Events
			caller.unbind("vkevent");
			caller.bind("focus.vkevent", function(event) {
				var field = $(this);
				
				// Delete old nodes
				if (!VIC.keyboardSpawned) {
					$('.virtual_keyboard, .virtual_numpad').clearQueue().stop().finish().remove();
					field.removeAttr("data-spawned");
				}
				
				// Only proceed if keyboard is not already in use
				if ( typeof field.attr("data-spawned") == "undefined" || field.attr("data-spawned") == "false" ) {
					
					// Extend Default Settings
					var extendBy = (typeof callback == "object") ? callback : VIC.getAttributes(field);
					var settings = $.extend(true, {
						hint: "",
						symbols: true,
						numbers: true,
						letters: true,
						spaces: true,
						includeField: false,
						onkey: function() { return true; },
						callback: function() { return true; }
					}, extendBy);
					
					settings.value = ( field.val().length > 0 ) ? field.val() : "";
					if (typeof callback == "function") settings.callback = callback;
					
					// Set ID if not present
					if (typeof field.attr("id") == "undefined") {
						field.attr("id", "vkinput_" + i + rand);
						settings.field = field.attr("id");
					} else {
						settings.field = field.attr("id");
					}
					
					// Load Keyboard
					field.attr("data-spawned", "true");
					VIC.buildKeyboard(settings);
					VIC.buildKeyboardEvents(settings);
				}
			});
			
		});
	}
	$.virtualKeyboard = function(params) {
		var settings = $.extend(true, {
			hint: "",
			symbols: true,
			numbers: true,
			letters: true,
			spaces: true,
			value: "",
			includeField: true,
			field: "vkinput_0000",
			onkey: function() { return true; },
			callback: function() { return true; }
		}, params);
		
		// Delete old nodes
		if (!VIC.keyboardSpawned) {
			$('.virtual_keyboard, .virtual_numpad').clearQueue().stop().finish().remove();
		}
		
		// Load Keyboard
		VIC.buildKeyboard(settings);
		VIC.buildKeyboardEvents(settings);
	}
	$.fn.virtualNumpad = function(callback, params) {
		var selector = $(this);
		
		return selector.each(function(i, e) {
			var caller = $(e);
			
			// Set Index
			var rand = Math.floor(Math.random() * 99999999) + 9999;
			caller.attr("data-index", i + rand);
			
			// Setup Events
			caller.unbind("vkevent");
			caller.bind("focus.vkevent", function(event) {
				var field = $(this);
				
				// Delete old nodes
				if (!VIC.numpadSpawned) {
					$('.virtual_keyboard, .virtual_numpad').clearQueue().stop().finish().remove();
					field.removeAttr("data-spawned");
				}
				
				// Only proceed if keyboard is not already in use
				if ( typeof field.attr("data-spawned") == "undefined" || field.attr("data-spawned") == "false" ) {
					
					// Extend Default Settings
					var settings = $.extend(true, {
						hint: "",
						decimal: false,
						wholenumber: false,
						mod: -1,
						autolength: -1,
						maxlength: -1,
						callback: function() { return true; },
						minimum: -1,
						maximum: -1,
						overide: false,
						secret: false,
						keypress: function() { return true; },
						forceCallback: false
					}, VIC.getAttributes(field));
					
					if (typeof params == "object") {
						settings = $.extend(true, settings, params);
					}
					
					if (settings.mod == "inherit") {
						settings.mod = field.data("mod");
					}
					
					settings.value = ( field.val().length > 0 ) ? field.val() : "";
					if (typeof callback == "function") settings.callback = callback;
					
					// Set ID if not present
					if (typeof field.attr("id") == "undefined") {
						field.attr("id", "vninput_" + i + rand);
						settings.field = field.attr("id");
					} else {
						settings.field = field.attr("id");
					}
					
					// Load Numpad
					if (field.data("spawned") != "true") {
						VIC.buildNumpad(settings);
						VIC.buildNumpadEvents(settings);
						field.attr("data-spawned", "true");
					}
				}
			});
			
		});
	}
	$.fn.virtualDate = function(callback, params) {
		var selector = $(this);
		
		return selector.each(function(i, e) {
			var caller = $(e);
			
			// Set Index
			var rand = Math.floor(Math.random() * 99999999) + 9999;
			caller.attr("data-index", i + rand);
			
			// Setup Events
			caller.unbind("vkevent");
			caller.bind("focus.vkevent", function(event) {
				var field = $(this);
				
				// Delete old nodes
				if (!VIC.dateSpawned) {
					$('.virtual_keyboard, .virtual_numpad').clearQueue().stop().finish().remove();
					field.removeAttr("data-spawned");
				}
				
				// Only proceed if keyboard is not already in use
				if ( typeof field.attr("data-spawned") == "undefined" || field.attr("data-spawned") == "false" ) {
					
					// Extend Default Settings
					var settings = $.extend(true, {
						future: true,
						past: true,
						includeField: false,
						hint: "",
						callback: function() { return true; }
					}, VIC.getAttributes(field));
					
					if (typeof params == "object") {
						settings = $.extend(true, settings, params);
					}
										
					settings.value = ( field.val().length > 0 ) ? field.val() : "";
					if (typeof callback == "function") settings.callback = callback;
					
					// Set ID if not present
					if (typeof field.attr("id") == "undefined") {
						field.attr("id", "vninput_" + i + rand);
						settings.field = field.attr("id");
					} else {
						settings.field = field.attr("id");
					}
					
					// Load Numpad
					if (field.data("spawned") != "true") {
						VIC.buildDate(settings);
						VIC.buildDateEvents(settings);
						field.attr("data-spawned", "true");
					}
				}
			});
			
		});
	}
	$.fn.virtualTime = function(callback, params) {
		var selector = $(this);
		
		return selector.each(function(i, e) {
			var caller = $(e);
			
			// Set Index
			var rand = Math.floor(Math.random() * 99999999) + 9999;
			caller.attr("data-index", i + rand);
			
			// Setup Events
			caller.unbind("vkevent");
			caller.bind("focus.vkevent", function(event) {
				var field = $(this);
				
				// Delete old nodes
				if (!VIC.dateSpawned) {
					$('.virtual_keyboard, .virtual_numpad').clearQueue().stop().finish().remove();
					field.removeAttr("data-spawned");
				}
				
				// Only proceed if keyboard is not already in use
				if ( typeof field.attr("data-spawned") == "undefined" || field.attr("data-spawned") == "false" ) {
					
					// Extend Default Settings
					var settings = $.extend(true, {
						includeField: true,
						hint: "",
						field: "vninput_0000",
						callback: function() { return true; }
					}, VIC.getAttributes(field));
					
					if (typeof params == "object") {
						settings = $.extend(true, settings, params);
					}
										
					settings.value = ( field.val().length > 0 ) ? field.val() : "";
					if (typeof callback == "function") settings.callback = callback;
					
					// Set ID if not present
					if (typeof field.attr("id") == "undefined") {
						field.attr("id", "vninput_" + i + rand);
						settings.field = field.attr("id");
					} else {
						settings.field = field.attr("id");
					}
					
					// Load Numpad
					if (field.data("spawned") != "true") {
						VIC.buildTime(settings);
						VIC.buildTimeEvents(settings);
						field.attr("data-spawned", "true");
					}
				}
			});
			
		});
	}
	$.virtualNumpad = function(params) {
		var settings = $.extend(true, {
			hint: "",
			decimal: false,
			wholenumber: false,
			mod: -1,
			autolength: -1,
			maxlength: -1,
			includeField: true,
			fields: [],
			field: "vninput_0000",
			callback: function() { return true; },
			minimum: -1,
			maximum: -1,
			overide: false,
			secret: false,
			keypress: function() { return true; },
			forceCallback: false
		}, params);
		
		// Delete old nodes
		if (!VIC.numpadSpawned) {
			$('.virtual_keyboard, .virtual_numpad').clearQueue().stop().finish().remove();
		}
		
		// Load Numpad
		VIC.buildNumpad(settings);
		VIC.buildNumpadEvents(settings);
	}
	$.virtualDate = function(params) {
		var settings = $.extend(true, {
			future: true,
			past: true,
			includeField: true,
			hint: "",
			callback: function() { return true; }
		}, params);
		
		// Delete old nodes
		if (!VIC.dateSpawned) {
			$('.virtual_keyboard, .virtual_numpad').clearQueue().stop().finish().remove();
		}
		
		// Load Numpad
		VIC.buildDate(settings);
		VIC.buildDateEvents(settings);
	}
	$.virtualTime = function(params) {
		var settings = $.extend(true, {
			includeField: true,
			hint: "",
			field: "vninput_0000",
			callback: function() { return true; }
		}, params);
		
		// Delete old nodes
		if (!VIC.dateSpawned) {
			$('.virtual_keyboard, .virtual_numpad').clearQueue().stop().finish().remove();
		}
		
		// Load Numpad
		VIC.buildTime(settings);
		VIC.buildTimeEvents(settings);
	}
})(jQuery);