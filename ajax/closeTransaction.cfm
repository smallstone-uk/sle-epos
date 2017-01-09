<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.form = form>
<cfset closeTran = epos.CloseTransaction(parm)>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="no">
</cfcatch>
</cftry>