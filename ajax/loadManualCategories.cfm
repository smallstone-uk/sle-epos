<cfscript>
    products = new App.Product().where('prodCatID', 2).orderBy('prodTitle').getArray();
</cfscript>

<cfoutput>
    <script>
        $(document).ready(function(e) {
            $('.products_item').click(function(event) {
                var obj = $(this);
                var dataAttributes = getDataAttributes(obj);

                if (dataAttributes.credit != 0 || dataAttributes.cash != 0) {
                    $.addToBasket(dataAttributes);
                } else {
                    $.virtualNumpad({
                        maximum: 50,
                        overide: true,
                        callback: function(value) {
                            $.addToBasket( getDataAttributes(obj, "plain", {
                                credit: ( dataAttributes.cashonly == 1 ) ? 0 : value,
                                cash: ( dataAttributes.cashonly == 1 ) ? value : 0
                            }));
                        }
                    });
                }
            });
        });
    </script>

    <ul class="products_list">
        <cfloop array="#products#" index="item">
            <li
                class="products_item material-ripple"
                data-account=""
                data-addtobasket="true"
                data-btnsend="add"
                data-class="item"
                data-discount="0"
                data-discountable="#item.prodStaffDiscount#"
                data-pubid="0"
                data-prodid="#item.prodID#"
                data-prodtitle="#item.prodTitle#"
				data-unitsize=""	<!---#item.siUnitSize#--->
                data-qty="1"
                data-type="prod-#item.prodID#"
                data-prodClass="#item.prodClass#"
                data-vcode="#session.vat['#DecimalFormat(item.prodVatRate)#']#"
                data-vrate="#item.prodVatRate#"
                data-cashonly="#item.prodCashOnly#"
                data-prodsign="#item.prodSign#"
                data-itemclass="#item.hasOne('EPOSCat', 'prodEposCatID').epcKey#"
                data-credit="0"
                data-cash="0"
				<cfif StructKeyExists(item,"siUnitTrade")>data-unittrade="#item.siUnitTrade#"
					<cfelse>data-unittrade="#val(item.prodUnitTrade)#"</cfif>
            ><span><strong>#item.prodTitle#</strong></span></li>
        </cfloop>
    </ul>
</cfoutput>
