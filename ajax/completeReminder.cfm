<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.remID = reminderID>
<cfset parm.status = status>
<cfset completeReminder = epos.UpdateReminderStatus(parm.remID, parm.status)>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>