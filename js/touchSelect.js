;(function($) {
	'USE STRICT';
	$.fn.touchSelect = function(callback) {
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
				if (node.length <= 0) return {};
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
				s4 = function() { return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1); }
				return s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4();
			},
			_init: function(caller, index) {
				caller.hide();
				caller.after('<input type="text" name="input_' + index + '" class="input_' + index + '">');
				var findSelected = ( caller.find('option[selected]').length > 0 ) ? caller.find('option[selected]').val() : '';
				$('.input_' + index).val(findSelected);
				core._events( $('.input_' + index), caller, index );
				core["_callback_" + index]( $('.input_' + index), core._getAttributes(findSelected) );
				return $('.input_' + index);
			},
			_events: function(box, caller, index) {
				box.bind("focus", function(event) {
					$('.touchselect').remove();
					var html_items = '';
					
					$.each(caller.find('option'), function(i, e) {
						var selected = ( $(e).prop("selected") ) ? true : false;
						var dataAttributes = core._getAttributes( $(e), "html" );
						html_items += '<li data-index="' + i + '" data-selected="' + selected + '" data-value="' + $(e).val() + '" ' + dataAttributes + '>' + $(e).html() + '</li>';
					});
					
					var controls = '<span class="ctrl_return icon-undo2"></span>';
					var html_full = '<div class="touchselect slide noselect" data-index="' + index + '"><div class="list">' + html_items + '</div><div class="controls">' + controls + '</div></div>';
					$('body').prepend(html_full);
					var ts = $('.touchselect[data-index="' + index + '"]');
					
					ts.find('.list').scrollTo('li[data-selected="true"]');
					
					ts.find('.ctrl_return').bind("click", function(event) {
						ts.addClass("slide_end");
					});
					
					ts.find('li').bind("click", function(event) {
						caller.val( $(this).attr("data-value") );
						box.val( $(this).text() );
						ts.addClass("slide_end");
					});
				});
			}
		};
		
		console.log(this);
		return $(this).each(function(index, element) {
			var uuid = core._guid();
			core["_callback_" + uuid] = (typeof callback == "function") ? callback : function() { return false; };
			core._init( $(element), uuid );
		});
	}
})(jQuery);