<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.path = "#application.site.basedir#css">

<script src="js/jquery-1.11.1.min.js"></script>
<script src="js/jquery-ui.js"></script>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.cssc_clean').click(function(event) {
				var path = $(this).data("path");
				var resultCell = $(this).parent('td').next('td');
				$.ajax({
					type: "POST",
					url: "ajax/cleanCSSInPath.cfm",
					data: {"path": path},
					success: function(data) {
						resultCell.html("OK");
					}
				});
				event.preventDefault();
			});
		});
	</script>
	
	<cfdirectory action="list" directory="#parm.path#" name="cssFiles">
	
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
	</style>
	
	<table border="1" class="tableList" style="font-size:14px;">
		<tr>
			<th colspan="3" style="font-size:18px;">CSS Cleaner</th>
		</tr>
		<cfloop query="cssFiles">
			<tr>
				<th align="left">#name#</th>
				<td><button class="cssc_clean" data-path="#directory#\#name#">Clean</button></td>
				<td>Waiting...</td>
			</tr>
		</cfloop>
	</table>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>