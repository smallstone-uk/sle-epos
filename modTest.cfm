<cfscript>
    products = new App.Product()
        .orderBy("prodID", "desc")
        .take(1)
        .skip(0)
        .get();

    setVariable("products_new", products);
</cfscript>
