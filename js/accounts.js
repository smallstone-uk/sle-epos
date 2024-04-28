;(function($) {
	$(document).on("keyup", "body", function(event) {
		var code = event.keyCode || event.which;
		if (code == "107") {
			event.preventDefault();
			$('.aifnewRow').click();
			$('.aifnewRow').parent('tr').prev('tr').find('.nom').focus();
			
			$('.niAmount').each(function(i, e) {
				$(e).val( $(e).val().replace(/\+/ig, "") );
			});
			
			vatTotal();
			netTotal();
			netDiff();
			vatDiff();
		}
	});
	validateTran = function() {
		var result = false;
		try {
			if ($('#trnDate').val().length > 0 && $('#NetAmount').val().length > 0) {
				if ($('#HeaderType').val().indexOf("pay|rfd")) {
				//if ($('#HeaderType').val() == "pay") {
					result = true;
				} else {
					if (typeof netDiff == "function" && typeof vatDiff == "function") {
						if (netDiff() === 0 && (vatDiff() > -0.03 || vatDiff() < 0.03)) {
							result = true;
						} else {
							result = false;
						}
					}
				}
			} else {
				result = false;
			}
		} catch(e) {
			result = false;
		}
		return result;
	}
	disableSave = function(isOn) {}
	toggleTranList = function() {
		$('#tranListTable').toggle();
	}
	switchHeaderType = function(a, b) {
		var type = $('#HeaderType').val();
		if (b) {
			switch (a)
			{
				case "crn":
					$('.aif-headline')
						.css({"background": "#ED143D", "box-shadow": "#880E25 0px 2px 0px"})
						.html("New Credit Note");
					break;
				case "inv":
					$('.aif-headline')
						.css({"background": "#4169E1", "box-shadow": "#273F86 0px 2px 0px"})
						.html("New Invoice");
					break;
				case "pay":
					$('.aif-headline')
						.css({"background": "#5F9EA0", "box-shadow": "#3C6566 0px 2px 0px"})
						.html("New Payment");
					break;
				case "jnl":
					$('.aif-headline')
						.css({"background": "#2E8B57", "box-shadow": "#1A4E31 0px 2px 0px"})
						.html("New Credit Journal");
					break;
				case "rfd":
					$('.aif-headline')
						.css({"background": "#2E8B57", "box-shadow": "#1A4E31 0px 2px 0px"})
						.html("New Refund");
					break;
				case "dbt":
					$('.aif-headline')
						.css({"background": "#2E8B57", "box-shadow": "#1A4E31 0px 2px 0px"})
						.html("New Debit Journal");
					break;
				default:
					$('.aif-headline')
						.css({"background": "#4169E1", "box-shadow": "#273F86 0px 2px 0px"})
						.html("New Invoice");
					break;
			}
		} else {
			switch (a)
			{
				case "crn":
					$('.aif-headline')
						.css({"background": "#ED143D", "box-shadow": "#880E25 0px 2px 0px"})
						.html("Credit Note");
					break;
				case "inv":
					$('.aif-headline')
						.css({"background": "#4169E1", "box-shadow": "#273F86 0px 2px 0px"})
						.html("Invoice");
					break;
				case "pay":
					$('.aif-headline')
						.css({"background": "#5F9EA0", "box-shadow": "#3C6566 0px 2px 0px"})
						.html("Payment");
					break;
				case "jnl":
					$('.aif-headline')
						.css({"background": "#2E8B57", "box-shadow": "#1A4E31 0px 2px 0px"})
						.html("Credit Journal");
					break;
				case "rfd":
					$('.aif-headline')
						.css({"background": "#2E8B57", "box-shadow": "#1A4E31 0px 2px 0px"})
						.html("Refund");
					break;
				case "dbt":
					$('.aif-headline')
						.css({"background": "#2E8B57", "box-shadow": "#1A4E31 0px 2px 0px"})
						.html("Debit Journal");
					break;
				default:
					$('.aif-headline')
						.css({"background": "#4169E1", "box-shadow": "#273F86 0px 2px 0px"})
						.html("Invoice");
					break;
			}
		}
	}
	$.messageBox = function(a, b, c) {
		var _params = {
			id: "sle-message-box",
			height: 100,
			easing: 300,
			delay: 2000
		};
		$(document).unbind(".msgBoxEvents");
		$('#' + _params.id).each(function(index, element) {
			$(element).remove();
		});
		var _style = "display: none;position: fixed;width:100%;height: 0px;background: rgba(139, 173, 52, 0.9);text-align: center;line-height: 0px;font-size: 16px;color: #FFF;z-index: 0;bottom: 0;left: 0;pointer-events:none;";
		$('body').prepend("<div id='" + _params.id + "' style='" + _style + "'></div>");
		var _box = $('#' + _params.id);
		if (b == "error")
			_box.css("background", "rgba(173, 52, 52, 0.9)");
		_box
			.html(a)
			.fadeTo(_params.easing, 0.9)
			.animate({"height": _params.height, "line-height": _params.height + "px"}, _params.easing, 'easeInOutCubic');
		setTimeout(function(){
			_box.animate({
				"height": "50px",
				"line-height": "50px"
			}, _params.easing, 'easeInOutCubic', function() {
				$(document).bind("click.msgBoxEvents", function(event) {
					_box.animate({
						"height": "0",
						"line-height": "0"
					 }, _params.easing, 'easeInOutCubic', function() {
						_box.remove();
						if (typeof c == "function") c();
					 });
				});
			});
		}, _params.delay);
	}
	serializeRecordEditForm = function() {
		var form = {};
		for (var i = 0; i < document.RecordEditFormName.elements.length; i++) {
			if (document.RecordEditFormName.elements[i].name.length > 0) {
				if (document.RecordEditFormName.elements[i].type == "checkbox") {
					form[document.RecordEditFormName.elements[i].name] = document.RecordEditFormName.elements[i].checked;
				} else {
					form[document.RecordEditFormName.elements[i].name] = document.RecordEditFormName.elements[i].value;
				}
			}
		}
		return form;
	}
	$.fn.successMessage = function(msg) {
		var caller = $(this);
		caller.html("<div class='green-success'>" + msg + "</div>");
	}
	$.confirmation = function(params) {
		$.fn.centerPopupBox = function() {
			var caller = $(this);
			caller.css("top", Math.max(0, (($(window).height() - caller.outerHeight()) / 2)));
			caller.css("left", Math.max(0, (($(window).width() - caller.outerWidth()) / 2)));
		}
		$('body').prepend('<div class="body-dim"></div><div class="confirmation-box"><h1 class="cb-header">Confirmation</h1><p class="cb-content">Are you sure you want to to this?</p><button class="cb-yes">Yes</button><button class="cb-no">No</button></div>');
		$('.confirmation-box').centerPopupBox();
		$('.cb-yes').bind("click", function(event) {
			$('.body-dim').remove();
			$('.confirmation-box').remove();
			params.accept();
		});
		$('.cb-no').bind("click", function(event) {
			$('.body-dim').remove();
			$('.confirmation-box').remove();
			params.decline();
		});
	}
	$.fn.loading = function(on) {
		var caller = $(this);
		if (on) {caller.html("<img src='images/ajax-loader.gif' class='loadingGif'>").fadeIn();} else {caller.fadeOut();}
	}
})(jQuery);