<cftry>
	<cfobject component="code/epos" name="epos">
	<cfset parm = {}>
	<cfset parm.type = type>
	<cfset parm.index = index>
	<cfset parm.newQty = val(newQty)>
	
	<cfif StructKeyExists(session.epos_frame.basket, parm.type)>
		<cfset category = StructFind(session.epos_frame.basket, parm.type)>
		<cfif StructKeyExists(category, parm.index)>
			<cfset item = StructFind(category, parm.index)>
			<cfset StructUpdate(item, "qty", parm.newQty)>
		</cfif>
	</cfif>

	<cfset epos.CalculateAccountTotals()>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
		output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>