<cfscript>
    route = new Route("ProductController", "index");
    writeOutput("<a href='#route#' target='_newtab'>#route#</a>");
    writeDump(cgi);
</cfscript>
