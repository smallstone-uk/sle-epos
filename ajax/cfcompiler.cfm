<cftry>

<cfset data = structCopy(session)>
<cfset prefs = {}>

<cfif structKeyExists(data.user, 'prefs')>
    <cfset prefs = data.user.prefs>
    <cfset structDelete(data.user, 'prefs')>
</cfif>

<cfoutput>
    #serializeJSON(data)#
</cfoutput>

<cfset data.user.prefs = prefs>

<cfcatch type="any">
    <cfset writeDumpToFile(cfcatch)>
</cfcatch>
</cftry>
