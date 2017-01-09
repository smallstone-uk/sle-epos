<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset prodcats = epos.LoadProductCategories()>
<cfset groups = epos.LoadProductGroups()>

<link href="icomoon/style.css" rel="stylesheet" type="text/css">
<link href="css/bigSelect.css" rel="stylesheet" type="text/css">
<script src="js/jquery-1.11.1.min.js"></script>
<script src="js/jquery-ui.js"></script>
<script src="js/epos.js"></script>
<script src="js/touchSelect.js"></script>

<cfoutput>
	<body>
	
		<style>
			.bigselect .list li {color:##000 !important;}
		</style>
		
		<script>
			$(document).ready(function(e) {
				$('.epf_prodcat').touchSelect();
				
				$('.epf_more').touchSelect();
			});
		</script>
		
		<select name="epf_prodcat" class="epf_prodcat">
			<cfloop array="#prodcats#" index="item">
				<option value="#item.pcatID#" data-group-id="#item.pcatGroup#" data-group-title="#item.pcatTitle#">#item.pcatTitle#</option>
			</cfloop>
		</select>
		
		<select name="epf_more" class="epf_more">
			<cfloop array="#prodcats#" index="item">
				<option value="#item.pcatID#" data-group-id="#item.pcatGroup#" data-group-title="#item.pcatTitle#">#item.pcatTitle#</option>
			</cfloop>
		</select>
		
	</body>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="no">
</cfcatch>
</cftry>