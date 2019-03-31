<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset home = epos.LoadHomeFunctions(parm)>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.home_list_item').click(function(event) {
				var index = $(this).data("index");
				switch (index)
				{
					case "topupaccount":
						$.ajax({
						    type: 'GET',
						    url: "#getUrl('ajax/getTopupAccounts.cfm')#",
						    success: function(data) {
						    	$.popup(data);
						    }
						});
						break;
					case "barcode":
						$.virtualNumpad({
							wholenumber: true,
							callback: function(value) {
								$.searchBarcode(value);
							}
						});
						break;
					case "savebasket":
						$.ajax({
							type: "GET",
							url: "ajax/saveBasketForLater.cfm",
							success: function(data) {
								$.msgBox("Basket Saved");
								$.ajax({
									type: "GET",
									url: "ajax/emptyBasket.cfm",
									success: function(data) {
										$.loadBasket();
										$.ajax({
											type: "GET",
											url: "ajax/loadHeaderNote.cfm",
											success: function(data) {
												$('.header_note_holder').html(data);
											}
										});
									}
								});
							}
						});
						break;
					case "opentill":
						cf('till.isTranOpen').then(function(isOpen) {
							if (isOpen) return;

							$.virtualNumpad({
								autolength: 4,
								wholenumber: true,
								callback: function(pin) {
									$.ajax({
										type: "POST",
										url: "ajax/checkPin.cfm",
										data: {"pin": pin},
										success: function(data) {
											var response = data.trim();
											if (response == "true") {
												$.openTill();
											} else {
												$.msgBox("Invalid Login", "error");
											}
										}
									});
								}
							});
						});
						break;
				}
				event.preventDefault();
			});
		});
	</script>
	<ul class="home_list">
		<cfloop array="#home#" index="item">
			<li class="home_list_item material-ripple" data-index="#item.ehIndex#">
				<span>#item.ehTitle#</span>
			</li>
		</cfloop>
	</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>
