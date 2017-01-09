<cftry>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.form = form>
<cfset sign = (2 * int(session.basket.info.mode eq "reg")) - 1>
<cfset parm.form.value = (-val(parm.form.value)) * sign>

<cfif StructKeyExists(session.epos_frame.basket.paypoint, "charge")>
	<cfset StructUpdate(session.epos_frame.basket.paypoint, "charge", {
		index = "charge",
		title = parm.form.title,
		price = parm.form.value,
		qty = 1
	})>
<cfelse>
	<cfset StructInsert(session.epos_frame.basket.paypoint, "charge", {
		index = "charge",
		title = parm.form.title,
		price = parm.form.value,
		qty = 1
	})>
</cfif>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>