<cftry>

	<cfif session.till.isTranOpen>
		<cfoutput>#serializeJSON({msg = "Please finish the current transaction before resuming the saved basket."})#</cfoutput>
	<cfelse>
		<cfloop collection="#session.epos_archive#" item="key">
			<cfset ref = StructFind(session.epos_archive, key)>
			<cfset frame = StructCopy(ref)>
			<cfset StructDelete(session, "basket")>
			<cfset StructInsert(session, "basket", frame)>
			<cfset StructDelete(session.epos_archive, key)>
		</cfloop>
		<cfoutput>#serializeJSON({msg = "OK"})#</cfoutput>
		<cfset session.till.isTranOpen = true>
	</cfif>
<cfcatch type="any">
	<cfset writeDumpToFile(cfcatch)>
</cfcatch>
</cftry>
