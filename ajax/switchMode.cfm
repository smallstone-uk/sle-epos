<cftry>
	<!---<cfset session.basket.info.mode = mode>
	<cfset session.basket.info.staff = false>
	--->
	<cfif session.basket.info.itemCount gt 0>
		<!---<cfset session.basket.info.mode = "reg">--->
		<cfset session.basket.info.errMsg = "You cannot switch to refund mode during a sales transaction.">
		false
	<cfelse>
		<cfset session.basket.info.mode = mode>
		true
	</cfif>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>