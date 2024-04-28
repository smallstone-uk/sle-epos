;(function($) {
	'use strict';
	
	var core = {
		_constants: {
			index: 0
		},
		_init: function(i, t) {
			// P = Page // T = Tab
			
			var p = $( t.attr("href") );
			
			p.attr("data-index", i);
			t.attr("data-index", i);
			
			p.addClass( (i > 0) ? "slide out" : "slide" );
			
			t.click(core._events._click);
		},
		_events: {
			_click: function(event) {
				var curIndex = $(this).attr("data-index");
				var dest = $( $(this).attr("href") );
				var destIndex = dest.attr("data-index");
				
				core._constants.index = $(this).attr("data-index");
				
				$(this).html( "Current Index: " + curIndex + " // Destination Index: " + destIndex );
				
				if (destIndex > core._constants.index) {
					$('.slide').removeClass("in reverse").addClass("out reverse");
				} else {
					$('.slide').removeClass("in reverse").addClass("out");
				}
				
				dest.addClass("in");
				event.preventDefault();
			}
		}
	};
	
	$.fn.slides = function() {
		return this.each(function(i, e) {
			core._init( i, $(e) );
		});
	}
})(jQuery);