<cfdump var="#session#" label="session" expand="no">
<cfdump var="#application#" label="application" expand="no">
<cfdump var="#variables#" label="variables" expand="no">

<cfdump var="#application#" label="test app" expand="yes" format="html" 
	output="#application.site.dir_logs#test-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">

<cfoutput>
<a href="#application.site.normal#vars.cfm">Refresh</a><br />
<a href="#application.site.normal#vars.cfm?restart=true">Restart</a><br />
<a href="#application.site.normal#">Show Till</a><br />
</cfoutput>
