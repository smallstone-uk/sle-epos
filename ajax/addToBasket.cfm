<cftry>
	<cfobject component="#application.site.codePath#" name="e">
	<cfset parm = {}>
	<cfset parm.form = form>
	<cfset e.AddItem(parm)>

    <cfset product = new App.Product(parm.form.prodID)>
    <cfset group = product.getGroup()>
    <cfset packet = {
        'classname' = group.pgClassname,
        'product' = product
    }>

    <cfoutput>#serializeJSON(packet)#</cfoutput>

    <cfcatch type="any">
    	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
    		output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
    </cfcatch>
</cftry>
