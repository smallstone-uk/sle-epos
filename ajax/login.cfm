<cftry>
<cfobject component="code/epos" name="epos">
<cfobject component="#application.site.codePath#" name="e">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.form = form>
<cfset parm.form.reportDate = lsDateFormat(now(), "yyyy-mm-dd")>
<cfset login = epos.Login(parm)>
<cfset totals = e.loadTillTotals(parm)>

<cfoutput>#login#</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>