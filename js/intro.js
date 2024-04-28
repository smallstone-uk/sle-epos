;(function($) {
	INTRO = {
		editable: false,
		client: {
			width: screen.width,
			height: screen.height
		},
		nowID: 0,
		slides: [],
		isEdit: false,
		type: function(text, field, callback) {
			var tSplit = text.split("");
			var i = 0;
			var int = null;
			setTimeout(function() {
				int = setInterval(function() {
					if ( $(field).val().length < text.length ) {
						$(field).val( $(field).val() + tSplit[i] ).change();
						i++;
					} else if ( $(field).val().length == text.length ) {
						clearInterval(int);
						setTimeout(function() {
							if (typeof callback == "function") callback();
						}, 500);
					}
				}, 150);
			}, 1000);
		},
		zoom: function(a) {
			setTimeout(function() {
				$(a).zoomTo({
					targetsize: 0,
					duration: 1000,
					nativeanimation: true
				});
			}, 500);
		},
		next: function(i) {
			if (INTRO.slides.length >= i) {
				var fn = Function( INTRO.slides[ (i - 1) ].NEXT );
				if ( typeof fn == "function" ) fn();
				INTRO.tooltip( i, INTRO.slides[i] );
				INTRO.scaleElements( i, INTRO.slides[i] );
				INTRO.setDefaultScale();
			}
		},
		back: function(i) {
			if (INTRO.slides.length >= i) {
				var fn = Function( INTRO.slides[ (i + 1) ].BACK );
				if ( typeof fn == "function" ) fn();
				INTRO.tooltip( i, INTRO.slides[i] );
				INTRO.scaleElements( i, INTRO.slides[i] );
				INTRO.setDefaultScale();
			}
		},
		setDefaultScale: function() {
			var scaleStr = INTRO.client.width + "x" + INTRO.client.height;
			$('.INTRO_admin a[data-size="' + scaleStr + '"]').addClass("ia_active");
			
			$('.INTRO_tooltip').attr({
				"data-scale_w": INTRO.client.width,
				"data-scale_h": INTRO.client.height
			});
			
			$('.INTRO_OutlineBox').attr({
				"data-scale_w": INTRO.client.width,
				"data-scale_h": INTRO.client.height
			});
		},
		scaleElements: function(i, obj) {
			for (var i = 0; i < obj.SCALE.length; i++) {
				if ( INTRO.client.width == obj.SCALE[i].SCREEN_WIDTH ) {
					$('.INTRO_tooltip').animate({
						"top": obj.SCALE[i].NEW_T,
						"left": obj.SCALE[i].NEW_L
					}, "slow", "easeInOutCubic");
					
					$('.INTRO_OutlineBox').animate({
						"left": obj.SCALE[i].NEW_BOX_L,
						"top": obj.SCALE[i].NEW_BOX_T,
						"width": obj.SCALE[i].NEW_W,
						"height": obj.SCALE[i].NEW_H
					}, "slow", "easeInOutCubic");
				}
			}
		},
		boxDraggableDefaults: {
			containment: "html",
			stop: function() {
				var id = $(this).data("id");
				var x = $(this).offset().left;
				var y = $(this).offset().top;
				var w = $(this).outerWidth();
				var h = $(this).outerHeight();
				var sw = typeof $(this).data("scale_w") == "undefined" ? 0 : $(this).data("scale_w");
				var sh = typeof $(this).data("scale_h") == "undefined" ? 0 : $(this).data("scale_h");
				$.ajax({
					type: "POST",
					url: "ajax/updateIntroBox.cfm",
					data: {
						width: w,
						height: h,
						top: y,
						left: x,
						scale_w: sw,
						scale_h: sh,
						id: INTRO.nowID
					},
					success: function(data) {
						var useThisIndex = arrayStructFind( INTRO.slides, "ID", INTRO.nowID );
						
						INTRO.loadData(function() {
							INTRO.tooltip( useThisIndex, INTRO.slides[ useThisIndex ] );
							INTRO.scaleElements( useThisIndex, INTRO.slides[ useThisIndex ] );
							if (INTRO.editable) INTRO.buildAdmin();
							INTRO.setDefaultScale();
						});
					}
				});
			}
		},
		boxResizableDefaults: {
			handles: "n, e, s, w, ne, se, sw, nw",
			stop: function() {
				var id = $(this).data("id");
				var x = $(this).offset().left;
				var y = $(this).offset().top;
				var w = $(this).outerWidth();
				var h = $(this).outerHeight();
				var sw = typeof $(this).data("scale_w") == "undefined" ? 0 : $(this).data("scale_w");
				var sh = typeof $(this).data("scale_h") == "undefined" ? 0 : $(this).data("scale_h");
				$.ajax({
					type: "POST",
					url: "ajax/updateIntroBox.cfm",
					data: {
						width: w,
						height: h,
						top: y,
						left: x,
						scale_w: sw,
						scale_h: sh,
						id: INTRO.nowID
					},
					success: function(data) {
						var useThisIndex = arrayStructFind( INTRO.slides, "ID", INTRO.nowID );
						
						INTRO.loadData(function() {
							INTRO.tooltip( useThisIndex, INTRO.slides[ useThisIndex ] );
							INTRO.scaleElements( useThisIndex, INTRO.slides[ useThisIndex ] );
							if (INTRO.editable) INTRO.buildAdmin();
							INTRO.setDefaultScale();
						});
					}
				});
			}
		},
		tooltip: function(i, obj) {
			obj.ID = ( typeof obj.ID != "undefined" ) ? obj.ID : 0;
			INTRO.nowID = obj.ID;
			
			if ( $('.INTRO_tooltip').length ) {
				$('.INTRO_tooltip').attr("data-id", obj.ID);
				$('.INTRO_tooltip').find('.INTRO_text').html(obj.TEXT);
				$('.INTRO_tooltip').find('.INTRO_Back').attr("onclick", "javascript:INTRO.back(" + (i - 1) + ");");
				$('.INTRO_tooltip').find('.INTRO_Next').attr("onclick", "javascript:INTRO.next(" + (i + 1) + ");");
			} else {
				$('body').prepend(
					'<div class="INTRO_tooltip" data-id="' + obj.ID + '"><div><span class="INTRO_text">' + obj.TEXT + '</span><span style="float:left;width:100%;margin-top:20px;">'+
					'<button class="INTRO_Back" onclick="javascript:INTRO.back(' + (i - 1) + ');" style="float:left;">Back</button>'+
					'<button class="INTRO_Next" onclick="javascript:INTRO.next(' + (i + 1) + ');" style="float:right;">Next</button>'+
					'</span></div></div>'
				);
				
				$('.INTRO_tooltip').css({
					"top": obj.POSITION[1],
					"left": obj.POSITION[0]
				});
			}
			
			if ( $('.INTRO_OutlineBox').length ) {
				// if (typeof obj.BOX != "undefined" && obj.BOX[2] > 0 && obj.BOX[3] > 0)
					$('.INTRO_OutlineBox').attr("data-id", obj.ID);
			} else {
				if (typeof obj.BOX != "undefined" && obj.BOX[2] > 0 && obj.BOX[3] > 0) {
					$('body').prepend('<div class="INTRO_OutlineBox ui-widget-content blink_me" data-id="' + obj.ID + '"></div>');
					$('.INTRO_OutlineBox').css({
						"left": obj.BOX[0],
						"top": obj.BOX[1],
						"width": obj.BOX[2],
						"height": obj.BOX[3]
					});
				}
			}
			
			if (!INTRO.editable) $('.INTRO_OutlineBox').css("pointer-events", "none");
			
			if (INTRO.editable) {
				$('.INTRO_OutlineBox').draggable( INTRO.boxDraggableDefaults );
				$('.INTRO_OutlineBox').resizable( INTRO.boxResizableDefaults );
				
				$('.INTRO_tooltip').draggable({
					stop: function() {
						var id = $(this).data("id");
						var x = $(this).offset().left;
						var y = $(this).offset().top;
						var sw = typeof $(this).data("scale_w") == "undefined" ? 0 : $(this).data("scale_w");
						var sh = typeof $(this).data("scale_h") == "undefined" ? 0 : $(this).data("scale_h");
						$.ajax({
							type: "POST",
							url: "ajax/updateIntroTooltip.cfm",
							data: {
								top: y,
								left: x,
								scale_w: sw,
								scale_h: sh,
								id: INTRO.nowID
							},
							success: function(data) {
								var useThisIndex = arrayStructFind( INTRO.slides, "ID", INTRO.nowID );
								
								INTRO.loadData(function() {
									INTRO.tooltip( useThisIndex, INTRO.slides[ useThisIndex ] );
									INTRO.scaleElements( useThisIndex, INTRO.slides[ useThisIndex ] );
									if (INTRO.editable) INTRO.buildAdmin();
									INTRO.setDefaultScale();
								});
							}
						});
					}
				});
				
				INTRO.isEdit = false;
				$('.INTRO_tooltip').bind("dblclick", function(event) {
					var useThisIndex = arrayStructFind( INTRO.slides, "ID", INTRO.nowID );
					if (!INTRO.isEdit) {
						INTRO.isEdit = true;
						var id = $(this).parents('.INTRO_tooltip').data("id");
						var text = $(this).html();
						$('.INTRO_text').html(
							"<textarea class='INTRO_textEdit'>" + INTRO.slides[ useThisIndex ].TEXT + "</textarea>"+
							"<textarea class='INTRO_nextEdit'>" + INTRO.slides[ useThisIndex ].NEXT + "</textarea>"+
							"<textarea class='INTRO_backEdit'>" + INTRO.slides[ useThisIndex ].BACK + "</textarea>"
						);
						$('.INTRO_tooltip').htmlClick(function(event) {
							var newText = $('.INTRO_textEdit').val();
							var newNext = $('.INTRO_nextEdit').val();
							var newBack = $('.INTRO_backEdit').val();
							$.ajax({
								type: "POST",
								url: "ajax/updateIntroTooltipText.cfm",
								data: {
									text: newText,
									next: newNext,
									back: newBack,
									id: INTRO.nowID
								},
								success: function(data) {
									$('.INTRO_textEdit').unbind("blur");
									INTRO.isEdit = false;
									
									
									INTRO.loadData(function() {
										INTRO.tooltip( useThisIndex, INTRO.slides[ useThisIndex ] );
										obj.NEXT = newNext;
										obj.BACK = newBack;
									});
								}
							});
						});
					}
				});
			}
		},
		loadData: function(a) {
			$.ajax({
				type: "GET",
				url: "ajax/loadIntroData.cfm",
				cache: false,
				success: function(data) {
					INTRO.slides = JSON.parse(data);
					if (INTRO.slides.length > 0) if (typeof a == "function") a();
				}
			});
		},
		buildAdmin: function() {
			var thisScreen = INTRO.client.width + "x" + INTRO.client.height;
			var defaultScreens = ["1920x1080", "1280x1024"];
			
			$('body').prepend(
				'<div class="INTRO_admin"><span>'+
				'<input type="checkbox" value="all">Toggle All</span>'+
				'<span><input type="checkbox" value="admin">Toggle Admin Bar</span>'+
				'<a href="javascript:void(0)" data-method="center">Center Objects</a>'+
				'<a href="javascript:void(0)" data-method="order">Reorder Slides</a>'+
				'<a href="javascript:void(0)" data-method="del">Delete Slides</a>'+
				'<a href="javascript:void(0)" data-method="add">Create Tooltip</a>'+
				'<a href="javascript:void(0)" data-method="delbox">Delete Box</a>'+
				'<a href="javascript:void(0)" data-method="box">Create Box</a>'+
				'<a href="javascript:void(0)" data-method="size" data-size="1920x1080">1920x1080</a>'+
				'<a href="javascript:void(0)" data-method="size" data-size="1280x1024">1280x1024</a>'+
				'</div>'
			);
			
			makeScreen = true;
			for (var s = 0; s < defaultScreens.length; s++) if (defaultScreens[s] == thisScreen) makeScreen = false;
			if (makeScreen) $('.INTRO_admin').append('<a href="javascript:void(0)" data-method="size" data-size="' + thisScreen + '">' + thisScreen + '</a>');
			
			$('.INTRO_admin span input').bind("click", function(event) {
				if ( $(this).prop("checked") ) {
					$('.INTRO_admin').css("right", "inherit");
					if ( $(this).val() == "all" ) {
						$('.INTRO_admin a, .INTRO_tooltip, .INTRO_OutlineBox, .INTRO_admin span:last').hide();
					} else {
						$('.INTRO_admin a').hide();
					}
				} else {
					$('.INTRO_admin').css("right", "0");
					$('.INTRO_admin a, .INTRO_tooltip, .INTRO_OutlineBox, .INTRO_admin span:last').show();
				}
			});
			
			$('.INTRO_admin a').bind("click", function(event) {
				switch ( $(this).data("method") )
				{
					case "delbox":
						$.ajax({
							type: "POST",
							url: "ajax/updateIntroBox.cfm",
							data: {
								width: 0,
								height: 0,
								top: 0,
								left: 0,
								scale_w: INTRO.client.width,
								scale_h: INTRO.client.height,
								id: $('.INTRO_OutlineBox').data("id")
							},
							success: function(data) {
								$('.INTRO_OutlineBox').remove();
							}
						});
						break;
					case "box":
						$('.INTRO_OutlineBox').remove();
						$('body').prepend('<div class="INTRO_OutlineBox ui-widget-content blink_me" data-id="' + $('.INTRO_tooltip').data("id") + '"></div>');
						$('.INTRO_OutlineBox').css({ "width": 250, "height": 250 }).center();
						$('.INTRO_OutlineBox').draggable( INTRO.boxDraggableDefaults );
						$('.INTRO_OutlineBox').resizable( INTRO.boxResizableDefaults );
						INTRO.setDefaultScale();
						break;
					case "center":
						$('.INTRO_tooltip').center();
						$('.INTRO_OutlineBox').center();
						break;
					case "size":
						$('.INTRO_admin a').removeClass("ia_active");
						$(this).addClass("ia_active");
						
						if ( $(this).hasClass("ia_active") ) {
							var dim = {};
							dim.extract = $(this).html().split("x");
							dim.width = Number( dim.extract[0] );
							dim.height = Number( dim.extract[1] );
							
							$('.INTRO_tooltip').attr({
								"data-scale_w": dim.width,
								"data-scale_h": dim.height
							});
							
							$('.INTRO_OutlineBox').attr({
								"data-scale_w": dim.width,
								"data-scale_h": dim.height
							});
						} else {
							$('.INTRO_tooltip').removeAttr("data-scale_w data-scale_h");
							$('.INTRO_OutlineBox').removeAttr("data-scale_w data-scale_h");
						}
						break;
					case "add":
						$.ajax({
							type: "GET",
							url: "ajax/loadIntroAdd.cfm",
							success: function(data) { $.popup(data); }
						});
						break;
					case "del":
						$.ajax({
							type: "GET",
							url: "ajax/loadIntroDel.cfm",
							success: function(data) { $.popup(data); }
						});
						break;
					case "order":
						$.ajax({
							type: "GET",
							url: "ajax/loadIntroReorder.cfm",
							success: function(data) { $.popup(data); }
						});
						break;
				}
				event.preventDefault();
			});
		},
		init: function() {
			INTRO.loadData(function() {
				INTRO.tooltip( 0, INTRO.slides[0] );
				INTRO.scaleElements( 0, INTRO.slides[0] );
				if (INTRO.editable) INTRO.buildAdmin();
				INTRO.setDefaultScale();
			});
			
			$(document).keyup(function(event) {
				event.preventDefault();
				if (event.which === 37 && !INTRO.isEdit) $('.INTRO_Back').click();
				if (event.which === 39 && !INTRO.isEdit) $('.INTRO_Next').click();
			});
		}
	};
})(jQuery);