<!DOCTYPE html>
<html>
<head>
<title>Font Awesome</title>
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<link href="css/font-awesome.css" rel="stylesheet" type="text/css">

<body>
<cffile action="read" file="#application.site.basedir#css/font-awesome.css" variable="strCSSData">
<cfset strCSSData = strCSSData.ReplaceAll( "[\r\n]+", " " ) />
<cfset strCSSData = strCSSData.ReplaceAll( "/\*.*?\*/", " " ) />
<cfset strCSSData = strCSSData.ReplaceAll( "\{[^\}]*\}", "|" ) />
<cfset arrClasses = ArrayNew( 1 ) />

<cfloop index="strRule" list="#strCSSData#" delimiters="|">
	<cfset strRule = strRule.Trim() />
	<cfif Len( strRule )>
		<cfset arrClasses.AddAll( ListToArray( strRule, "," ) ) />
	</cfif>
</cfloop>

<cfset objUniqueClasses = StructNew() />

<cfloop index="intClass" from="1" to="#ArrayLen( arrClasses )#" step="1">
	<cfset objUniqueClasses[ arrClasses[ intClass ] ] = true />
</cfloop>

<cfoutput>
<i class="fa fa-camera"></i>
	<ul class="fa-ul">
		<cfloop array="#arrClasses#" index="item">
			<li><i class="fa-li fa #REReplaceNoCase(item, '.', '')#"></i>#item#</li>
		</cfloop>
	</ul>
</cfoutput>
</body>
</html>