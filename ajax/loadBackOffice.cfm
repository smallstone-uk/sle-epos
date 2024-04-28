<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<div class="backoffice">
		<script>
			$(document).ready(function(e) {
				window.officeOpen = true;
				$('.bo_controlItem').click(function(event) {
					$.ajax({
						type: "GET",
						url: $(this).data("file"),
						success: function(data) {
							$.popup(data, true);
						}
					});
					event.preventDefault();
				});
			});
		</script>
		<ul class="bo_controlList">
			<li class="bo_controlItem" data-file="ajax/office/addProduct.cfm">Add Product</li>
			<li class="bo_controlItem" data-file="ajax/office/addDeal.cfm">Add Deal</li>
		</ul>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>