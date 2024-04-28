<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.dealid = dealid>
<cfset deal = epos.LoadDealByID(parm.dealid)>
<cfset items = epos.LoadDealItems(deal.edID)>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.ui-text').virtualKeyboard();
			$('.ui-date').virtualDate();
			$('.ui-number').virtualNumpad();
			$('.edf_type').bigSelect();
			var #ToScript(items, "deal_items")#;
			
			$('.EditDealForm').submit(function(event) {
				$.ajax({
					type: "POST",
					url: "ajax/apps/fn/post_editDeal.cfm",
					data: $('.EditDealForm').serialize(),
					success: function(data) {
						$.sidepanel.close(function() {
							$.msgBox("Deal Saved");
							$.ajax({
								type: "GET",
								url: "ajax/apps/fn/get_reloadDeals.cfm",
								success: function(data) {
									$('.edf_deallist').html(data);
								}
							});
						});
					}
				});
				event.preventDefault();
			});
			
			$('.ndf_editprods').click(function(event) {
				$.productSelect({
					maxqty: 1,
					products: deal_items,
					callback: function(data) {
						$('.ndf_editprods').val( data[0].title );
						$('.ndf_item_id').val( data[0].id );
					}
				});
				event.preventDefault();
			});
		});
	</script>
	<form method="post" enctype="multipart/form-data" class="EditDealForm">
		<input type="hidden" name="ndf_id" value="#deal.edID#">
		<table border="0" class="header-align-right">
			<tr>
				<th>Title</th>
				<td><input type="text" value="#deal.edTitle#" name="ndf_title" class="appfld required ui-text" placeholder="Deal Title"></td>
			</tr>
			<tr>
				<th>Start Date</th>
				<td><input type="text" value="#LSDateFormat(deal.edStarts, 'dd/mm/yyyy')#" name="ndf_start" class="appfld required ui-date" placeholder="DD/MM/YYYY"></td>
			</tr>
			<tr>
				<th>End Date</th>
				<td><input type="text" value="#LSDateFormat(deal.edEnds, 'dd/mm/yyyy')#" name="ndf_end" class="appfld required ui-date" placeholder="DD/MM/YYYY" data-past="false"></td>
			</tr>
			<tr>
				<th>Type</th>
				<td>
					<select name="ndf_type" class="edf_type required">
						<option value="Quantity" <cfif deal.edType eq "Quantity">selected="true"</cfif>>Quantity</option>
						<option value="Discount" <cfif deal.edType eq "Discount">selected="true"</cfif>>Discount</option>
						<!---<option value="Selection" <cfif deal.edType eq "Selection">selected="true"</cfif>>Selection</option>--->
					</select>
				</td>
			</tr>
			<tr>
				<th>Amount</th>
				<td><input type="text" value="#DecimalFormat(deal.edAmount)#" name="ndf_amount" class="money ui-number required" placeholder="GBP"></td>
			</tr>
			<tr>
				<th>Quantity</th>
				<td><input type="text" value="#deal.edQty#" name="ndf_qty" class="money ui-number required" placeholder="Qty" data-wholenumber="true"></td>
			</tr>
			<tr>
				<th>Assigned Product</th>
				<td>
					<cfloop array="#items#" index="item">
						<input type="hidden" name="ndf_item_id" class="ndf_item_id" value="#item.id#">
						<input type="text" name="ndf_item_title" value="#item.title#" class="appfld ndf_editprods" placeholder="Assigned Product">
					</cfloop>
				</td>
			</tr>
		</table>
		<input type="submit" class="appbtn" value="Save Deal">
	</form>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>