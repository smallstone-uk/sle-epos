<!---28/04/2024--->
<cfscript>
    accounts = new App.EPOSAccount().getPayableAccounts();
</cfscript>

<cfoutput>
    <script>
        $(document).ready(function(e) {
            #toScript(accounts, 'window.accounts')#;

            Vue.filter('currency', function(value) {
                var language = (navigator.language || navigator.browserLanguage).split('-')[0];

                return value.toLocaleString(language, {
                    style: 'currency',
                    currency: 'gbp'
                });
            });

            new Vue({
                el: '.topup-account',

                data: {
                    accounts: window.accounts,
                    account: null
                },

                computed: {
                    notValid: function() {
                        return this.account === null;
                    }
                },

                methods: {
                    getAccountClasses: function(account) {
                        return {
                            'grid-item': true,
                            'selector': true,
                            'active': account.eaid === opt(this.account).eaid
                        };
                    },

                    selectAccount: function(account) {
                        this.account = account;
                    },

                    complete: function() {
                        $('.popup_box, .dim').remove();

                        var data = this.$data;

                        $.virtualNumpad({
                            callback: function(value) {
                                $.addItem({
                                    account: data.account.eaid,
                                    addtobasket: true,
                                    btnsend: "Add",
                                    cash: 0,
                                    cashonly: 0,
                                    credit: value,
                                    prodid: 50621,
                                    prodtitle: "Account Payment",
									unitsize: "",
                                    qty: 1,
                                    type: "",
                                    vrate: 0,
                                    payID: '',
                                    prodSign: 1,
                                    itemClass: 'ACCPAY',
                                    prodClass: ''
                                }, function() {
                                    $.loadBasket(function() {
                                        $('.popup_box, .dim').remove();
                                    });
                                });
                            }
                        });
                    }
                }
            });
        });
    </script>

    <div class="topup-account">
        <div class="grid gap-1 row-size-4 m-b-2 m-t-1" title="Account">
            <div v-for="(account, index) in accounts" :class="getAccountClasses(account)" @click.prevent="selectAccount(account)">
                <span style="padding: 0 1rem">
                    <span class="pull-left text-left">{{ account.eatitle }}</span>
                    <span class="pull-right text-right">{{ account.balance | currency }}</span>
                </span>
            </div>
        </div>

        <div class="grid gap-1 row-size-3">
            <div class="grid-item">
                <button class="button is-primary" :disabled="notValid" @click.prevent="complete">Pay Selected Account...</button>
            </div>
        </div>
    </div>
</cfoutput>
