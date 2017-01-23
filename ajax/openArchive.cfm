<cftry>

<cfloop collection="#session.epos_archive#" item="key">
	<cfset ref = StructFind(session.epos_archive, key)>
	<cfset frame = StructCopy(ref)>
	<cfset StructDelete(session, "basket")>
	<cfset StructInsert(session, "basket", frame)>
	<cfset StructDelete(session.epos_archive, key)>
</cfloop>

<cfcatch type="any">
	<cfset writeDumpToFile(cfcatch)>
</cfcatch>
</cftry>
