<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset emps = epos.LoadEmployees()>
<cfset cats = epos.LoadCategories()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.acf_emp').bigSelect(function() {
				$.ajax({
					type: "POST",
					url: "ajax/apps/fn/get_loadCatsForAssigning.cfm",
					data: {"empID": $('.acf_emp').val()},
					success: function(data) {
						$('.assigncatlist').html(data);
					}
				});
			});
		});
	</script>
	<select name="acf_emp" class="acf_emp">
		<cfloop array="#emps#" index="item">
			<option value="#item.empID#">#item.empFirstName# #Left(item.empLastName, 1)#</option>
		</cfloop>
	</select>
	<ul class="applist assigncatlist"></ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>