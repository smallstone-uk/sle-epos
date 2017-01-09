<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.width = val(width)>
<cfset parm.height = val(height)>
<cfset parm.top = val(top)>
<cfset parm.left = val(left)>
<cfset parm.id = val(id)>
<cfset parm.scale_w = val(scale_w)>
<cfset parm.scale_h = val(scale_h)>
<cfset update = epos.UpdateIntroBox(parm)>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>