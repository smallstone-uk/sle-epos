<cfscript>
    query = new App.QueryBuilder();

    query.select("*")
        .from("tblProducts")
        .where("prodOurPrice > 1")
        .orderBy("prodID", "desc")
        .limit(10)
        .offset(5)
        .run();

    writeDump(query);
</cfscript>
