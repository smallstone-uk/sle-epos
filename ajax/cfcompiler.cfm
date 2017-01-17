<cftry>

<!--- <cfset data = StructCopy(session)>

<cfif StructKeyExists(data.user, 'prefs')>
    <cfset StructDelete(data.user, 'prefs')>
</cfif> --->

<cfoutput>
    #SerializeJSON(session)#
</cfoutput>

<cfcatch type="any">
    <!--- <cfset writeDumpToFile(cfcatch)> --->
</cfcatch>
</cftry>
