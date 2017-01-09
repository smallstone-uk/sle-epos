<cftry>
<cfsetting showdebugoutput="no">
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.randNum = RandRange(1024, 1220120, 'SHA1PRNG')>
<cfset sign = (2 * int(session.basket.info.mode eq "reg")) - 1>
<cfset zreading = epos.LoadZReading(parm)>
<cfdump var="#zreading#" label="zreading" expand="yes">

<cfset dateNow = LSDateFormat(Now(), "dd/mm/yyyy")>
<cfset timeNow = LSTimeFormat(Now(), "HH:mm")>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>