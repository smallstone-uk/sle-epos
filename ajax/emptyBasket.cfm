<cfobject component="#application.site.codePath#" name="e">

<cfif StructKeyExists(session,"basket") AND StructKeyExists(session.basket,"header")>
	<cfif session.basket.header.balance neq 0>	
		<cfdump var="#session.basket#" label="ClearBasket" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\clear-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
	</cfif>
</cfif>

<cfset e.ClearBasket()>
