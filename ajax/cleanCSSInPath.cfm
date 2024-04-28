<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.path = path>

<cffile action="read" file="#parm.path#" variable="cssFile">

<cfset content = cssFile>

<cfset content = REReplaceNoCase(content, "[\s]{2,}", "", "all")>
<cfset content = ReplaceNoCase(content, "}", "}#Chr(13)#", "all")>

<cffile action="write" file="#parm.path#" output="#content#" addnewline="no">

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>