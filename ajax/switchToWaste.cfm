<cfif session.basket.info.itemCount gt 0>
	<cfset session.basket.info.errMsg = "You cannot switch to waste mode during a sales transaction.">
<cfelse>
	<cfset session.basket.info.mode = "wst">
</cfif>
