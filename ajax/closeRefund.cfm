<cftry>
<cfsetting showdebugoutput="no">
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.balance = val(balance)>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.checkout_refund_options').htmlRemove();
			
			$('.checkout_refund_options button').click(function(event) {
				var type = $(this).html().trim().toUpperCase();
				
				$.ajax({
					type: "GET",
					url: "ajax/closeRefundTran.cfm",
					beforeSend: function() {
						$.addPayment({
							type: type,
							value: Number("#parm.balance#"),
							wipe: true
						});
						
						$.openTill();
					},
					success: function(data) {
						$('body').append('<div style="display:none;">' + data + '</div>');
					}
				});
				
				event.preventDefault();
			});
			
			$('.checkout_refund_options').animate({
				bottom: 87,
				opacity: 1
			}, 500, "easeInOutCubic");
		});
	</script>
	<div class="checkout_refund_options">
		<button class="scalebtn">Cash</button>
		<button class="scalebtn">Card</button>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>