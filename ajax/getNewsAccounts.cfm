<cfoutput>
    <div style="padding: 2rem" class="topup-account">
        <div class="w-full m-b-3 pull-left">
            <input ref="query" placeholder="Search for a news account" class="w-full">
        </div>

        <div class="grid gap-1 row-size-3 m-b-2 m-t-1 w-full" title="Account">
            <div v-for="(account, index) in accounts" class="grid-item selector" @click.prevent="select(account)">
                <span style="padding: 0 1rem">
                    <span class="pull-left text-left">
                        {{ account.name }}
<!---                         <span class="pull-left w-full">Address</span> --->
                    </span>

                    <span class="pull-right text-right">{{ 150 | currency }}</span>
                </span>
            </div>
        </div>
    </div>

    <script>
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
                show: true,
                query: 'lemon',
                accounts: []
            },

            computed: {
                style: function () {
                    return {
                        display: 'inline-block',
                        width: '100%'
                    };
                }
            },

            watch: {
                query: function (newValue, oldValue) {
                    if (newValue !== oldValue) {
                        this.search();
                    }
                }
            },

            methods: {
                search: function () {
                    ajax.post('/ajax/searchNewsAccounts.cfm', { query: this.query })
                        .then(function (r) {
                            this.accounts = r.data.accounts;                            
                        }.bind(this));
                },

                select: function (account) {
                    $.virtualNumpad({
                        hint: "Enter an amount",
                        callback: function(value) {
                            ajax.post('/ajax/addNewsAccountToBasket.cfm', {
                                account: account,
                                amount: value
                            }).then(function (r) {
                                $.loadBasket();
                            });
                        }
                    });
                }
            },

            created: function () {
                if (this.query !== null) {
                    this.search();
                }
            },

            mounted: function () {
                $(this.$refs.query).virtualKeyboard({
                    onkey: function (value) {
                        this.query = value;
                    }.bind(this)
                });
            }
        });
    </script>
</cfoutput>
