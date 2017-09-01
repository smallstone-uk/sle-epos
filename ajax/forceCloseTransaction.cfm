<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset session.epos_frame.result.balanceDue = 0>
<cfset session.epos_frame.result.totalGiven = 0>
<cfset session.epos_frame.result.changeDue = 0>
<cfset session.epos_frame.result.discount = 0>
<cfset requiredKeys = ["product", "publication", "paystation", "deal", "payment", "discount", "supplier"]>
<cfset session.epos_frame.basket = {}>
<cfloop array="#requiredKeys#" index="key">
	<cfset StructInsert(session.epos_frame.basket, key, {})>
</cfloop>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>