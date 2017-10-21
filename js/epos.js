;(function($) {
    //'use strict';

    window.sound = function(name) {
    	new Audio('audio/' + name + '.mp3').play();
    }

    window.opt = window.optional = (object) => {
	    return new Proxy(object || {}, {
	        get: function(target, name) {
	            return (name in target)
	                ? target[name]
	                : null;
	        }
	    });
	}

	convertKeysToLowerCase = function(obj) {
	    var output = {};
	    for (i in obj) {
	        if (Object.prototype.toString.apply(obj[i]) === '[object Object]') {
	           output[i.toLowerCase()] = convertKeysToLowerCase(obj[i]);
	        } else if (Object.prototype.toString.apply(obj[i]) === '[object Array]'){
	            output[i.toLowerCase()] = [];
	            output[i.toLowerCase()].push(convertKeysToLowerCase(obj[i][0]));
	        } else {
	            output[i.toLowerCase()] = obj[i];
	        }
	    }
	    return output;
	};

	// Usage: cf('some.key.in.session').then(function(data) { ... });
	cf = function(key) {
		return new Promise(function(resolve, reject) {
			$.ajax({
				type: "POST",
				url: "ajax/cfcompiler.cfm",
				data: {key: key},
				success: function(data) {
					data = convertKeysToLowerCase(JSON.parse(data)).data;
					resolve(data);
				},
				error: function() {
					reject();
				}
			});
		});
	}

    ajax = {
    	// Usage Example: ajax.loadBasket({}, function(data) {alert(data)});
    	__compile: function() {
    		$.ajax({
				type: "GET",
				url: "ajax/ajaxcompiler.cfm",
				success: function(data) {
					var files = JSON.parse(data);
					for (var file in files) {
						eval("ajax['" + files[file].split('.')[0] + "'] = function(params, success, error) {\
							$.ajax({\
								type: 'POST',\
								url: 'ajax/" + files[file] + "',\
								data: params || {},\
								success: function(data) {\
									if (typeof success == 'function') success(data);\
								},\
								error: function() {\
									if (typeof error == 'function') error();\
								}\
							});\
						}");
					}
				}
			});
    	}
    }; ajax.__compile();

	raiseEvent = function(event, packet) {
		packet = JSON.parse(packet);
		window.events[packet.classname.toLowerCase()][event](packet.product);
	}

    openTillDrawer = function() {
    	ajax.openTillDrawer({}, function() {});
    }

    updateTillModeDisplay = function() {
    	cf('basket.info.mode').then(function(mode) {
    		$('.header_tabs li').removeClass('active');
			$('.header_tabs li[data-mode="' + mode + '"]').addClass('active');
    	});
    }

	window.barcode = "";
	window.epos_frame = {
		isStockControl: false,
		grocer_int: null,
		news_int: null,
		alerts: [],
		enableSupplier: true,
		barcode: "",
		handleAlerts: function() {
			var queue = [];

			notify = function() {
				if (queue.length > 0) {
					var curAlt = queue[0],
						timeout = null;

					$('body').prepend(
						'<div class="alert_notification"><span>' +
						curAlt + '</span></div>'
					);

					timeout = setTimeout(function() {
						window.epos_frame.alerts.splice( curAlt.indexOf() );
						queue.splice(0, 1);
						$('.alert_notification').remove();
						notify();
					}, 5000);
				}
			}

			initial = function() {
				for (var i = 0; i < window.epos_frame.alerts.length; i++) {
					setTimeout(function() {
						var a = window.epos_frame.alerts[i];

						var alt = getDateAttributes(a.ALTTIMESTAMP),
							now = getDateAttributes();

						if (a.ALTRECUR) {
							// Recurring
							if (
								alt.hour === now.hour &&
								alt.minute === now.minute
							) { queue.push(a.ALTCONTENT); }
						} else {
							// Non-Recurring
							if (
								alt.year === now.year &&
								alt.month === now.month &&
								alt.day === now.day
							) { queue.push(a.ALTCONTENT); }
						}

						queue.push(a.ALTCONTENT);
						notify();
					}, 5000);
				}
			}

			initial();
			setInterval(function() { initial(); }, 60000);
		}
	};

	guid = function() {
		function s4() {
			return Math.floor((1 + Math.random()) * 0x10000)
				.toString(16)
				.substring(1);
		}
		return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
			s4() + '-' + s4() + s4() + s4();
	}
//	$.ifBasketEmpty = function(a, b) {
//		$.ajax({
//			type: "GET",
//			url: "ajax/loadBasketCount.cfm",
//			success: function(data) {
//				var result = Number( data.trim() );
//				if (result <= 0) if (typeof a == "function") a();
//				if (result > 0) if (typeof b == "function") b();
//			}
//		});
//	}
	$.loadHome = function(a) {
		$.ajax({
			type: "GET",
			url: "ajax/loadHome.cfm",
			success: function(data) {
				$('.categories_viewer').html(data);
				if (typeof a == "function") a();
			}
		});
	}
	getDateAttributes = function(a) {
		var obj = {};

		if (typeof a == "undefined") {
			obj.date = new Date();
			obj.day = obj.date.getDate();
			obj.month = obj.date.getMonth() + 1;
			obj.year = obj.date.getFullYear();
			obj.hour = obj.date.getHours();
			obj.minute = obj.date.getMinutes();
		} else {
			obj.date = new Date(a);
			obj.day = obj.date.getDate();
			obj.month = obj.date.getMonth() + 1;
			obj.year = obj.date.getFullYear();
			obj.hour = obj.date.getHours();
			obj.minute = obj.date.getMinutes();
		}

		return obj;
	}
	getRotationDegrees = function(obj) {
		var matrix = obj.css("-webkit-transform") ||
			obj.css("-moz-transform")    ||
			obj.css("-ms-transform")     ||
			obj.css("-o-transform")      ||
			obj.css("transform");
			if (matrix !== 'none') {
				var values = matrix.split('(')[1].split(')')[0].split(',');
				var a = values[0];
				var b = values[1];
				var angle = Math.round(Math.atan2(b, a) * (180/Math.PI));
			} else { var angle = 0; }
		return angle;
	}
	arrayStructFind = function(arr, key, val) {
		for (var i = 0; i < arr.length; i++) {
			if ( arr[i][key] === val ) return i;
		}
	}
	$.ignoreTheseClicks = function(elArr, callback) {
		check = function(target) {
			var result = true;
			for (var i = 0; i < elArr.length; i++)
				if ( target.is($( elArr[i] )) || target.is($( elArr[i] ).find('*')) ) result = false;
			return result;
		}

		$(document).bind("mousedown.eventsGrp", function(event) {
			var target = $(event.target);
			if ( check( $(event.target) ) ) if (typeof callback == "function") callback(event);
		});
	}
	$.productSelect = function(params) {
		var delay = 250;
		$.ajax({
			type: "POST",
			url: "ajax/loadProductSelect.cfm",
			data: {"params": JSON.stringify(params)},
			beforeSend: function() {
				$('.product_selector').remove();
			},
			success: function(data) {
				$('body').prepend("<div class='product_selector vic_host' style='opacity:0;transform:scale(0);transform-origin:center;'><div class='inner'>" + data + "</div></div>");
				$('.product_selector').center("both", "fixed");
				$('.product_selector').addClass("reveal");
				$('.dark_dim').fadeIn(delay);

				setTimeout(function() {
					$(document).bind("mousedown.eventsGrp2", function(event) {
						var target = $(event.target);
						if (
							!target.is($('.sidepanel')) && !target.is($('.sidepanel').find('*')) &&
							!target.is($('.virtual_numpad')) && !target.is($('.virtual_numpad').find('*')) &&
							!target.is($('.virtual_keyboard')) && !target.is($('.virtual_keyboard').find('*')) &&
							!target.is($('.confirm_box')) && !target.is($('.confirm_box').find('*')) &&
							!target.is($('.product_selector')) && !target.is($('.product_selector').find('*')) &&
							!target.is($('.dark_dim')) && !target.is($('.dark_dim').find('*')) &&
							!target.is($('.touch_menu')) && !target.is($('.touch_menu').find('*'))
						) {
							$(document).unbind("mousedown.eventsGrp2");
							$('.product_selector').removeClass("reveal").addClass("hidden");
							$('.dark_dim').fadeOut(delay);
							setTimeout(function() { $('.product_selector, .dark_dim').remove(); }, delay);
							window.epos_frame.productSelectComplete = null;
						}
					});

					window.epos_frame["productSelectComplete"] = function(arr) {
						$(document).unbind("mousedown.eventsGrp2");
						setTimeout(function() {
							$('.product_selector').prepend("<div class='closing'><span class='icon-checkmark'></span></div>");
							$('.closing').slideDown(250);
							setTimeout(function() {
								$('.product_selector').removeClass("reveal").addClass("hidden");
								$('.dark_dim').fadeOut(delay);
								if (typeof params.callback == "function") params.callback(arr);
								setTimeout(function() { $('.product_selector, .dark_dim').remove(); }, delay);
								window.epos_frame.productSelectComplete = null;
							}, 1000);
						}, 250);
					}
				}, delay);
			}
		});
		return this;
	}
	$.formToStruct = function(arr, returntype) {
		var result = {};

		for (var i = 0; i < arr.length; i++) {
			$( arr[i] ).find('input, select').each(function(i, e) {
				if (typeof $(e).attr("name") != "undefined") result[ $(e).attr("name") ] = ( $(e).val().length > 0 ) ? $(e).val() : "";
			});
		}

		switch (returntype)
		{
			case "json":
				return JSON.stringify(result);
				break;
			default:
				return result;
				break;
		}
	}
	$.fn.hasLength = function() {
		var result = false;
		this.each(function(i, e) { if ( $(e).val().length > 0 ) result = true; else result = false; });
		return result;
	}
	$.infoMsg = function() {
		return $('.infomsg').each(function(i, e) {
			var $msg = $(e);

			$msg
				.attr("data-msg", $msg.html())
				.html("")
				.bind("click", function(event) {
					$.sidepanel( '<p class="infomsg-p">' + $msg.attr("data-msg") + '</p>', 360 );
				});
		});
	}
	$.appMsg = function(text, type, callback) {
		$('.app_message_box').remove();
		$('body').prepend("<div class='app_message_box'></div>");
		var settings = {delay: 3500, easing: 500};
		var box = $('.app_message_box');
		var background = (typeof type != "undefined" && type == "error") ? "rgba(173, 52, 52, 0.9)" : "rgba(139, 173, 52, 0.9)";

		box.html(text);
		box.css("background", background);
		if (typeof type == "undefined" || type != "error") box.addClass("user-background");
		box.animate({
			"bottom": 0
		}, settings.easing);

		setTimeout(function() {
			box.animate({
				"bottom": "-1000px"
			}, settings.easing, function() {
				if (typeof callback == "function") callback();
				box.remove();
			});
		}, settings.delay);
	}
	$.sidepanel = function(data, fixedwidth, pos, allowblur) {
		var usepos = pos || "right";
		var useblur = (typeof allowblur != "undefined") ? allowblur : true;
		$('.sidepanel').remove();
		$('body').prepend("<div class='sidepanel sidepanel_" + usepos + "'><div class='sidepanel_inner'></div></div>");
		$('.sidepanel').css( "width", (typeof fixedwidth == "undefined") ? ($(window).innerWidth() / 1.5) + "px" : fixedwidth + "px" );
		$('.sidepanel').addClass("sidepanel_open_" + usepos);
		$('.sidepanel_inner').html(data);
		// if (useblur) $('.home_screen_content').addClass("blur");

		$(document).bind("mousedown.eventsGrp", function(event) {
			var target = $(event.target);
			if (
				!target.is($('.sidepanel')) && !target.is($('.sidepanel').find('*')) &&
				!target.is($('.sidepanel_expansion')) && !target.is($('.sidepanel_expansion').find('*')) &&
				!target.is($('.virtual_numpad')) && !target.is($('.virtual_numpad').find('*')) &&
				!target.is($('.virtual_keyboard')) && !target.is($('.virtual_keyboard').find('*')) &&
				!target.is($('.confirm_box')) && !target.is($('.confirm_box').find('*')) &&
				!target.is($('.product_selector')) && !target.is($('.product_selector').find('*')) &&
				!target.is($('.dark_dim')) && !target.is($('.dark_dim').find('*')) &&
				!target.is($('.INTRO_tooltip')) && !target.is($('.INTRO_tooltip').find('*')) &&
				!target.is($('.INTRO_OutlineBox')) && !target.is($('.INTRO_OutlineBox').find('*')) &&
				!target.is($('.INTRO_admin')) && !target.is($('.INTRO_admin').find('*')) &&
				!target.is($('.popup_box')) && !target.is($('.popup_box').find('*')) &&
				!target.is($('.touch_menu')) && !target.is($('.touch_menu').find('*'))
			) {
				$('.sidepanel').removeClass("sidepanel_open_" + usepos);
				$('.sidepanel_expansion').remove();
				$('.home_screen_content').removeClass("blur");
			}
		});

		return this;
	}
	$.sidepanel.expand = function(params) {
		var settings = $.extend(true, {
			pos: "right",
			width: "100%",
			content: "",
			callback: function() { return true; }
		}, params);

		var sidepanelWidth = $('.sidepanel').outerWidth();
		var windowWidth = $(window).innerWidth();
		var expandSpace = windowWidth - sidepanelWidth;

		$('.sidepanel_expansion').remove();

		$('body').prepend(
			'<div class="sidepanel_expansion"><div class="sidepanel_expansion_inner">'+
			'<span class="sidepanel_expansion_close close-button scalebtn">x</span>' + settings.content + '</div></div>'
		);

		$('.sidepanel_expansion').css({
			"right": (settings.width == "100%") ? 0 : settings.width,
			"left": sidepanelWidth
		});

		$('.sidepanel_expansion_close').bind("click", function(event) {
			$('.sidepanel_expansion').remove();
		});
	}
	$.sidepanel.close = function(a) {
		$('.sidepanel').removeClass("sidepanel_open_right sidepanel_open_left");
		$('.home_screen_content').removeClass("blur");
		if (typeof a == "function") a();
	}
	$.sidepanel.next = function(content) {
		$('.sidepanel_page').remove();
		$('.sidepanel').append('<div class="sidepanel_page"><div class="sidepanel_page_inner">'+
		'<span class="sidepanel_page_back icon-undo2 scalebtn"></span>' + content + '</div></div>');
		$('.sidepanel_inner').animate({ "margin-left": -( $('.sidepanel_inner').outerWidth() ) }, 500, "easeInOutCubic");
		$('.sidepanel_page').animate({ "margin-left": 0 }, 500, "easeInOutCubic");

		$('.sidepanel_page_back').bind("click", function(event) {
			$('.sidepanel_inner').animate({ "margin-left": 0 }, 500, "easeInOutCubic");
			$('.sidepanel_page').animate({ "margin-left": $('.sidepanel_page').outerWidth() }, 500, "easeInOutCubic");
		});
	}
	$.emptyBasket = function() {
		$.get("ajax/emptyBasket.cfm", function(data) {
			$.loadBasket();
		});
	}
	$.fn.newsStories = function() {
		var caller = this;
		var delay = 10000;
		clearInterval(window.epos_frame.news_int);

		loadStory = function() {
			$.ajax({
				type: "GET",
				url: "ajax/loadNewsStory.cfm",
				success: function(data) {
					var result = data.toJava();
					caller.html('<div><p>' + result.content + '</p></div>');
				}
			});
		}

		loadStory();

		/*window.epos_frame.news_int = setInterval(function() {
			loadStory();
		}, delay);*/
	}
	$.fn.barcodeBox = function(callback) {
		var selector = $(this);

		return selector.each(function(i, e) {
			var caller = $(e);
			var scanning = false;

			caller.bind("click", function(event) {
				scanning = true;
				caller.html("Waiting for barcode");
				$.scanBarcode({
					callback: function(barcode) {
						if (scanning) {
							caller.html(barcode);
							scanning = false;
							if (typeof callback == "function") callback(barcode);
							caller.clearQueue().stop().finish();
						}
					}
				});
				event.preventDefault();
			});
		});
	}
	$.fn.booleanResponse = function(file, cons) {
		var selector = $(this);
		var conswitch = cons || true;

		return selector.each(function(i, e) {
			var caller = $(e);

			caller.bind("focus", function(event) {
				if (caller.val().length > 0 && conswitch) {
					$.ajax({
						type: "POST",
						url: file,
						data: {"value": caller.val()},
						success: function(data) {
							var response = ( data.trim() == "true" ) ? true : false;
							if (response) {
								caller.addClass("boolean_response_true");
							} else {
								caller.removeClass("boolean_response_true");
							}
						}
					});
				} else {
					caller.removeClass("boolean_response_true");
				}
			});
		});
	}
	$.openTill = function() {
		ajax.openTillDrawer({}, function(data) {
			$('.printable').html(data);
		});
	}
	$.printReceipt = function() {
		$.ajax({
			type: "POST",
			url: "ajax/printReceipt.cfm",
			data: {},
			success: function(data) {
				$('.printable').html(data);
			}
		});
	}
	$.calendar = function(year, month, callback) {
		$.ajax({
			type: "POST",
			url: "ajax/loadCalendar.cfm",
			data: {
				"cyear": year,
				"cmonth": month
			},
			success: function(data) {
				if (typeof callback == "function") callback(data);
			}
		});
	}
	$.fullscreenPopup = function(content) {
		$('.fullscreen_popup_box').remove();
		$('body').prepend("<div class='fullscreen_popup_box'>" + content + "</div>");

		var box = $('.fullscreen_popup_box');

		var counter = 0;
		var grow = null;
		grow = setInterval(function() {
			counter += 0.1;
			box.css({
				"transform": "scale3d(" + counter + ", " + counter + ", " + counter + ")",
				"opacity": counter
			});
			if (counter >= 1) {
				clearInterval(grow);
				box.css("transform", "scale3d(1, 1, 1)");
			}
		}, 15);
	}
	$.popup = function(content, confirmation) {
		$('.popup_box, .dim').remove();
		$('body').prepend("<div class='dim'></div><div class='popup_box'>" + content + "</div>");

		var box = $('.popup_box');
		var dim = $('.dim');
		box.center();
		dim.fadeIn();

		var counter = 0;
		var grow = null;
		grow = setInterval(function() {
			counter += 0.1;
			box.css({
				"transform": "scale3d(" + counter + ", " + counter + ", " + counter + ")",
				"opacity": counter
			});
			if (counter >= 1) {
				clearInterval(grow);
				box.css("transform", "scale3d(1, 1, 1)");
			}
		}, 15);

		box.htmlClick(function() {
			if (typeof confirmation == "undefined" || !confirmation) {
				dim.fadeOut();
				var counter = 1;
				var shrink = null;
				shrink = setInterval(function() {
					counter -= 0.1;
					box.css({
						"transform": "scale3d(" + counter + ", " + counter + ", " + counter + ")",
						"opacity": counter
					});
					if (counter <= 0) {
						clearInterval(shrink);
						box.remove();
					}
				}, 15);
			}
		});
	}
	$.popup.close = function() {
		var box = $('.popup_box');
		var dim = $('.dim');
		dim.fadeOut();
		var counter = 1;
		var shrink = null;
		shrink = setInterval(function() {
			counter -= 0.1;
			box.css({
				"transform": "scale3d(" + counter + ", " + counter + ", " + counter + ")",
				"opacity": counter
			});
			if (counter <= 0) {
				clearInterval(shrink);
				box.remove();
			}
		}, 15);
	}
	$.bigDatePicker = function() {
		$('.big_datepicker_backdrop').remove();
		$('body').prepend("<div class='big_datepicker_backdrop'><div class='bdp_inner'></div></div>");

		var now = new Date();
		var today = {
			day: now.getDate(),
			month: now.getMonth() + 1,
			year: now.getFullYear()
		};

		var selected = {
			day: today.day,
			month: today.month,
			year: today.year
		};

		highlightSelected = function() {
			var scope = $('.bdp_scope');
			var selDay = $('.bdp_days').find('li[data-value="' + selected.day + '"]');
			var selMonth = $('.bdp_months').find('li[data-value="' + selected.month + '"]');
			var selYear = $('.bdp_years').find('li[data-value="' + selected.year + '"]');

			var frameHeight = $(window).innerHeight();
			var scopeTop = scope.offset().top;

			// Days
			$('.bdp_days').find('li').removeClass("bdp_selected");
			$('.bdp_days').find('li[data-value="' + selected.day + '"]').addClass("bdp_selected");
			var selDayTop = selDay.offset().top;
			var selDayHeight = selDay.height();
			var listBottom = frameHeight - (selDayTop + selDayHeight);
			var difference = ((frameHeight / 2) - listBottom - (selDayHeight / 2)) * -1;
			$('.bdp_days').css("top", difference);

			// Months
			$('.bdp_months').find('li').removeClass("bdp_selected");
			$('.bdp_months').find('li[data-value="' + selected.month + '"]').addClass("bdp_selected");
			var selMonthTop = selMonth.offset().top;
			var selMonthHeight = selMonth.height();
			var listBottom = frameHeight - (selMonthTop + selMonthHeight);
			var difference = ((frameHeight / 2) - listBottom - (selMonthHeight / 2)) * -1;
			$('.bdp_months').css("top", difference);

			// Years
			$('.bdp_years').find('li').removeClass("bdp_selected");
			$('.bdp_years').find('li[data-value="' + selected.year + '"]').addClass("bdp_selected");
			var selYearTop = selYear.offset().top;
			var selYearHeight = selYear.height();
			var listBottom = frameHeight - (selYearTop + selYearHeight);
			var difference = ((frameHeight / 2) - listBottom - (selYearHeight / 2)) * -1;
			$('.bdp_years').css("top", difference);
		}

		daysInMonth = function(month, year) {
			return new Date(year, month, 0).getDate();
		}

		getDays = function() {
			var result = "";
			var end = daysInMonth(selected.month, selected.year);

			for (var i = 1; i < end; i++) {
				result += "<li data-part='day' data-value='" + i + "'>" + zeroPad(i, 2) + "</li>";
			}

			return result;
		}

		getMonths = function() {
			var result = "";

			for (var i = 0; i < 11; i++) {
				result += "<li data-part='month' data-value='" + (i + 1) + "'>" + zeroPad( (i + 1), 2 ) + "</li>";
			}

			return result;
		}

		getYears = function(a) {
			var result = "";
			var start = today.year - a;
			var end = today.year + a;

			for (var i = start; i < end; i++) {
				result += "<li data-part='year' data-value='" + i + "'>" + i + "</li>";
			}

			return result;
		}

		$('.big_datepicker_backdrop .bdp_inner').append("<ul class='bdp_days'>" + getDays() + "</ul>");
		$('.big_datepicker_backdrop .bdp_inner').append("<ul class='bdp_months'>" + getMonths() + "</ul>");
		$('.big_datepicker_backdrop .bdp_inner').append("<ul class='bdp_years'>" + getYears(10) + "</ul>");
		$('.big_datepicker_backdrop .bdp_inner').center();

		$('body').prepend("<div class='bdp_scope'></div>");
		$('.bdp_scope').center("top");

		highlightSelected();

		var mouseDown = false;
		var mouseY = 0;

		$(document).bind("mousedown", function(event) {
			mouseDown = true;
			mouseY = event.pageY;
		});

		$(document).bind("mouseup", function(event) {
			mouseDown = false;
			mouseY = 0;
		});

		$(document).bind("mousemove", function(event) {
			if (mouseDown) {
				var target = $(event.target);

				if ( target.is($('.bdp_days')) || target.is($('.bdp_days').find('*')) ) {
					var curMouseY = event.pageY;
					var distance = curMouseY - mouseY;
					var winHeight = $(window).innerHeight();
					var winScrollTop = $(window).scrollTop();
					var curHeight = $('.bdp_days').height();
					var curTop = $('.bdp_days').css("top").replace("px", "");
					var curBottom = winHeight - curTop - curHeight;
					var excess = $(window).innerHeight() - curMouseY;
					var newTop = curTop - (distance * -1);
					$('.bdp_days').css("top", newTop);

					$('.bdp_days').find('li').each(function(i, e) {
						console.log($(e).offset().top);
						if ( $(e).offset().top <= 0 ) {
							$(e).appendTo($('.bdp_days'));
						} else if ( $(e).offset().top >= winHeight ) {
							$(e).prependTo($('.bdp_days'));
						}
					});

					/*if (newTop < -25) {
						console.log("Point A");
						if (curBottom < -25) {
							console.log("Point B");
							$('.bdp_days').css("top", newTop)
						}
					} else if (curBottom < -25) {
						console.log("Point C");
						if (newTop < -25) {
							console.log("Point D");
							$('.bdp_days').css("top", newTop)
						}
					}*/

					mouseY = curMouseY;
				}
			}
		});
	}
	zeroPad = function(num, places) {
		var zero = places - num.toString().length + 1;
		return Array(+(zero > 0 && zero)).join("0") + num;
	}
	componentToHex = function(c) {
		var hex = c.toString(16);
		return hex.length == 1 ? "0" + hex : hex;
	}

	rgbToHex = function(r, g, b) {
		return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
	}
	$.fn.currentTime = function(a) {
		var caller = $(this);
		setInterval(function() {
			var d = new Date();
			var str = (typeof a != "undefined" && a === 1) ?
				('0' + d.getHours()).slice(-2) + ":" + ('0' + d.getMinutes()).slice(-2) + ":" + ('0' + d.getSeconds()).slice(-2) :
				('0' + d.getHours()).slice(-2) + ":" + ('0' + d.getMinutes()).slice(-2);
			caller.html(str);
		}, 1000);
	}
	$.confirmation = function(message, callback, cancel) {
		$('.confirm_box').remove();
		$('.dim').remove();

		var useMessage = (typeof message == "string") ? message : "Are you sure?";
		var justOk = (typeof cancel == "boolean") ? cancel : false;

		window.confirmationCallback = function(a) {
			$('.confirm_box').fadeOut(200, function() {$('.confirm_box').remove();});
			$('.dim').fadeOut(200, function() {$('.dim').remove();});

			switch (a)
			{
				case 1:
					if (typeof message == "function") message();
					else if (typeof callback == "function") callback();
					break;
				case 2:
					if (typeof cancel == "function") cancel();
					break;
			}

		}

		var buttonHTML = (justOk) ? "<button class='scalebtn' onclick='window.confirmationCallback(1)' style='width:290px;margin:0 auto;float:none;'>Ok</button>" : "<button class='scalebtn' onclick='window.confirmationCallback(1)' style='float:left;width:290px;'>Yes</button><button class='scalebtn' onclick='window.confirmationCallback(2)' style='width:290px;'>No</button>";

		$('body').prepend("<div class='dim'></div>");
		$('body').prepend("<div class='confirm_box'><div class='confirm_box_inner'><p>" + useMessage + "</p>" + buttonHTML + "</div></div>");

		$('.confirm_box').center("top");
		$('.confirm_box').fadeIn(200);
		$('.dim').fadeIn(200);
	}
	$.addCharge = function(params) {
		$.ajax({
			type: "POST",
			url: "ajax/addCharge.cfm",
			data: params,
			success: function(data) {
				$.loadBasket();
			}
		});
	}
	$.addDiscount = function(params) {
		$.ajax({
			type: "POST",
			url: "ajax/addDiscount.cfm",
			data: params,
			success: function(data) {
				$.loadBasket();
			}
		});
	}
	$.addPayment = function(params, callback) {
		$.ajax({
			type: "POST",
			url: "ajax/addPayment.cfm",
			data: params,
			success: function(data) {
				// sound('added');
				var closeTranNow = (data.trim().toLowerCase() == "yes") ? true : false;

				if (closeTranNow) {
					ajax.openTillDrawer({}, function(data) {
						$('.printable').html(data);
					});
				}

				if (typeof callback == "function") callback(params);
			}
		});
	}
	$.addItem = function(params, callback) {
		$.ajax({
			type: "POST",
			url: "ajax/addItem.cfm",
			data: params,
			success: function(data) {
				sound('added');
				if (typeof callback == "function") callback(params);
			}
		});
	}
	$.fn.loadPayments = function() {
		var caller = $(this);
		$.ajax({
			type: "GET",
			url: "ajax/loadPayments.cfm",
			success: function(data) {
				caller.html(data);
			}
		});
	}
	$.fn.buttonSelect = function(a) {
		var caller = $(this);
		caller.find('li').each(function(i, e) {
			var selected = $(this).data("selected");
			if (typeof selected != "undefined") {
				caller.find('li').removeClass("active_button");
				$(a).val( $(e).html().trim() );
				$(e).addClass("active_button");
			}
		});
		caller.find('li').bind("click", function(event) {
			caller.find('li').removeClass("active_button");
			$(a).val( $(this).html().trim() );
			$(this).addClass("active_button");
		});
	}
	$.openCategory = function(catID) {
		$.ajax({
			type: "POST",
			url: "ajax/productsByCategory.cfm",
			data: {"catID": catID},
			success: function(data) {

			}
		});
	}
	String.prototype.containsSpace = function(){
		return /[\s]/.test(this);
	}
	String.prototype.isSymbol = function() {
		return /[$-/:-?{-~!""^_`\[\]]/.test(this);
	}
	String.prototype.isNumber = function() {
		return /^([-\d]|\.)+$/.test(this);
	}
	String.prototype.isBoolean = function() {
		if (this == "true" || this == "false") return true; else return false;
	}
	String.prototype.isEncoded = function() {
		console.log(decodeURIComponent(this));
		return decodeURIComponent(this) !== this;
	}
	String.prototype.toJava = function() {
		var a = this;
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
	}
	getDataAttributes = function(node, type, extended) {
		var d = {}, re_dataAttr = /^data\-(.+)$/;
		$.each(node.get(0).attributes, function(index, attr) {
			if (re_dataAttr.test(attr.nodeName)) {
				var key = attr.nodeName.match(re_dataAttr)[1];
				var isNum = attr.value.isNumber();
				var isBool = attr.value.isBoolean();

				if (typeof type != "undefined" && type == "plain") {
					var value = attr.value;
				} else {
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
				}

				d[key] = value;
			}
		});

		if (typeof type == "undefined") {
			return d;
		} else {
			switch (type)
			{
				case "html":
					var retStr = "";
					for (var k in d) {
						var itStr = " data-" + k + "='" + d[k] + "'";
						retStr += itStr;
					}
					return retStr;
					break;
				case "plain":
					if (typeof extended == "object") {
						var object = $.extend(d, extended);
						return object;
					} else {
						return d;
					}
					break;
			}
		}
	}
	loadSessionVAT = function(rate) {
		var result = "";
		$.ajax({
			type: "POST",
			url: "#request.url#ajax/loadSessionVAT.cfm",
			data: {"vatRate": rate},
			success: function(data) {
				var result = data.trim();
			}
		});
		return result;
	}

	window.eposScanningBarcode = false;
	$.searchBarcode = function(barcode, callback) {
		if (window.eposScanningBarcode) return;
		window.eposScanningBarcode = true;

		$.msgBox("Processing..", "success");

		callback = callback || function () {};

		$.ajax({
			type: "POST",
			url: "ajax/searchBarcode.cfm",
			data: {"barcode": barcode},
			success: function(data) {
				window.eposScanningBarcode = false;
				var result = JSON.parse(data);
				if (typeof result.PRODID != "undefined") {
					var price = (typeof result.ENCODEDVALUE != "undefined" && Math.abs(result.ENCODEDVALUE) > 0) ? result.ENCODEDVALUE : result.SIOURPRICE;
					if (price == 0) price = result.PRODOURPRICE;
					if (result.ENCODEDVALUE < 0) {
						$.addItem({
							account: "",
							addtobasket: true,
							btnsend: "Add",
							cash: result.ENCODEDVALUE,
							cashonly: 1,
							credit: "",
							prodid: "",
							pubid: "",
							prodtitle: result.PRODTITLE,
							prodsign: result.PRODSIGN,
							qty: 1,
							type: "VOUCHER",
							vrate: ""
						}, function() { $.loadBasket(); callback(); });
					} else {
						$.addToBasket({
							account: "",
							addtobasket: "true",
							btnsend: "Add",
							class: "item",
							discount: "0",
							discountable: result.PRODSTAFFDISCOUNT,
							prodid: result.PRODID,
							pubid: "1",
							prodtitle: result.PRODTITLE,
							prodsign: result.PRODSIGN,
							prodClass: result.PRODCLASS,
							qty: "1",
							itemclass: result.EPCKEY,
							vcode: loadSessionVAT(result.PRODVATRATE),
							vrate: result.PRODVATRATE,
							cashonly: result.PRODCASHONLY,
							cash: (result.PRODCASHONLY == 1) ? price : 0,
							credit: (result.PRODCASHONLY == 1) ? 0 : price,
							unitTrade: result.SIUNITTRADE
						}, callback);
					}
				} else {
					$.msgBox("Product not found", "error");
				}
			}
		});
	}
	$.stockControlScanner = function(a, b) {
		var code = window.epos_frame.barcode;
		if (a.keyCode == 13) {
			if (code.length >= 8 & code.length <= 14) {
				b(window.epos_frame.barcode);
			}
			window.epos_frame.barcode = "";
		} else {
		//	var newStr = (code != "") ? code + String.fromCharCode(a.keyCode) : String.fromCharCode(a.keyCode);
			var newStr = (code != "") ? code + String.fromCharCode(a.charCode) : String.fromCharCode(a.charCode);
			window.epos_frame.barcode = newStr;
		}
	}
	$.scanner = function(a, b) {
		try {
			if (a.keyCode == 13) {
				console.log(window.barcode);
				if (window.barcode.length >= 8 && window.barcode.length <= 14) {
					if (typeof b == "function") b(window.barcode);
				} else {
					console.log("else: " + window.barcode);
				}
				window.barcode = "";
			} else if (a.charCode != 0) {
			//	console.log("keycode "+a.charCode);
				if (typeof window.barcode == "undefined") window.barcode = "";
				window.barcode += (String.fromCharCode(a.charCode) + "");
			//	console.log(window.barcode);
			//	window.barcode += (String.fromCharCode(a.keyCode) + "");
			} else {
				console.log("invalid keycode "+a.charCode);
			}
		} catch (error) {
			console.log(error);
		}
	}

	$.scanBarcode = function(params) {
		if (typeof params.preinit == "function") params.preinit();
		$(document).bind("keypress.scanBarcodeEvent", function(event) {
			try {
				if (!($('input').is(":focus"))) {
					$.scanner(event, function(barcode) {
						if (typeof params.callback == "function") params.callback(barcode);
						if (params.unbindOnCallback || false) $(document).unbind("keypress.scanBarcodeEvent");
					});
				} else {
					window.barcode = "";
				}
			} catch (error) {
				console.log(error);
			}
		});
		if (typeof params.postinit == "function") params.postinit();
	}
	$.loadBasket = function(a) {
		$.ajax({
			type: "GET",
			url: "ajax/loadBasket.cfm",
			success: function(data) {
				$('.basket').html(data);
				if (typeof a == "function") a();
			}
		});
	}

	$.addToBasket = function(params, callback) {
		callback = callback || function() {};

		$.ajax({
			type: "POST",
			url: "ajax/addToBasket.cfm",
			data: params,
			success: function(data) {
				sound('added');
				raiseEvent('onAdded', data);
				$.loadBasket();
				callback();
			}
		});
	}
	$.tillNumpad = function(a) {
		$('.till_numpad span[data-method="enter"]').unbind("click");
		$('.till_numpad span[data-method="enter"]').bind("click", function(event) {
			var value = (Number($('.tn_value').html()) / 100).toFixed(2);
			if (typeof a == "function") a(value);
		});
	}
	tillFormat = function(a) {
		return (Number(a) / 100).toFixed(2);
	}
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
	}
	$.fn.center = function(a, b) {
		var caller = $(this);
		caller.css("position", b || "absolute");

		switch(a || "both")
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
	}
	cut = function(str, cutStart, cutEnd) {
	  return str.substr(0, cutStart) + str.substr(cutEnd + 1);
	}
	$.fn.htmlClick = function(a) {
		var caller = $(this);
		$(document).bind("mousedown.eventsGrp", function(event) {
			var target = $(event.target);
			if (!target.is(caller) && !target.is(caller.find('*')))
				if (typeof a == "function") a();
		});
	}
	$.fn.htmlRemove = function(a) {
		var caller = $(this);
		$(document).bind("mousedown.eventsGrp", function(event) {
			var target = $(event.target);
			if (!target.is(caller) && !target.is(caller.find('*'))) {
				caller.remove();
				if (typeof a == "function") a(target);
			}
		});
	}
	setCaretPosition = function(elemId, caretPos) {
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
	}
	getCaretPosition = function(oField) {
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
	}
	insertAtCaret = function(areaId, text) {
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
	}
	$.fn.FCDatePicker = function(changed) {
		var iArray = [];
		var now = new Date();
		var placeholder = zeroPad(now.getDate(), 2) + "/" + zeroPad((now.getMonth() + 1), 2) + "/" + now.getFullYear();
		$(this).each(function(index, element) {
			var caller = $(element);
			iArray.push(index);
			caller
				.val(placeholder)
				.attr("data-dpindex", index)
			caller.bind("focus", function(event) {
				$('.FCDatePickerPopup').htmlClick(function() {
					$('.FCDatePickerPopup').hide();
				});
				$('.FCDatePickerPopup')
					.hide()
					.show()
					.attr("data-dpindex", $(this).attr("data-dpindex"));
				$('.FCDatePickerPopup').css({
					"left": caller.offset().left,
					"top": caller.offset().top + caller.height() + 5
				});
			});
		});
		setDatePickerValue = function(date, i) {
			var dateArr = date.split("/");
			$('.FCDatePicker[data-dpindex="' + iArray[i] + '"]').val( zeroPad(dateArr[2], 2) + "/" + zeroPad(dateArr[1], 2) + "/" + dateArr[0] );
			if (typeof changed == "function") {
				changed('.FCDatePicker[data-dpindex="' + iArray[i] + '"]');
			}
		}
		window.setDatePickerValue = setDatePickerValue;
	}
	$.fn.gravity = function(gHost, whiteFlyout, prefPos, offset, allowFlyout) {
		var caller = $(this),
			host = $(gHost);
		var callerHeight = caller.height();
		var padding = {
			top: Number(host.css("padding-top").replace("px", "")),
			bottom: Number(host.css("padding-bottom").replace("px", "")),
			left: Number(host.css("padding-left").replace("px", "")),
			right: Number(host.css("padding-right").replace("px", ""))
		};
		if (typeof whiteFlyout != "undefined" && whiteFlyout) {
			var flyouts = {
				n: "FCFlyoutNorth_White",
				s: "FCFlyoutSouth_White",
				e: "FCFlyoutEast_White",
				w: "FCFlyoutWest_White"
			};
		} else {
			var flyouts = {
				n: "FCFlyoutNorth",
				s: "FCFlyoutSouth",
				e: "FCFlyoutEast",
				w: "FCFlyoutWest"
			};
		}
		var excessNorth = host.offset().top,
			excessSouth = window.innerHeight - (host.offset().top + host.height()),
			excessEast = window.innerWidth - (host.offset().left + host.width()),
			excessWest = host.offset().left;
		var excessArray = [excessNorth, excessSouth, excessEast, excessWest];
		var mostSpace = Math.max.apply(Math, excessArray);
		var recommendedDir = mostSpace;
		var useDir = null;
		var offsetToUse = (typeof offset == "undefined") ? 20 : Number(offset);
		var showFlyout = (typeof allowFlyout != "undefined") ? allowFlyout : true;
		switch (mostSpace)
		{
			case excessNorth:
				useDir = 'north';
				break;
			case excessSouth:
				useDir = 'south';
				break;
			case excessEast:
				useDir = (excessSouth >= caller.height() && excessNorth >= caller.height()) ? 'east' : (excessNorth > excessSouth) ? 'north' : 'south';
				break;
			case excessWest:
				useDir = (excessSouth >= caller.height() && excessNorth >= caller.height()) ? 'west' : (excessNorth > excessSouth) ? 'north' : 'south';
				break;
		}

		var keys = {
			north: excessNorth,
			south: excessSouth,
			east: excessEast,
			west: excessWest
		};

		if (typeof prefPos != "undefined") {
			if (prefPos != "auto") {
				if (keys[prefPos] > callerHeight) {
					useDir = prefPos;
				} else {
					if (keys[prefPos] < recommendedDir) {
						switch (prefPos)
						{
							case "north":
								useDir = "south";
								break;
							case "south":
								useDir = "north";
								break;
							case "east":
								useDir = "west";
								break;
							case "west":
								useDir = "east";
								break;
						}
					} else {
						useDir = prefPos;
					}
				}
			}
		}

		switch (useDir)
		{
			case 'north':
				$('.' + flyouts.n).remove();
				if (showFlyout) {
					caller.prepend("<div class='" + flyouts.n + "'></div>");
					var flyoutNorth = $('.' + flyouts.n);
					flyoutNorth.css({
						"width": caller.width(),
						"margin-top": caller.height() - 1
					});
				}
				caller.css({
					"left": excessWest - (caller.width() / 2) + (host.width() / 2),
					"top": excessNorth - caller.height() - offsetToUse
				});
				break;
			case 'south':
				$('.' + flyouts.s).remove();
				if (showFlyout) {
					caller.prepend("<div class='" + flyouts.s + "'></div>");
					var flyoutSouth = $('.' + flyouts.s);
					flyoutSouth.css({
						"width": caller.width(),
						"margin-top": "-8px"
					});
				}
				caller.css({
					"left": excessWest - (caller.width() / 2) + (host.width() / 2),
					"top": excessNorth + host.height() + offsetToUse + (padding.bottom + padding.top)
				});
				break;
			case 'east':
				$('.' + flyouts.e).remove();
				if (showFlyout) {
					caller.prepend("<div class='" + flyouts.e + "'></div>");
					var flyoutEast = $('.' + flyouts.e);
					flyoutEast.css({
						"height": caller.height(),
						"margin-left": "-8px"
					});
				}
				caller.css({
					"left": excessWest + host.width() + offsetToUse,
					"top": excessNorth - (caller.height() / 2) + (host.height() / 2)
				});
				break;
			case 'west':
				$('.' + flyouts.w).remove();
				if (showFlyout) {
					caller.prepend("<div class='" + flyouts.w + "'></div>");
					var flyoutWest = $('.' + flyouts.w);
					flyoutWest.css({
						"height": caller.height(),
						"margin-left": caller.width() - 1
					});
				}
				caller.css({
					"left": excessWest - caller.width() - offsetToUse,
					"top": excessNorth - (caller.height() / 2) + (host.height() / 2)
				});
				break;
		}
	}
	$.fn.touchHold = function(a) {
		var caller = $(this), width = 400, delay = 1;

		if ($.contains(document, caller[0])) {
			caller.on("click", function() {
				var me = $(this);
				me.addClass("active");
				var attributes = getDataAttributes(me, "plain");
				console.log(attributes);
				window.touchtime = setTimeout(function() {
					window.touchhold = true;
					window.touchHoldAction = function(index) {
						a[index].action(attributes, me);
						$('.touch_menu').remove();
					}
					//me.removeClass("active");
					var listStr = "";
					for (var i = 0; i < a.length; i++) {
						var b = a[i];
						a[i].index = i;
						if (typeof b.action == "function")
							listStr += "<li onclick='javascript:window.touchHoldAction(" + i + ");'>" + b.text + "</li>";
					}
					$('body').prepend("<ul class='touch_menu'><div class='touch_menu_inner'>" + listStr + "</div></ul>");
					if ($.contains(document, $('.touch_menu')[0])) {
						var menuHalfWidth = width / 2;
						$('.touch_menu').htmlRemove(function() {
							me.removeClass("touch_menu_active");
							me.removeClass("active");
						});
						$('.touch_menu').gravity(me, false, "south", 2, false);
						$('.touch_menu').css("left", (me.offset().left/* - menuHalfWidth + me.width() / 2*/));

						$('.touch_menu').show().animate({
							"width": me.outerWidth()/*width*/ + "px"
						}, 500, 'easeInOutCubic');

						me.addClass("touch_menu_active");
					}

				}, delay);
			});

			caller.on("mouseup mouseleave", function() {
				clearTimeout(window.touchtime);
			});

			/*$(document).bind("click", function() {
				window.touchtime = 0;
				window.touchhold = false;
			});*/
		}
	}
	$.fn.iconOptions = function(a, callback, restore) {
		var me = $(this), caller = $(this), width = 400, delay = 1;

		me.addClass("active");
		window.touchtime = setTimeout(function() {
			window.touchhold = true;
			window.touchHoldAction = function(index) {
				a[index].action(attributes, me);
				$('.touch_menu').remove();
				if (typeof restore == "function") restore();
			}
			me.removeClass("active");
			var listStr = "";
			var attributes = getDataAttributes(me);
			for (var i = 0; i < a.length; i++) {
				var b = a[i];
				a[i].index = i;
				if (typeof b.action == "function")
					listStr += "<li onclick='javascript:window.touchHoldAction(" + i + ");' class='scalebtn'><span class='icon-" + b.icon + "'></span></li>";
			}

			var timeoutval = caller.hasClass("scalebtn") ? 150 : 1;

			setTimeout(function() {
				$('body').prepend("<ul class='touch_menu tm_icon'><div class='touch_menu_inner'>" + listStr + "</div></ul>");
				if ($.contains(document, $('.touch_menu')[0])) {
					var menu = $('.touch_menu');
					var menuHalfWidth = width / 2;

					menu.htmlRemove(function() {
						me.removeClass("touch_menu_active");
					});

					menu.gravity(me, false, "south", 2, false);
					menu.css("left", (me.offset().left));

					var orig_top = menu.offset().top;

					menu
						.show()
						.css({
							"width": me.outerWidth() + "px",
							"top": me.offset().top,
							"opacity": 0
						})
						.animate({
							"top": ( me.offset().top + me.outerHeight() ),
							"opacity": 1
						}, 500, "easeOutBounce");

					me.addClass("touch_menu_active");

					if (typeof callback == "function") callback();
				}
			}, timeoutval);

		}, delay);
	}
	$.fn.touchHoldIcon = function(a, callback, restore) {
		var caller = $(this), width = 400, delay = 1;

		if ($.contains(document, caller[0])) {
			caller.on("click", function() {
				var me = $(this);
				me.addClass("active");
				window.touchtime = setTimeout(function() {
					window.touchhold = true;
					window.touchHoldAction = function(index) {
						a[index].action(attributes, me);
						$('.touch_menu').remove();
						if (typeof restore == "function") restore();
					}
					me.removeClass("active");
					var listStr = "";
					var attributes = getDataAttributes(me);
					for (var i = 0; i < a.length; i++) {
						var b = a[i];
						a[i].index = i;
						if (typeof b.action == "function")
							listStr += "<li onclick='javascript:window.touchHoldAction(" + i + ");' class='scalebtn'><span class='icon-" + b.icon + "'></span></li>";
					}

					var timeoutval = caller.hasClass("scalebtn") ? 150 : 1;

					setTimeout(function() {
						$('body').prepend("<ul class='touch_menu tm_icon'><div class='touch_menu_inner'>" + listStr + "</div></ul>");
						if ($.contains(document, $('.touch_menu')[0])) {
							var menu = $('.touch_menu');
							var menuHalfWidth = width / 2;

							menu.htmlRemove(function() {
								me.removeClass("touch_menu_active");
								if (typeof restore == "function") restore();
							});

							menu.gravity(me, false, "south", 2, false);
							menu.css("left", (me.offset().left));

							var orig_top = menu.offset().top;

							menu
								.show()
								.css({
									"width": me.outerWidth() + "px",
									"top": me.offset().top,
									"opacity": 0
								})
								.animate({
									"top": ( me.offset().top + me.outerHeight() ),
									"opacity": 1
								}, 500, "easeOutBounce");

							me.addClass("touch_menu_active");

							if (typeof callback == "function") callback();
						}
					}, timeoutval);

				}, delay);
			});

			caller.on("mouseup mouseleave", function() {
				clearTimeout(window.touchtime);
			});
		}
	}
	$.msgBox = function(text, type, callback) {
		$('.message_box').remove();
		$('body').prepend("<div class='message_box'></div>");
		var settings = {delay: 5000, easing: 250};
		var box = $('.message_box');
		var background = (typeof type != "undefined" && type == "error") ? "rgba(173, 52, 52, 0.9)" : "rgba(139, 173, 52, 0.9)";

		box.html(text);
		box.css("background", background);
		box.animate({
			"left": 0
		}, settings.easing);

		setTimeout(function() {
			box.animate({
				"left": "-1000px"
			}, settings.easing, function() {
				if (typeof callback == "function") callback();
				box.remove();
			});
		}, settings.delay);
	}
})(jQuery);

// scrollTo Plugin
;(function(k){'use strict';k(['jquery'],function($){var j=$.scrollTo=function(a,b,c){return $(window).scrollTo(a,b,c)};j.defaults={axis:'xy',duration:parseFloat($.fn.jquery)>=1.3?0:1,limit:!0};j.window=function(a){return $(window)._scrollable()};$.fn._scrollable=function(){return this.map(function(){var a=this,isWin=!a.nodeName||$.inArray(a.nodeName.toLowerCase(),['iframe','#document','html','body'])!=-1;if(!isWin)return a;var b=(a.contentWindow||a).document||a.ownerDocument||a;return/webkit/i.test(navigator.userAgent)||b.compatMode=='BackCompat'?b.body:b.documentElement})};$.fn.scrollTo=function(f,g,h){if(typeof g=='object'){h=g;g=0}if(typeof h=='function')h={onAfter:h};if(f=='max')f=9e9;h=$.extend({},j.defaults,h);g=g||h.duration;h.queue=h.queue&&h.axis.length>1;if(h.queue)g/=2;h.offset=both(h.offset);h.over=both(h.over);return this._scrollable().each(function(){if(f==null)return;var d=this,$elem=$(d),targ=f,toff,attr={},win=$elem.is('html,body');switch(typeof targ){case'number':case'string':if(/^([+-]=?)?\d+(\.\d+)?(px|%)?$/.test(targ)){targ=both(targ);break}targ=win?$(targ):$(targ,this);if(!targ.length)return;case'object':if(targ.is||targ.style)toff=(targ=$(targ)).offset()}var e=$.isFunction(h.offset)&&h.offset(d,targ)||h.offset;$.each(h.axis.split(''),function(i,a){var b=a=='x'?'Left':'Top',pos=b.toLowerCase(),key='scroll'+b,old=d[key],max=j.max(d,a);if(toff){attr[key]=toff[pos]+(win?0:old-$elem.offset()[pos]);if(h.margin){attr[key]-=parseInt(targ.css('margin'+b))||0;attr[key]-=parseInt(targ.css('border'+b+'Width'))||0}attr[key]+=e[pos]||0;if(h.over[pos])attr[key]+=targ[a=='x'?'width':'height']()*h.over[pos]}else{var c=targ[pos];attr[key]=c.slice&&c.slice(-1)=='%'?parseFloat(c)/100*max:c}if(h.limit&&/^\d+$/.test(attr[key]))attr[key]=attr[key]<=0?0:Math.min(attr[key],max);if(!i&&h.queue){if(old!=attr[key])animate(h.onAfterFirst);delete attr[key]}});animate(h.onAfter);function animate(a){$elem.animate(attr,g,h.easing,a&&function(){a.call(this,targ,h)})}}).end()};j.max=function(a,b){var c=b=='x'?'Width':'Height',scroll='scroll'+c;if(!$(a).is('html,body'))return a[scroll]-$(a)[c.toLowerCase()]();var d='client'+c,html=a.ownerDocument.documentElement,body=a.ownerDocument.body;return Math.max(html[scroll],body[scroll])-Math.min(html[d],body[d])};function both(a){return $.isFunction(a)||typeof a=='object'?a:{top:a,left:a}}return j})}(typeof define==='function'&&define.amd?define:function(a,b){if(typeof module!=='undefined'&&module.exports){module.exports=b(require('jquery'))}else{b(jQuery)}}));
