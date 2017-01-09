<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.accID = val(accID)>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$(document).keypress(function(e) {
				if ( !( $('input').is(":focus") ) &&
					window.epos_frame.isStockControl
				) $.stockControlScanner(e, function(barcode) {
					$.ajax({
						type: "POST",
						url: "#parm.url#ajax/apps/fn/post_stockBarcode.cfm",
						data: {
							"barcode": barcode,
							"step": 1
						},
						success: function(data) {}
					});
				});
			});
		});
	</script>
	Something here needs to happen...
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>