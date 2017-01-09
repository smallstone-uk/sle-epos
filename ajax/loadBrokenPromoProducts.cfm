<cfsetting requesttimeout="300">

<cfset adminUrl = "http://#application.site.host#.shortlanesendstore.co.uk">
<cfset products = new App.Product()
    .orderedBy("prodID", "desc")
    .take(form.take)
    .skip(form.skip)
    .get()>

<cfoutput>
    <cfloop array="#products#" index="product">
        <cfset product.items = product.getPromoStockItems()>
        <cfset product.deals = product.getDeals()>

        <cfif NOT arrayIsEmpty(product.items) AND arrayIsEmpty(product.deals)>
            <!--- No deal assigned --->
            <tr>
                <td><a href="#adminUrl#/ProductStock6.cfm?product=#product.prodID#" target="_newtab">#product.prodID#</a></td>
                <td>#product.prodTitle#</td>
                <td>
                    <table class="table table-striped table-condensed table-bordered">
                        <tr>
                            <th>ID</th>
                            <th>Deal</th>
                            <th>Expired</th>
                        </tr>
                        <cfloop array="#product.deals#" index="deal">
                            <cfset deal.header = deal.getHeader()>
                            <tr>
                                <td>#deal.header.edID#</td>
                                <td>#deal.header.edTitle#</td>
                                <td>#deal.header.hasExpired()#</td>
                            </tr>
                        </cfloop>
                    </table>
                </td>
                <td>
                    <table class="table table-striped table-condensed table-bordered">
                        <tr>
                            <th>Item</th>
                            <th>Order</th>
                            <th>Ref</th>
                        </tr>
                        <cfloop array="#product.items#" index="item">
                            <cfset item.order = item.getOrder()>
                            <tr>
                                <td>#item.siID#</td>
                                <td>#item.order.soID#</td>
                                <td>#item.order.soRef#</td>
                            </tr>
                        </cfloop>
                    </table>
                </td>
                <cfif arrayIsEmpty(product.getBarcodes())>
                    <!--- Add barcode --->
                    <td class="danger">TODO Add Barcode</td>
                <cfelse>
                    <td class="success"></td>
                </cfif>
            </tr>
        </cfif>
    </cfloop>
</cfoutput>
