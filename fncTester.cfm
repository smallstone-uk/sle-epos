<cftry>
<cfobject component="code/core" name="core">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<link href="css/basicTables.css" rel="stylesheet" type="text/css">

<cfoutput>
	<script>
		$(document).ready(function(e) {});
	</script>
	<table border="1" width="100%" class="table">
		<tr>
			<th>Function Name</th>
			<th>Expected Result</th>
			<th>Given Arguments</th>
			<th>Final Result</th>
		</tr>
		<tr>
			<cfset args = {
				id = 22292,
				title = "My Product",
				type = "product",
				price = 1.2 * -1,
				cashonly = false
			}>
			<cfset result = core.addToBasket(args)>
			<td>addToBasket</td>
			<td>Adds the given product information to the basket session structure</td>
			<td><cfdump var="#args#" label="arguments" expand="no"></td>
			<td><cfdump var="#result#" label="result" expand="no"></td>
		</tr>
	</table>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="no">
</cfcatch>
</cftry>