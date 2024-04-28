<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset alerts = epos.LoadOldAlerts()>

<cfoutput>
	<cfloop array="#alerts#" index="item">
		<li class="scalebtn alert_item" data-id="#item.altID#">
			<span class="ai_icon icon-alarm"></span>
			<span class="ai_timestamp">#epos.CalculateEasyDateTime(item.altTimestamp)#</span>
			<span class="ai_content">#item.altContent#</span>
		</li>
	</cfloop>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>