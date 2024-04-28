<!---28/04/2024--->
<cfscript>
    accounts = new App.EPOSAccount()
        .where('eaMenu', 'Yes')
		.andWhere ('eaActive', 1)
        .getArray();
</cfscript>

<cfoutput>
	<p class="account-title">Select account to charge this basket to:-</p>
	<script>
		$(document).ready(function(e) {
			$('.account-item').click(function(event) {
				var account = $(this);

				$.addPayment({
					account: account.data('id'),
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
					payID: account.data('id')
				}, function() {
					$.loadBasket(function() {
						window.eposPaymentsDisabled = false;
						$('.popup_box, .dim').remove();
					});
				});

				event.preventDefault();
			});
		});
	</script>

    <div class="account-list">
        <div class="grid gap-1 row-size-4">
            <cfloop array="#accounts#" index="account">
                <div class="grid-item selector account-item" data-id="#account.eaID#">
                    <span>#account.eaTitle#</span>
                </div>
            </cfloop>
        </div>
    </div>
</cfoutput>
