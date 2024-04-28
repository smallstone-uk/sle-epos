<cftry>
<cfsetting showdebugoutput="no">
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset closeTran = epos.CloseTransaction()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.basket_receipt').prop("disabled", false);
			$('.basket_receipt').bind("click", function(event) {
				$.printReceipt("#closeTran#");
				event.preventDefault();
			});
		});
	</script>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>