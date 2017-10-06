<cfobject component="#application.site.codePath#" name="ecfc">

<cfset epos = ecfc.LoadEPOSTotals({
	"reportDate" = createDate(2017, 10, 6)
})>

<cfset writeDump(epos)>
