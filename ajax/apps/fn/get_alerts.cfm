<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset alerts = epos.LoadAlerts()>

<cfoutput>
	<cfset counter = 0>
	<cfloop array="#alerts#" index="item">
		<li class="scalebtn alert_item <cfif counter is 0>ai_first</cfif>" data-id="#item.altID#">
			<span class="ai_icon icon-alarm"></span>
			<span class="ai_timestamp">#epos.CalculateEasyDateTime(item.altTimestamp)#</span>
			<span class="ai_content">#item.altContent#</span>
		</li>
		<cfset counter++>
	</cfloop>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>