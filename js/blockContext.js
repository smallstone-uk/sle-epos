(function () {
	var blockContextMenu, myElement;
	
	blockContextMenu = function(evt) {
		evt.preventDefault();
	}
	
	window.addEventListener('contextmenu', blockContextMenu);
})();