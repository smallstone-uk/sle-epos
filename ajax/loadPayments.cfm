<!---28/04/2024--->
<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset payments = epos.LoadPayments(parm)>
<cfset notEnoughCredit = session.basket.header.bcredit + session.basket.header.discdeal + session.basket.header.discstaff + session.till.prefs.mincard>
<cfset session.basket.info.checkout = true>
<cfset session.basket.info.showTotal = true>
<cfoutput>
	<script>
		$(document).ready(function(e) {
			window.eposPaymentsDisabled = false;

			var callback = function() {
				$.loadBasket(function() {
					window.eposPaymentsDisabled = false;
				});
			}

			var cancel = function() {
				window.eposPaymentsDisabled = false;
			}

			$('.payment_item').click(function(event) {
				if (window.eposPaymentsDisabled) return;
				window.eposPaymentsDisabled = true;

				var obj = $(this);
				var type = $(this).data("method");
				var id = $(this).data("id");
				var balance = Number("#session.basket.total.balance#");
				// console.log(type);
				switch (type) {
					case "partcash":
						$.virtualNumpad({
							hint: "Enter a value for part cash",
							cancel: cancel,
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
								}, callback);
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
						}, callback);
						break;
					case "partcard":
						// sometimes shows values from previous transactions 	01/08/2017 (fixed)
						var cashTotal = Number("0"); // session.basket.header.bcash included prize money as cashback so set to zero 
						$.ajax({
						    type: 'GET',
						    url: "#getUrl('ajax/getRemainingBalance.cfm')#",
						    success: function(data) {
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
											value: nf(data, "str")
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
										}, callback);
									},
									cancel: cancel
								});
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
							}, callback);
						} else {
							$.msgBox("You cannot fast card when you have cash only items in the basket. Use part card instead.", "error");
						}
						break;
					case "bt":
						$.addPayment({
							account: "",
							addtobasket: true,
							btnsend: "BT",
							cash: "",
							cashonly: "",
							credit: "",
							prodid: "",
							prodtitle: "",
							qty: 1,
							type: "",
							vrate: "",
							payID: id
						}, callback);
						break;
					case "online":
						$.addPayment({
							account: "",
							addtobasket: true,
							btnsend: "ONLINE",
							cash: "",
							cashonly: "",
							credit: "",
							prodid: "",
							prodtitle: "",
							qty: 1,
							type: "",
							vrate: "",
							payID: id
						}, callback);
						break;
					case "chqs":
						$.virtualNumpad({
							hint: "Enter the cheque value",
							cancel: cancel,
							callback: function(value) {
								$.addPayment({
									account: "",
									addtobasket: true,
									btnsend: "chqs",
									cash: value,
									cashonly: "",
									credit: "",
									prodid: "",
									prodtitle: "",
									qty: 1,
									type: "",
									vrate: "",
									payID: id
								}, callback);
							}
						});
						break;
					case "cpn":
						$.virtualNumpad({
							hint: "Enter the coupon amount",
							cancel: cancel,
							callback: function(value) {
								$.addPayment({
									account: "",
									addtobasket: true,
									btnsend: "cpn",
									cash: value,
									cashonly: 1,
									credit: "",
									prodtitle: "Coupon",
									qty: 1,
									type: "CPN",
									vrate: "",
									payID: id
								}, callback);
							}
						});
						break;
					case "hsv":
						$.virtualNumpad({
							hint: "Enter the Healthy Start coupon amount",
							cancel: cancel,
							callback: function(value) {
								$.addPayment({
									account: "",
									addtobasket: true,
									btnsend: "hsv",
									cash: value,
									cashonly: 1,
									credit: "",
									prodtitle: "Healthy",
									qty: 1,
									type: "hsv",
									vrate: "",
									payID: id
								}, callback);
							}
						});
						break;
					case "acc":
						$.ajax({
						    type: 'GET',
						    url: "#getUrl('ajax/getPayableAccounts.cfm')#",
						    success: function(data) {
						    	window.eposPaymentsDisabled = false;
						    	$.popup(data);
						    }
						});
						break;
					case "waste":
						$.addPayment({
							account: id,
							addtobasket: true,
							btnsend: "waste",
							cash: "",
							cashonly: "",
							credit: "",
							prodid: "",
							prodtitle: "Waste Account",
							qty: 1,
							type: "",
							vrate: "",
							payID: id
						}, callback);
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
							prodtitle: "General Account",
							qty: 1,
							type: "",
							vrate: "",
							payID: id
						}, callback);
						break;
				}

				event.preventDefault();
			});
		});
	</script>

	<cfset supplier = lCase(session.basket.info.bod) eq "supplier">
	<cfset waste = lCase(session.basket.info.mode) eq "wst">
	<ul class="payment_list">
		<cfset counter = 0>
		<cfif waste>
			<li class="payment_item material-ripple" data-method="waste" data-id="13" style="background-color: ##ff3; color:##000; font-weight: bold;">
				<span>Waste Account</span>
			</li>
		<cfelse>
		
			<cfloop array="#payments#" index="item">
				<cfswitch expression="#LCase(item.eaCode)#">
					<cfcase value="cash">
						<cfif not supplier>
							<li class="payment_item material-ripple" data-method="partcash" data-id="#item.eaID#" style="#item.eaStyle#">
								<span>Part #item.eaTitle#</span>
							</li>
						</cfif>
	
						<li class="payment_item material-ripple" data-method="fastcash" data-id="#item.eaID#" style="#item.eaStyle#">
							<span>Fast #item.eaTitle#</span>
						</li>
					</cfcase>
	
					<cfcase value="card">
						<cfif not supplier>
							<li class="payment_item material-ripple" data-method="partcard" data-id="#item.eaID#" style="#item.eaStyle#">
								<span>Part #item.eaTitle#</span>
							</li>
	
							<li class="payment_item material-ripple" data-method="fastcard" data-id="#item.eaID#" style="#item.eaStyle#">
								<span>Fast #item.eaTitle#</span>
							</li>
						</cfif>
					</cfcase>
	
					<cfcase value="account">
						<cfif not supplier>
							<li class="payment_item material-ripple" data-method="account" data-id="#item.eaID#" style="#item.eaStyle#">
								<span>Account</span>
							</li>
						</cfif>
					</cfcase>
	
					<cfdefaultcase>
						<cfif not supplier>
							<li class="payment_item material-ripple" data-method="#LCase(item.eaCode)#" 
								data-accid="#item.eaID#" data-id="#item.eaID#" style="#item.eaStyle#">
								<span>#item.eaTitle#</span>
							</li>
						</cfif>
					</cfdefaultcase>
				</cfswitch>
				<cfset counter++>
			</cfloop>
		</cfif>
	</ul>
	
	<cfif !waste>
<!---
		<div class="lottoCheck">
			On this transaction...<br />
			<cfif session.basket.total.scratchcard neq 0>
				Check scratchcards total: &pound;#DecimalFormat(-session.basket.total.scratchcard)#<br />
			<cfelse>
				No scratch cards were sold.<br />
			</cfif>
			<cfif session.basket.total.lottery neq 0>
				Check lottery tickets total: &pound;#DecimalFormat(-session.basket.total.lottery)#<br />
			<cfelse>
				No lottery tickets were sold.<br />
			</cfif>
			<cfif session.basket.total.sprize + session.basket.total.lprize neq 0>
				Check prizes total: &pound;#DecimalFormat(session.basket.total.lprize + session.basket.total.sprize)#<br />
			<cfelse>
				No prizes were redeemed.<br />
			</cfif>
		</div>
--->		
		<cfif session.basket.header.balance gt 0 AND session.basket.info.type neq 'purch'>
			<cfif notEnoughCredit gt 0 OR session.basket.header.balance LT session.till.prefs.mincard>
				<script>sound('error2')</script>
				<div class="payWarning">
					Cash only please!<br />
					Spend another &pound;#DecimalFormat(notEnoughCredit)# to pay on card.
				</div>
			<cfelse>
				<div class="payOK">
					Card payment acceptable.
				</div>
			</cfif>
		</cfif>
	</cfif>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>
