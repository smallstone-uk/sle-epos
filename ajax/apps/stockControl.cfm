<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<!---<cfset suppliers = epos.LoadSuppliersForStockControl()>--->

<cfoutput>
	<!---<script>
		$(document).ready(function(e) {
			window.epos_frame.isStockControl = true;
			
			$('.sl_item').click(function(event) {
				accID = $(this).data("id");
				$.ajax({
					type: "POST",
					url: "#parm.url#ajax/apps/fn/get_supplierProductList.cfm",
					data: {"accID": accID},
					success: function(data) {
						$('.supplier_list').fadeOut();
						$('.supplier_result').html(data).fadeIn();
					}
				});
				event.preventDefault();
			});
		});
	</script>--->
	<iframe src="http://tweb.sle-admin.co.uk/ProductStock3.cfm"></iframe>
	<!---<ul class="supplier_list">
		<cfloop array="#suppliers#" index="item">
			<li class="sl_item scalebtn" data-id="#item.accid#"><span>#item.accname#</span></li>
		</cfloop>
	</ul>
	<div class="supplier_result" style="display:none;"></div>--->
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="no">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>