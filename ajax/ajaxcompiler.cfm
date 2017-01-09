<cftry>

<cfset loc = {}>
<cfset loc.path = GetDirectoryFromPath(GetCurrentTemplatePath())>
<cfset loc.ajaxFiles = []>

<cfdirectory action="list" directory="#loc.path#" name="loc.listRoot">

<cfloop query="loc.listRoot">
    <cfif type eq "File">
        <cfset ArrayAppend(loc.ajaxFiles, name)>
    </cfif>
</cfloop>

<cfoutput>
    #SerializeJSON(loc.ajaxFiles)#
</cfoutput>

<cfcatch type="any">
    <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
        output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>