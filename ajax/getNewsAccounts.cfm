<cfoutput>
    <div class="news-account">
        <input v-model="query" placeholder="Search for a news account">

        <ul>
            <li :style="style" v-for="(account, index) in accounts" :key="index">
                {{ account.name }}
            </li>
        </ul>
    </div>

    <script>
        Vue.filter('currency', value => {
            let language = (navigator.language || navigator.browserLanguage).split('-')[0];

            return value.toLocaleString(language, {
                style: 'currency',
                currency: 'gbp'
            });
        });

        new Vue({
            el: '.news-account',

            data: {
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
                    this.query = newValue;

                    if (newValue !== oldValue) {
                        this.search();
                    }
                }
            },

            methods: {
                search: function () {
                    ajax.get('/ajax/searchNewsAccounts.cfm?query=' + this.query)
                        .then(function (r) {
                            this.accounts = r.data.accounts;
                        }.bind(this));
                }
            },

            created: function () {
                if (this.query !== null) {
                    this.search();
                }
            }
        });
    </script>
</cfoutput>
