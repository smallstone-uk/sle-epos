<cftry>
    <cfobject component="#application.site.codePath#" name="e">
    
    <cfset parm.form = form>
   <!--- <cfset parm.form.prodsign = 1>--->
    <cfset parm.form.class = 'item'>
    <cfset parm.form.qty = parm.form.incqty>
    <cfset parm.form.account = 1>
    <cfset parm.form.prodID = form.itemID>
    <cfset parm.form.prodtitle = title>
	<cfset parm.form.addToBasket = true>	<!--- used by non-shopItems categories --->
    <cfset e.AddItem(parm)>

<cfcatch type="any">
    <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
        output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>