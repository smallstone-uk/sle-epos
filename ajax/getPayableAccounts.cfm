<cfscript>
    accounts = new App.EPOSAccount()
        .where('eaMenu', 'Yes')
        .getArray();
</cfscript>

<cfoutput>
    <div class="account-list">
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

        <cfloop array="#accounts#" index="account">
            <div class="account-item" data-id="#account.eaID#">
                #account.eaTitle#
            </div>
        </cfloop>
    </div>
</cfoutput>