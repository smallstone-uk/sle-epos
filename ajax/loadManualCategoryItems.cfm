<cfscript>
    items = new App.ProductCat().where('pcatGroup', form.groupID).orderBy('pcatTitle').getArray();
</cfscript>

<cfoutput>
    <script>
        $(document).ready(function(e) {
            $('.products_item').click(function(event) {
                var catID = $(this).data("id");

                $.ajax({
                    type: 'POST',
                    url: 'ajax/productsByCategory.cfm',
                    data: {"catID": catID},
                    success: function(data) {
                        $('.categories_viewer').html(data);
                    }
                });
            });
        });
    </script>
    <cfloop array="#items#" index="item">
        <li class="products_item scalebtn" data-id="#item.pcatID#">
            <span><strong>#item.pcatTitle#</strong></span>
        </li>
    </cfloop>
</cfoutput>
