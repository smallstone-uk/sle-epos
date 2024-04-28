<cftry>

	<cfif StructkeyExists(session,"basket")>
		<cfif session.basket.info.totaldue neq 0>
			<cfset session.basket.info.errMsg = "Please finish this transaction before exiting.">
			false
		<cfelse>
			true
		</cfif>
	</cfif>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>