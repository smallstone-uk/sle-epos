<cftry>
<cfsetting showdebugoutput="no">
<cfobject component="#application.site.codePath#" name="e">
<cfset parm = {}>

<cfoutput>
    <iframe src="ajax/printReceiptPrivate.cfm?#session.urltoken#">
</cfoutput>

<cfcatch type="any">
    <cfset writeDumpToFile(cfcatch)>
</cfcatch>
</cftry>
