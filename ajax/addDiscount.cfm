<cftry>
<cfset parm = {}>
<cfset parm.form = form>

<cfif StructKeyExists(session.epos_frame.basket.discount, parm.form.type)>
	<cfset paymentItem = StructFind(session.epos_frame.basket.discount, parm.form.type)>
	<cfset paymentItem.value = val(parm.form.value)>
<cfelse>
	<cfset StructInsert(session.epos_frame.basket.discount, parm.form.type, {
		title = UCase(parm.form.title),
		value = val(parm.form.value),
		unit = ( StructKeyExists(parm.form, "unit") ) ? parm.form.unit : "percentage",
		minbalance = ( StructKeyExists(parm.form, "minbalance") ) ? parm.form.minbalance : 0
	})>
</cfif>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>