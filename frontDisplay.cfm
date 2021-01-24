<cfoutput>
    <div id="app-frontdisplay" v-if="loaded">
        <div v-show="inProgress">
            <div class="product">
                <h1>{{ basket.lastitemadded.data.title }}</h1>

                <span>
                    {{ basket.lastitemadded.data.qty }}
                    &times;
                    {{ basket.lastitemadded.data.unitprice | currency }}
                </span>
            </div>

            <div class="total">
                {{ basket.total.balance | currency }}
            </div>
        </div>

        <div v-show="!inProgress">
            <h1 class="product">Welcome to Shortlanesend Store</h1>
        </div>
    </div>
</cfoutput>

<script src="js/vue.js"></script>
<script src="js/vue-resource.js"></script>

<script>
    Vue.filter('currency', function(value) {
        var language = (navigator.language || navigator.browserLanguage).split('-')[0];

        return value.toLocaleString(language, {
            style: 'currency',
            currency: 'gbp'
        });
    });

    window.opt = function(object) {
        return new Proxy(object || {}, {
            get(target, name) {
                return (name in target)
                    ? target[name]
                    : null;
            }
        });
    }

    new Vue({
        el: '#app-frontdisplay',

        data: {
            basket: null
        },

        computed: {
            loaded() {
                return this.basket !== null;
            },

            inProgress() {
                return opt(this.basket.lastitemadded).data
                    ? true
                    : false;
            }
        },

        methods: {
            fetch() {
                return this.$http.get('/ajax/frontDisplay.cfm')
                    .then(r => this.basket = JSON.parse(r.body));
            }
        },

        mounted() {
            this.fetch().then(r => {
                // setInterval(this.fetch, 1000);
            });
        }
    });
</script>

<style>
    #app-frontdisplay {
        display: grid;
        grid-template-columns: 1fr;
        grid-template-rows: 1fr 1fr;
        grid-gap: 5rem;
        font-family: monospace;
        height: 100%;
    }

    #app-frontdisplay .product {
        text-align: center;
        font-size: 2rem;
        padding-top: 10rem;
    }

    #app-frontdisplay .total {
        text-align: center;
        font-size: 10rem;
    }
</style>
