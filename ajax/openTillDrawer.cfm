<cftry>
<cfsetting showdebugoutput="no">
<cfobject component="#application.site.codePath#" name="e">
<cfset parm = {}>

<cfif application.site.disableDrawer>
    <cfabort>
</cfif>

<cfoutput>
    <iframe src="#application.site.normal#ajax/openTillDrawerPrivate.cfm?#session.urltoken#">
</cfoutput>

<cfcatch type="any">
    <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
        output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>
