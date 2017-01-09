<cftry>
<cfobject component="code/epos" name="epos">
<cfobject component="#application.site.codePath#" name="e">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<!--- <cfset e.ClearBasket()> --->

<cfoutput>
	<script>
		$(document).ready(function(e) {
			window.epos_frame.isStockControl = false;
			$('input').blur();
			$('*').addClass("disable-select");
			
			$.scanBarcode({
				postInit: function() {
					console.log("Initialized barcode event handler");
				},
				callback: function(barcode) {
					$.searchBarcode(barcode);
				}
			});
		});
	</script>
	<div class="header" style="font-family: Helvetica, Arial, 'lucida grande',tahoma,verdana,arial,sans-serif !important;">
		<cfinclude template="header.cfm">
	</div>
	<div class="content" style="font-family: Helvetica, Arial, 'lucida grande',tahoma,verdana,arial,sans-serif !important;">
		<cfinclude template="content_loader.cfm">
	</div>
</cfoutput>
</html>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>