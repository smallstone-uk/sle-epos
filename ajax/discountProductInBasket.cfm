<cftry>
	<cfobject component="code/epos" name="epos">
	<cfset parm = {}>
	<cfset parm.datasource = application.site.datasource1>
	<cfset parm.url = application.site.normal>
	<cfset parm.form = form>
		
	<cfif StructKeyExists(session.epos_frame.basket, parm.form.type)>
		<cfset group = StructFind(session.epos_frame.basket, parm.form.type)>
		<cfif StructKeyExists(group, parm.form.index)>
			<cfset item = StructFind(group, parm.form.index)>
			<cfset newPrice = val(item.price) * 0.9>
			<cfset StructUpdate(item, "price", newPrice)>
		</cfif>
	</cfif>

	<cfset epos.CalculateAccountTotals()>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>