<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<script src="js/jquery-1.11.1.min.js"></script>
<script src="js/jquery-ui.js"></script>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			var pixelarea = ( $(window).innerWidth() * $(window).innerHeight() );
			console.log(pixelarea);
			
			getRandomColor = function() {
				var letters = '0123456789ABCDEF'.split('');
				var color = '##';
				for (var i = 0; i < 6; i++ ) {
					color += letters[Math.floor(Math.random() * 16)];
				}
				return color;
			}
			
			var spins = pixelarea;
			var chunkSize = 3000;
			var chunk;
			
			var index = 0;
			
			function workLoop() {
				index += 1;
				var rand = Math.random() * 25;
				$('.content').append('<span class="grid_block" id="' + index + '"></span>');
				$('##' + index).css({
					"background": getRandomColor()
				});
				if (index < spins) {
					setTimeout(workLoop, 5); 
				}   
			}
			
			workLoop();
		});
	</script>
		
	<style>
		body {font-family: Segoe, "Segoe UI", "DejaVu Sans", "Trebuchet MS", Verdana, sans-serif;}
		.tableList {border-spacing: 0px;border-collapse: collapse;border: 1px solid ##BDC9DD;font-size: 12px;border-color:##BDC9DD;}
		.tableList th {padding:4px 5px;background: ##EFF3F7;border-color: ##BDC9DD;color: ##18315C;}
		.tableList td {padding:2px 5px;border-color: ##BDC9DD;}
		.tableList.morespace {font-size: 12px;}
		.tableList.morespace th {padding:4px 5px;}
		.tableList.morespace td {padding:4px 5px;}
		.tableList.trhover tr:hover {background: ##EFF3F7;}
		.tableList.trhover tr.active:hover {background:##0F5E8B;}
		button {border:none;background:##1B81DF;color:##FFF;outline:0;padding:5px 15px;cursor:pointer;margin:5px;opacity:1;}
		button:hover {opacity:0.8;}
		button:active {background:##111;opacity:1;}
		
		.grid_block {
			float: left;
			width: 1px;
			height: 1px;
			transition:all 1s;
			background:##C00;
		}
		.grid_block_active {background: ##C00;}
	</style>
	<div class="content"></div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>