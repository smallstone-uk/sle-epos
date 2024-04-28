<cftry>
	<cfoutput>
		<cfset session.till.info.staff = !session.till.info.staff>
       <!--- <cfset session.basket.info.mode = "staff">--->
		#session.till.info.staff#	<!--- toggle flag then return result --->
	</cfoutput>
<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
		output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>