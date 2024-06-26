<!---28/04/2024--->
<cftry>
<cfobject component="#application.site.codePath#" name="e">

<cfif StructKeyExists(session,"user") AND session.user.ID eq 0>
	<script>sound('error2')</script>
	<div class="basket_error">Your session timed out. Please login again.</div>
	<cfexit>
</cfif>
<cfset loc = {}>
<cfset loc.thisBasket = (session.till.isTranOpen) ? session.basket : session.till.prevtran>
<cfif StructIsEmpty(loc.thisBasket)>
	<!--- nothing to show --->
	<cfexit>
</cfif>

<cfoutput>
	<div class="basket_relative">
		<script>
			$(document).ready(function(e) {
				updateTillModeDisplay();

				$('.basket_clear').click(function(event) {
					sound('question');
					$.confirmation("Are you sure you want to clear the basket?", function() {
						ajax.emptyBasket({}, function(data) {
							$.loadBasket();
							$('##hti_home').click();
	                        $('*').blur();
						});
					});
					event.preventDefault();
				});

				$('.basket_checkout').click(function(event) {
					$('.categories_viewer').loadPayments();
	                $('*').blur();
					event.preventDefault();
				});

				$('.basket_receipt').click(function(event) {
					var enabled = $(this).data('enabled');

					if (enabled) {
						ajax.printReceipt({}, function(data) {
							$('.printable').html(data);
		                    $('*').blur();
						});
					}

					event.preventDefault();
				});

				$('.basket_closerefund').click(function(event) {
					var balance = $(this).data("balance");

					ajax.closeRefund({"balance": -balance}, function(data) {
						$('.basket').append(data);
	                    $('*').blur();
					});

					event.preventDefault();
				});
			});
		</script>

		<div class="eposBasketDivWrap">
			<cfif Len(session.basket.info.errMsg)>
				<script>
					$(document).ready(function(e) {
						sound('error2');
					// once error appears, till breaks and items cannot be added to basket.
					//	var err_box = document.getElementById('##bskt_Error');
					//	err_box.scrollIntoView();
						//$('.basket_error').scrollIntoView();
					})
				</script>
				<div id="bskt_Error" class="basket_error">
					#session.basket.info.errMsg#
				</div>
			</cfif>

			<cfif not loc.thisBasket.tranID>
				<script>
					$(document).ready(function(e) {
					//	var canAmend = $(this).attr("data-discountable");
						$('.basket_payment, .basket_discount').touchHold([
							{
								text: "remove",
								action: function(a, e) {
									$.ajax({
										type: "POST",
										url: "ajax/removeFromBasket.cfm",
										data: {
											"type": a.type,
											"index": a.prodid
										},
										success: function(data) {
											$.loadBasket();
											$('##hti_home').click();
										}
									});
								}
							}
						]);

						$('.ebt_payment').touchHold([
							{
								text: "remove",
								action: function(a, e) {
									$.ajax({
										type: "POST",
										url: "ajax/removePaymentFromBasket.cfm",
										data: a,
										success: function(data) {
											$.loadBasket();
											$('##hti_home').click();
										}
									});
								}
							}
						]);

						$('.basket_item').touchHold([
							{
								text: "add one",
								action: function(a, e) {
									ajax.incBasketItem(a, $.loadBasket);
									$('##hti_home').click();
								}
							},
							{
								text: "add many...",
								action: function(a, e) {
									$.virtualNumpad({
										wholenumber: true,
										minimum: 1,
										maximum: 10,
										overide: true,
										callback: function(value) {
											a.incqty = value;
											ajax.incBasketItemMany(a, $.loadBasket);
											$('##hti_home').click();
										}
									});
								}
							},
							{
								text: "remove one",
								action: function(a, e) {
									ajax.removeFromBasket(a, $.loadBasket);
									$('##hti_home').click();
								}
							},
							{
								text: "remove all",
								action: function(a, e) {
									ajax.removeAllFromBasket(a, $.loadBasket);
									$('##hti_home').click();
								}
							},
							{
								text: "amend price...",
								condition: function (item) {
									// item is the selected basket item
									// console.log(item.data('discountable'));
									// return String(item.data('discountable')).toLowerCase() == 'yes'
									var discText = String(item.data('discountable')).toLowerCase();
									return discText == 'yes' || discText == 'true';
								},
								action: function(a, e) {
									if (typeof a.origprice !== 'undefined') {
										var maxy =  -a.origprice;
									} else {
										var maxy =  -a.retail;
									}
									$.virtualNumpad({
										wholenumber: false,
										minimum: (maxy*0.8).toFixed(2),
										maximum: maxy.toFixed(2),
										overide: false,
										callback: function(value) {
											a.newretail = value;
											ajax.amendPrice(a, $.loadBasket);
											$('##hti_home').click();
										}
									});
								}
							}
						]);

						// Auto-scroll to bottom
						var basket = $('.eposBasketDivWrap');
						var height = basket[0].scrollHeight;
						basket.scrollTop(height);
					});
				</script>
			</cfif>
			#e.ShowBasket("html")#
		</div>

		<cfif loc.thisBasket.tranID>
			<script>
				$(document).ready(function(e) {
					$('##hti_home').click();
				});
			</script>
		</cfif>

		<cfset loc.metaTitle = "Balance Due from Customer">
		<cfset loc.metaValue = decimalFormat(0.00)>
		<cfset loc.metaClass = "bmeta_dueto">
		<cfif loc.thisBasket.info.itemcount gt 0>
			<cfif loc.thisBasket.info.mode eq "reg">
				<cfif loc.thisBasket.info.canClose>
					<cfif loc.thisBasket.total.balance lte 0.001>
						<cfset loc.metaTitle = "Change">
						<cfset loc.metaValue = decimalFormat(-loc.thisBasket.info.change)>
						<cfset loc.metaClass = (loc.metaValue eq 0) ? "bmeta_dueto" : "bmeta_changeto">
					<cfelse>
						<cfset loc.metaTitle = "Balance Due from Customer">
						<cfset loc.metaValue = decimalFormat(loc.thisBasket.total.balance)>
						<cfset loc.metaClass = "bmeta_duefrom">
					</cfif>
				<cfelse>
					<cfif loc.thisBasket.total.balance gt 0.001>
						<cfset loc.metaTitle = "Balance Due from Customer">
						<cfset loc.metaValue = decimalFormat(loc.thisBasket.total.balance)>
						<cfset loc.metaClass = "bmeta_duefrom">
					<cfelse>
						<cfset loc.metaTitle = "Balance Due to Customer">
						<cfset loc.metaValue = decimalFormat(loc.thisBasket.total.balance)>
						<cfset loc.metaClass = "bmeta_dueto">
					</cfif>
				</cfif>
			<cfelse>
				<cfif loc.thisBasket.total.balance lte 0>
					<cfset loc.metaTitle = "Balance Due to Customer">
					<cfset loc.metaValue = decimalFormat(loc.thisBasket.total.balance)>
					<cfset loc.metaClass = "bmeta_dueto">
				<cfelse>
					<cfset loc.metaTitle = "Balance Due from Customer">
					<cfset loc.metaValue = decimalFormat(loc.thisBasket.total.balance)>
					<cfset loc.metaClass = "bmeta_duefrom">
				</cfif>
			</cfif>
		</cfif>

		<div class="basket_meta #loc.metaClass#">
			<div class="bmeta_balancedue">
				<span class="bmeta_heading">#loc.metaTitle#</span>
				<span class="bmeta_value">#loc.metaValue#</span>
			</div>

			<div class="bmeta_sub">
				<span class="bmetasub_itemcount">
					#loc.thisBasket.info.itemCount# items
				</span>

				<cfif not loc.thisBasket.tranID is 0>
					<span class="bmetasub_tranref">
						###loc.thisBasket.tranID#
					</span>
				</cfif>
			</div>
		</div>

		<div class="basket_controls">
			<a href="javascript:void(0)" class="basket_clear material-ripple"><i class="icon-spinner11"></i></a>
			<a href="javascript:void(0)" class="basket_checkout material-ripple">Checkout</a>

			<a
				href="javascript:void(0)"
				class="basket_receipt material-ripple <cfif loc.thisBasket.tranID is 0>disabled</cfif>"
				data-enabled="<cfif not loc.thisBasket.tranID is 0>true<cfelse>false</cfif>"
			><i class="icon-printer"></i></a>
		</div>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
		output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>
