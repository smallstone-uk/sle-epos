<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.commands_item').click(function(event) {
				var method = $(this).data("method");
				switch (method)
				{
					case "emptybasket":
						$.ajax({
							type: "GET",
							url: "ajax/emptyBasket.cfm",
							success: function(data) {
								$.loadBasket();
							}
						});
						break;
					case "cash":
						$.tillNumpad(function(value) {
							$.ajax({
								type: "POST",
								url: "ajax/addPayment.cfm",
								data: {
									"type": "cash",
									"value": value
								},
								success: function(data) {
									$.loadBasket();
								}
							});
						});
						break;
				}
				event.preventDefault();
			});
		});
	</script>
	<div class="commands">
		<ul class="commands_list">
			<li class="commands_item" data-method="cash">Cash</li>
			<li class="commands_item" data-method="card">Card</li>
			<li class="commands_item" data-method="cheque">Cheque</li>
			<li class="commands_item" data-method="newsvoucher">Newspaper Voucher</li>
			<li class="commands_item" data-method="prize">Prize</li>
			<li class="commands_item" data-method="coupon">Coupon</li>
			<li class="commands_item" data-method="owners">Owners Account</li>
			<li class="commands_item" data-method="supplier">Supplier</li>
			<li class="commands_item" data-method="refund">Refund</li>
			<li class="commands_item" data-method="emptybasket">Empty Basket</li>
		</ul>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>