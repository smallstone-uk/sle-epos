<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.userID = val(session.user.id)>
<cfset parm.oldpin = oldpin>
<cfset parm.newpin = newpin>
<cfset update = epos.UpdateUserPin(parm)>

<cfoutput>
	@msg: #update.msg#
	@error: #update.error#
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>