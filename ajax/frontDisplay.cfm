<cfset data = structIsEmpty(session.till.prevtran) ? session.basket : session.till.prevtran>

<cfoutput>
    #jsonEncode(data)#
</cfoutput>
