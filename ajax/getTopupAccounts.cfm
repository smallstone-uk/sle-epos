<cfscript>
    accounts = new App.EPOSAccount()
        .where('eaMenu', 'Yes')
        .toArray();
</cfscript>

<cfoutput>
    <script>
        $(document).ready(function(e) {
            #toScript(accounts, 'window.accounts')#;

            new Vue({
                el: '.topup-account',

                data: {
                    accounts: window.accounts,
                    account: null,
                    method: null
                },

                computed: {
                    notValid: function() {
                        return this.account === null
                            || this.method === null;
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

                    getMethodClasses: function(method) {
                        return {
                            'grid-item': true,
                            'selector': true,
                            'active': method === this.method
                        };
                    },

                    selectAccount: function(account) {
                        this.account = account;
                    },

                    selectMethod: function(method) {
                        this.method = method;
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
                                    cash: data.method == 'cash' ? value : 0,
                                    cashonly: 0,
                                    credit: data.method == 'credit' ? value : 0,
                                    prodid: 50621,
                                    prodtitle: "Account Payment",
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
        <div class="grid gap-1 row-size-3 m-b-2 m-t-1" title="Account">
            <div v-for="(account, index) in accounts" :class="getAccountClasses(account)" @click.prevent="selectAccount(account)">
                <span>{{ account.eatitle }}</span>
            </div>
        </div>

        <div class="grid gap-1 col-2 row-size-3 m-b-2" title="Payment Method">
            <div :class="getMethodClasses('cash')" @click.prevent="selectMethod('cash')">
                <span>Cash</span>
            </div>

            <div :class="getMethodClasses('credit')" @click.prevent="selectMethod('credit')">
                <span>Credit</span>
            </div>
        </div>

        <div class="grid gap-1 row-size-3">
            <div class="grid-item">
                <button class="button is-primary" :disabled="notValid" @click.prevent="complete">Complete</button>
            </div>
        </div>
    </div>
</cfoutput>
