<cftry>
	<cfobject component="#application.site.codePath#" name="e">
	<cfset parm = {}>
	<cfset parm.form = StructCopy(form)>
	<cfset e.AddPayment(parm)>

    <cfoutput>#e.closeTranNow#</cfoutput>
	
<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
		output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>
