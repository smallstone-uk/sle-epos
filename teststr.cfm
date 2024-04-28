<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Test Text</title>
</head>
<cfobject component="#application.site.codePath#" name="ecfc">
<cfset parm.datasource = ecfc.GetDataSource()>

<body>
<cfquery name="QDeals" datasource="#parm.datasource#">
	SELECT * FROM tblEPOS_Deals
	WHERE edID=82
</cfquery>
<cfoutput query="QDeals">
	#edTitle#<br />
	<cfloop from="1" to="#len(edTitle)#" index="i">
		<cfset ch = mid(edTitle,i,1)>
		#ch# = #asc(ch)#<br />
	</cfloop>
	<cfset loc.dealStr = Replace(edTitle,"#Chr(163)#","\x9c","all")>#loc.dealStr#<br />
	#Chr(163)# #Chr(163)# #Chr(163)# #Chr(163)# #Chr(163)#
</cfoutput>
</body>
</html>