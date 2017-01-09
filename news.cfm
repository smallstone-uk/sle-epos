<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.bbcrssfeed = "http://www.thegrocer.co.uk/XmlServers/navsectionRSS.aspx?navsectioncode=33">

<cffeed action="read" source="#parm.bbcrssfeed#" query="newsQuery">
<cfdump var="#newsQuery#" label="newsQuery" expand="no">

<!---<cfoutput>
	<ul>
		<cfloop query="newsQuery">
			<li>
				<h3>#title#</h3>
				<p>#content#</p>
			</li>
		</cfloop>
	</ul>
</cfoutput>--->

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>