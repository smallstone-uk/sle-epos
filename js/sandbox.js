;(function($) {
	var TSC = {
		defaults: {
			speed: 250,
			height: 30,
			list : "",
			callback: function() { return true; }
		},
		init: function(settings) {
			settings.this.find('option').each(function(i, e) {
				settings.list += '<li data-index="' + i + '" data-value="' + $(e).attr("value") + '">' + $(e).html() + '</li>';
			});
			
			settings.output = '<div class="touchselect disable-select" data-index="' + settings.index + '"><div class="touchselect_selected"></div><ul>' + settings.list + '</ul></div>';
			settings.this.after(settings.output);
			
			settings.holder = $('.touchselect[data-index="' + settings.index + '"]');
			settings.selectedHolder = $('.touchselect[data-index="' + settings.index + '"] .touchselect_selected');
			settings.list = $('.touchselect[data-index="' + settings.index + '"] ul');
			settings.item = $('.touchselect[data-index="' + settings.index + '"] ul li');
			
			TSC.buildEvents(settings);
		},
		buildEvents: function(settings) {
			/*settings.holder.bind("click", function(event) {
				TSC.expandToggle(settings);
			});*/
			
			settings.item.bind("click", function(event) {
				$(this).attr("data-selected", true);
				TSC.expandToggle(settings);
			});
			
			settings.selectedHolder.bind("click", function(event) {
				if (!Boolean(settings.holder.attr("data-open")))
					TSC.expandToggle(settings);
			});
		},
		expandToggle: function(settings, mode) {
			var isOpen = (mode == "close") ? true : (mode == "open") ? false : Boolean(settings.holder.attr("data-open")) || false;
			if (isOpen) {
				// Closing code
				console.log("Close");
				settings.holder.attr("data-open", false);
				
				settings.selected = {
					text: settings.list.find('li[data-selected="true"]').html() || settings.list.find('li[data-index="0"]').html(),
					value: settings.list.find('li[data-selected="true"]').val() || settings.list.find('li[data-index="0"]').val()
				};
				
				settings.selectedHolder.attr("data-value", settings.selected.value).html(settings.selected.text);
				settings.list.slideUp(TSC.defaults.speed);
			} else {
				// Opening code
				console.log("Open");
				settings.holder.attr("data-open", true);
				settings.selectedHolder.attr("data-value", "").html("");
				settings.list.slideDown(TSC.defaults.speed);
			}
		}
	};
	
	$.fn.touchSelect = function(a) {
		var selector = $(this);
		return selector.each(function(i, e) {
			var settings = $.extend(true, TSC.defaults, a || {});
			settings.this = $(e);
			settings.this.attr("data-index", i);
			settings.index = i;
			TSC.init(settings);
			console.log(settings);
		});
	}
})(jQuery);