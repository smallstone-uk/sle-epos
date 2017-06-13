<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset payments = epos.LoadPayments(parm)>
<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.payment_item').click(function(event) {
				var obj = $(this);
				var type = $(this).data("method");
				var id = $(this).data("id");
				var balance = Number("#session.basket.total.balance#");
				switch (type) {
					case "partcash":
						$.virtualNumpad({
							hint: "Enter a value for part cash",
							callback: function(value) {
								$.addPayment({
									account: "",
									addtobasket: true,
									btnsend: "Cash",
									cash: value,
									cashonly: "",
									credit: "",
									prodid: "",
									prodtitle: "",
									qty: 1,
									type: "",
									vrate: "",
									payID: id
								}, function() { $.loadBasket(); });
							}
						});
						break;
					case "fastcash":
						$.addPayment({
							account: "",
							addtobasket: true,
							btnsend: "Cash",
							cash: "",
							cashonly: "",
							credit: "",
							prodid: "",
							prodtitle: "",
							qty: 1,
							type: "",
							vrate: "",
							payID: id
						}, function() {
							$.loadBasket();
						});
						break;
					case "partcard":
						var cashTotal = Number("#-session.basket.header.bcash#");
						var creditTotal = Number("#-session.basket.header.bcredit - session.basket.header.discdeal#");
						$.virtualNumpad({
							fields: [
								{
									name: "cashbackAmount",
									label: "Cashback Amount",
									value: nf(cashTotal, "str")
								},
								{
									name: "saleAmount",
									label: "Sale Amount",
									value: nf(creditTotal, "str")
								}
							],
							callback: function(data) {
								$.addPayment({
									account: "",
									addtobasket: true,
									btnsend: "Card",
									cash: data.cashbackAmount,
									cashonly: "",
									credit: data.saleAmount,
									prodid: "",
									prodtitle: "",
									qty: 1,
									type: "",
									vrate: "",
									payID: id
								}, function() { $.loadBasket(); });
							}
						});
						break;
					case "fastcard":
						if ( !obj.data("disabled") ) {
							$.addPayment({
								account: "",
								addtobasket: true,
								btnsend: "Card",
								cash: "",
								cashonly: "",
								credit: "",
								prodid: "",
								prodtitle: "",
								qty: 1,
								type: "",
								vrate: "",
								payID: id
							}, function() {
								$.loadBasket();
							});
						} else {
							$.msgBox("You cannot fast card when you have cash only items in the basket. Use part card instead.", "error");
						}
						break;
					case "cheque":
						$.virtualNumpad({
							hint: "Enter the cheque's value",
							callback: function(value) {
								$.addPayment({
									account: "",
									addtobasket: true,
									btnsend: "Cheque",
									cash: value,
									cashonly: "",
									credit: "",
									prodid: "",
									prodtitle: "",
									qty: 1,
									type: "",
									vrate: "",
									payID: id
								}, function() {
									$.loadBasket();
								});
							}
						});
						break;
					case "coupon":
						$.virtualNumpad({
							hint: "Enter the coupon amount",
							callback: function(value) {
								$.addPayment({
									account: "",
									addtobasket: true,
									btnsend: "Coupon",
									cash: value,
									cashonly: 1,
									credit: "",
									prodtitle: "Coupon",
									qty: 1,
									type: "CPN",
									vrate: "",
									payID: id
								}, function() { $.loadBasket(); });
							}
						});
						break;
					default:
						$.addPayment({
							account: obj.data("accid"),
							addtobasket: true,
							btnsend: "Account",
							cash: "",
							cashonly: 0,
							credit: "",
							prodid: "",
							prodtitle: "",
							qty: 1,
							type: "",
							vrate: "",
							payID: id
						}, function() { $.loadBasket(); });
						break;
				}
				event.preventDefault();
			});
		});
	</script>

	<cfset supplier = lCase(session.basket.info.bod) eq "supplier">

	<ul class="payment_list">
		<cfset counter = 0>
		<cfloop array="#payments#" index="item">
			<cfswitch expression="#LCase(item.eaTitle)#">
				<cfcase value="cash">
					<cfif not supplier>
						<li class="payment_item material-ripple" data-method="partcash" data-id="#item.eaID#">
							<span>Part Cash</span>
						</li>
					</cfif>

					<li class="payment_item material-ripple" data-method="fastcash" data-id="#item.eaID#">
						<span>Fast Cash</span>
					</li>
				</cfcase>
				<cfcase value="card">
					<cfif not supplier>
						<li class="payment_item material-ripple" data-method="partcard" data-id="#item.eaID#">
							<span>Part Card</span>
						</li>

						<li class="payment_item material-ripple" data-method="fastcard" data-id="#item.eaID#">
							<span>Fast Card</span>
						</li>
					</cfif>
				</cfcase>
				<cfdefaultcase>
					<cfif not supplier>
						<li class="payment_item material-ripple" data-method="#LCase(item.eaTitle)#" data-accid="#item.eaID#" data-id="#item.eaID#">
							<span>#item.eaTitle#</span>
						</li>
					</cfif>
				</cfdefaultcase>
			</cfswitch>
			<cfset counter++>
			<!---<cfif counter is 1>
				<li class="payment_item" data-method="part#LCase(item.eaTitle)#">Part #item.eaTitle#</li>
				<li class="payment_item" data-method="fast#LCase(item.eaTitle)#">Fast #item.eaTitle#</li>
			<cfelse>
				<li class="payment_item" data-method="#LCase(item.eaTitle)#">#item.eaTitle#</li>
			</cfif>--->
		</cfloop>
		<!---<li class="payment_item_special" data-method="staffdiscount">Staff Discount</li>--->
		<!---<li class="payment_item_special" data-method="paypointcharge">PayPoint Charge</li>--->
		<!---<li class="payment_item_special" data-method="notused"></li>--->
	</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>