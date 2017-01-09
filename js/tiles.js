(function() {
	showDashBoard = function() {
		for (var i = 1; i <= 3; i++) {
			$('.col' + i).each(function() {
				$(this).addClass('fadeInForward-' + i).removeClass('fadeOutback');
			});
		}
	}

	fadeDashBoard = function() {
		for (var i = 1; i <= 3; i++) {
			$('.col' + i).addClass('fadeOutback').removeClass('fadeInForward-' + i);
		}
	}
	$.tiles = function(callback) {
		//get the background-color for each tile and apply it as background color for the cooresponding screen
		$('.tile').each(function() {
			var $this = $(this),
				page = $this.data('page-name'),
				bgcolor = $this.css('background-color'),
				textColor = $this.css('color');
			//if the tile rotates, we'll use the colors of the front face
			if ($this.hasClass('rotate3d')) {
				frontface = $this.find('.front');
				bgcolor = frontface.css('background-color');
				textColor = frontface.css('color');
			}
			//if the tile has an image and a caption, we'll use the caption styles
			if ($this.hasClass('fig-tile')) {
				caption = $this.find('figcaption');
				bgcolor = caption.css('background-color');
				textColor = caption.css('color');
			}
	
			$this.on('click', function() {
				$('.' + page).css({
					'background-color': bgcolor,
					'color': textColor,
					'display': 'block'
				})
					.find('.close-button').css({
						'background-color': textColor,
						'color': bgcolor
					});
			});
		});
	
			
		//listen for when a tile is clicked
		//retrieve the type of page it opens from its data attribute
		//based on the type of page, add corresponding class to page and fade the dashboard
		$('.tile').each(function() {
			var $this = $(this),
				pageType = $this.data('page-type'),
				page = $this.data('page-name'),
				title = $this.data('page-title'),
				file = $this.data('file');
				
			var hasOnClick = $this.attr("onClick") || false;
				
			$this.on('click', function() {
				if (!hasOnClick) {
					$.ajax({
						type: "GET",
						url: file,
						beforeSend: function() {
							fadeDashBoard();
							$('.' + page).addClass('slidePageInFromLeft').removeClass('slidePageBackLeft');
						},
						success: function(data) {
							$('.' + page).find('.page-title').html(title);
							$('.app-content').html(data);
						}
					});
				}
			});
		});
	
		//when a close button is clicked:
		//close the page
		//wait till the page is closed and fade dashboard back in
		$('.r-close-button').click(function() {
			$(this).parent().addClass('slidePageLeft')
				.one('webkitAnimationEnd oanimationend msAnimationEnd animationend', function(e) {
					$(this).removeClass('slidePageLeft').removeClass('openpage');
				});
			showDashBoard();
		});
		$('.s-close-button').click(function() {
			$(this).parent().removeClass('slidePageInFromLeft').addClass('slidePageBackLeft');
			showDashBoard();
		});
	}
})();