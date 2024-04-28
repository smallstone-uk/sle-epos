<cftry>

<cfif StructKeyExists(session.vat, "#DecimalFormat(vatRate)#")>
	<cfoutput>
		#session.vat['#DecimalFormat(vatRate)#']#
	</cfoutput>	
<cfelse>
	0
</cfif>

<cfcatch type="any">
	<cfdump var="#cfcatch#" output="#application.directory#\data\logs\E#DateFormat(Now(), 'yyyymmdd')##TimeFormat(Now(), 'HHmmss')#.html" format="html">
</cfcatch>
</cftry>