<cftry>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfexecute 
    name="#application.site.dir_data#programs\EPLConsole.exe"
    arguments="#application.site.basedir#receipt.txt EPOS-PC zebra"
	outputFile="C:\Temp\output.txt">
</cfexecute>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="no">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>