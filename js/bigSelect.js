;(function($) {
	// Calling from a class of "bigselect" will result in duplicates being created in the wrong place
	var core = {
		defaults: {
			delay: 250,
			allowOptionClick: false
		},
		_isNumber: function(str) {
			return /^(\d|\.)+$/.test(str);
		},
		_isBoolean: function(str) {
			if (str.trim() == "true" || str.trim() == "false") return true; else return false;
		},
		_getAttributes: function(node, type) {
			var d = {}, re_dataAttr = /^data\-(.+)$/;
			$.each(node.get(0).attributes, function(index, attr) {
				if (re_dataAttr.test(attr.nodeName)) {
					var key = attr.nodeName.match(re_dataAttr)[1];
					var isNum = core._isNumber(attr.value);
					var isBool = core._isBoolean(attr.value);
					if (isNum) var value = Number(attr.value);
					else if (isBool) if (attr.value == "true") var value = true;
					else if (attr.value == "false") var value = false;
					else var value = attr.value;
					d[key] = value;
				}
			});
			
			if (typeof type == "undefined" || type == "object") {
				return d;
			} else if (type == "html") {
				var retStr = "";
				for (var k in d) {
					var itStr = " data-" + k + "='" + d[k] + "'";
					retStr += itStr;
				}
				return retStr;
			}
		},
		_guid: function guid() {
			function s4() {
				return Math.floor((1 + Math.random()) * 0x10000)
					.toString(16)
					.substring(1);
			}
			return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
				s4() + '-' + s4() + s4() + s4();
		},
		_scroll: function(box, count) {
			var isMouseDown = false;
			var isMoving = false;
			var setMousePosY = 0;
			//var speed = Math.sqrt(count);
			var speed = 30;
			
			box.bind("mousedown", function(event) { isMouseDown = true; setMousePosY = event.pageY; });
			box.bind("mouseup", function(event) { isMouseDown = false; setTimeout(function() { core.defaults.allowOptionClick = true; }, 250); });
			box.bind("mousemove", function(event) {
				var mousePosY = event.pageY;
				var mousePosX = event.pageX;
				
				if ( box.height() > 46 ) {
					if (isMouseDown) {
						isMoving = true;
						core.defaults.allowOptionClick = false;
						if (mousePosY > setMousePosY) {
							// Scrolling Up
							box.scrollTop( box.scrollTop() - speed );
						} else {
							// Scrolling Down
							box.scrollTop( box.scrollTop() + speed );
						}
					}
				}
				
				setMousePosY = event.pageY;
			});
		},
		_init: function(caller, index) {
			var html_items = '';
			var item_count = 0;
			
			$.each(caller.find('option'), function(i, e) {
				item_count++;
				var selected = ( $(e).prop("selected") ) ? true : false;
				var dataAttributes = core._getAttributes( $(e), "html" );
				html_items += '<li data-index="' + i + '" data-selected="' + selected + '" data-value="' + $(e).val() + '" ' + dataAttributes + '>' + $(e).html() + '</li>';
			});
			
			var html_start = '<div class="bigselect noselect" data-index="' + index + '"><div class="list">';
			var html_end = '</div></div>';
			
			caller.hide();
			caller.after( html_start + html_items + html_end );
			
			var box = $('.bigselect[data-index="' + index + '"]');
			var item_height = box.find('li').height();
			var total_height = item_count * item_height;
			var innerHeight = $(window).innerHeight();
			var offTop = box.offset().top;
			var usableHeight = innerHeight - offTop;
			core._events( box, item_count, caller );
			
			box.css("height", "46px");
			box.removeAttr("data-open");
			
			core["_callback_" + index]( box, core._getAttributes(box.find('li[data-selected="true"]')) );
			
			box.scrollTo(box.find('li[data-selected="true"]'), {
				limit: false,
				offset: -1,
				duration: 100,
				easing: "easeInOutCubic"
			});
			
			return box;
		},
		_events: function(box, count, caller) {
			var item_height = box.find('li').height();
			var innerHeight = $(window).innerHeight();
			var offTop = box.offset().top;
			var usableHeight = innerHeight - offTop - 120;
			
			var column_count = Math.floor(usableHeight / item_height);
			var max_height = column_count * item_height;
			box.css("max-height", max_height + 4);
			
			box.find('li').bind("click", function(event) {
				if (core.defaults.allowOptionClick) {
					var thisObj = $(this);
					var index = box.attr("data-index");
					var scrollPos = box.scrollTop();
					var scrollHeight = box[0].scrollHeight;
					var value = $(this).attr("data-value");
					var open = box.attr("data-open");
					var full_height = (item_height * count) + 6 + "px";
					
					box.find('li').attr("data-selected", false);
					$(this).attr("data-selected", true);
					
					if (open) {
						box.css("width", "375px");
						box.find('li').css("width", "100%");
						box.removeAttr("data-open");
						caller.find('option[value="' + value + '"]').prop("selected", true);
						core["_callback_" + index]( box, core._getAttributes(box.find('li[data-selected="true"]')) );
						box.animate( { "height": "46px" }, 250, "easeInOutCubic" );
						box.scrollTo(thisObj, {
							limit: false,
							offset: -1,
							duration: 100,
							easing: "easeInOutCubic"
						});
					} else {
						box.attr("data-open", true);
						box.find('.list').css("margin-top", 0);
						box.animate( { "height": full_height }, 250, "easeInOutCubic" );
					}
				}
			});
			
			$(document).bind("mousedown.eventsGrp", function(event) {
				var target = $(event.target);
				if ( !target.is( $('.bigselect') ) && !target.is( $('.bigselect').find('*') ) ) {
					$('.bigselect').each(function(i, e) {
						$(e).css("width", "375px");
						$(e).find('li').css("width", "100%");
						$(e).removeAttr("data-open");
						$(e).animate( { "height": "46px" }, 250, "easeInOutCubic" );
						$(e).scrollTo($(e).find('li[data-selected="true"]'), {
							limit: false,
							offset: 0,
							duration: 100,
							easing: "easeInOutCubic"
						});
					});
				}
			});
			
			core._scroll(box, count);
		}
	};
	
	$.fn.bigSelect = function(callback) {
		var arrLength = this.length;
		return this.each(function(index, element) {
			if (arrLength > 1) {
				core["_callback_" + index] = (typeof callback == "function") ? callback : function() { return false; };
				core._init( $(element), index );
			} else {
				var uuid = core._guid();
				core["_callback_" + uuid] = (typeof callback == "function") ? callback : function() { return false; };
				core._init( $(element), uuid );
			}
		});
	}
})(jQuery);