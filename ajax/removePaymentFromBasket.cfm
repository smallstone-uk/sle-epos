<cftry>
	<cfobject component="#application.site.codePath#" name="e">	
	<cfset parm.form = form>
	<cfset e.RemovePayment(parm)>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>