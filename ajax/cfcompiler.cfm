<cftry>

<!--- <cfset data = StructCopy(session)>

<cfif StructKeyExists(data.user, 'prefs')>
    <cfset StructDelete(data.user, 'prefs')>
</cfif> --->

<cfoutput>
    #SerializeJSON(session)#
</cfoutput>

<cfcatch type="any">
    <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
        output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>
