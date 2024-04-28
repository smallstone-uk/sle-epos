;(function($) {
	var core = {
		init: function(index, field, callback, rand_index) {
			var html = '<div class="chk_outer" data-index="' + (index + rand_index) + '">'+
				'<div class="chk_inner">'+
				'<div class="chk_slider"></div>'+
				'</div></div>';
			
			field.after(html);
			field.hide();
			
			core.buildEvents( (index + rand_index), field, callback );
		},
		buildEvents: function(index, field, callback) {
			var checked = field.prop("checked");
			if (checked) {
				$('.chk_outer[data-index="' + index + '"]').find('.chk_slider').addClass("slider_checked");
				$('.chk_outer[data-index="' + index + '"]').find('.chk_inner').addClass("inner_checked");
			} else {
				$('.chk_outer[data-index="' + index + '"]').find('.chk_slider').removeClass("slider_checked");
				$('.chk_outer[data-index="' + index + '"]').find('.chk_inner').removeClass("inner_checked");
			}
			$('.chk_outer[data-index="' + index + '"]').bind("click", function(event) {
				$(this).find('.chk_slider').toggleClass("slider_checked");
				$(this).find('.chk_inner').toggleClass("inner_checked");
				if ( $(this).find('.chk_slider').hasClass("slider_checked") ) field.prop("checked", true); else field.prop("checked", false);
				if (typeof callback == "function") callback(field.prop("checked"));
			});
		}
	};
	
	$.fn.touchCheckbox = function(callback) {
		return $(this).each(function(index, element) {
			$(element).attr("data-index", index);
			var rand_index = Math.floor(Math.random() * 2056) + 1024;
			core.init( index, $(element), callback, rand_index );
		});
	}
})(jQuery);