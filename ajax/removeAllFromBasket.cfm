<cftry>
	<cfobject component="#application.site.codePath#" name="e">
	
	<cfif !StructIsEmpty(form)>
		<cfset parm.form = form>
		<!---<cfset parm.form.credit = -parm.form.unitprice>--->
		<cfset parm.form.qty = -(parm.form.qty)>
		<cfset parm.form.account = 1>
		<cfset parm.form.prodsign = 1>
		<cfset parm.form.prodID = form.itemID>
		<cfset parm.form.addToBasket = false>	<!--- used by non-shopItems categories --->
		<cfset parm.form.prodtitle = title>
		<cfset e.AddItem(parm)>
	</cfif>
	
<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
	<cfdump var="#form#" label="form" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\form-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>