<cfcomponent displayname="epos">

	<cfset coreArea={}>

	<cffunction name="InitCoreArea" access="public" returntype="struct">
		<cfargument name="parm" type="struct" required="yes">
		<cfset var key=0>
		<cftry>
			<cfloop collection="#parm#" item="key">
				<cfset "coreArea.#key#"=StructFind(parm,key)>
			</cfloop>
			<cfset coreArea.errors=0>
			<cfset coreArea.init=true>
		<cfcatch type="any">
			<cfset coreArea.init=false>
			<cfset coreArea.error=cfcatch>
		</cfcatch>
		</cftry>
		<cfreturn coreArea>
	</cffunction>
	
	<cffunction name="GetCoreArea" access="public" returntype="struct">
		<cfreturn coreArea>
	</cffunction>
	
	<cffunction name="newSession" access="public" output="false" returntype="boolean">
		<cfset onSessionStart()>
		<cfreturn true>
	</cffunction>
	
	<cffunction name="GetInfo" output="false" returnType="any">
		<cfargument name="structure" type="struct" required="true">
		<cfargument name="field" type="string" required="true">
		<cftry>
			<cfif StructKeyExists(structure,field)>
				<cfreturn StructFind(structure,field)>
			<cfelse>
				<cfreturn "">
			</cfif>
		<cfcatch type="any">
			<cfreturn "">	<!--- undefined --->
		</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="SetInfo" output="false" returnType="boolean">
		<cfargument name="structure" type="struct" required="true">
		<cfargument name="field" type="string" required="true">
		<cfargument name="value" type="any" required="true">
		<cfif StructKeyExists(structure,field)>
			<cfreturn StructUpdate(structure,field,value)>
		<cfelse>
			<cfreturn StructInsert(structure,field,value)>
		</cfif>
	</cffunction>

	<cffunction	name="GetRequestTimeout" access="public" returntype="numeric" output="false" hint="Returns the timeout period for the current page request.">	
		<cfset var local=StructNew() />
		<cfset local.RequestMonitor = CreateObject("java","coldfusion.runtime.RequestMonitor")>
		<cfreturn local.RequestMonitor.GetRequestTimeout() />
	</cffunction>

	<cffunction name="HandleError" access="public" returntype="struct" output="yes" hint="Extract info from cfcatch struct and write it to an error page.">
		<cfargument name="err" type="any" required="yes">
		<cfargument name="data" type="any" required="no" default="">
		<cfset var result=StructNew()>
		<cfset var tagItem=StructNew()>
		<cfset var i=0>
		<cfset var outputfile="#LSDateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHmmss')#">
		
		<cfsetting requesttimeout="#(getRequestTimeout() + 3)#">	<!--- add more time to handle time-outs --->
		<cfset result.tags=ArrayNew(1)>
		<cfloop from="1" to="#ArrayLen(err.TagContext)#" index="i">
			<cfset tagItem={}>
			<cfset StructInsert(tagItem,err.TagContext[i].template,err.TagContext[i].line)>
			<cfset ArrayAppend(result.tags,tagItem)>
		</cfloop>
		<cfswitch expression="#err.type#">
			<cfcase value="Database">
				<cfset result.sql=err.sql>
			</cfcase>
		</cfswitch>
		<cfset result.type=err.type>
		<cfset result.message=err.message>
		<cfset result.detail=err.detail>
		<cfset result.errorPath="#application.core.dir_logs#err#outputfile#.htm">
		<cfset result.session=session.visitor>
		<cfif StructKeyExists(arguments,"data")>
			<cfset result.data=data>
		</cfif>
		<cfif StructKeyExists(application.core,"errors")>
			<cfset application.core.errors++>
		</cfif>
		<cfdump var="#result#" format="html" output="#result.errorPath#">
		<cfreturn result>
	</cffunction>

	<cffunction name="FormatBytes" output="false" returntype="string">
		<cfargument name="bytes" type="numeric" required="true">
		<cfset var str="">
		<cfif bytes GT  1099511627776>
			<cfset str=NumberFormat(bytes / 1099511627776,"_.__") & "TB">
		<cfelseif bytes GT 1073741824>
			<cfset str=NumberFormat(bytes / 1073741824,"_.__") & "GB">
		<cfelseif bytes GT 1048576>
			<cfset str=NumberFormat(bytes / 1048576,"_.__") & "MB">
		<cfelseif bytes GT 1024>
			<cfset str=NumberFormat(bytes / 1024,"_.__") & "KB">
		<cfelse>
			<cfset str=NumberFormat(bytes) & "bytes">
		</cfif>
		<cfreturn str>
	</cffunction>
	
	<cffunction name="QueryToStruct" access="public" returntype="struct" output="false" hint="returns a struct for a single record from query.">
		<cfargument name="queryname" type="query" required="true">
		<cfset var qStruct={}>
		<cfset var columns=queryname.columnlist>
		<cfset var colName="">
		<cfset var fldValue="">
		<cfloop query="queryname">
			<cfset qStruct={}>
			<cfloop list="#columns#" index="colName">
				<cfset fldValue=StructFind(queryname,colName)>
				<cfset StructInsert(qStruct,colName,fldValue)>
			</cfloop>
			<cfreturn StructCopy(qStruct)>	<!--- only return first record if query contains more than one. --->
		</cfloop>
		<cfreturn qStruct> <!--- returns empty struct if query if empty --->
	</cffunction>

	<cffunction name="QueryToArrayOfStruct" access="public" returntype="array" output="false" 
		hint="returns array of structs of records from query. Can return an array containing an empty struct.">
		<cfargument name="queryname" type="query" required="true">
		<cfset var qArray=ArrayNew(1)>
		<cfset var qStruct=StructNew()>
		<cfset var columns=queryname.columnlist>
		<cfset var colName="">
		<cfset var fldValue="">
		<cfloop query="queryname">
			<cfset qStruct=StructNew()>
			<cfloop list="#columns#" index="colName">
				<cfset fldValue=StructFind(queryname,colName)>
				<cfset StructInsert(qStruct,colName,fldValue)>
			</cfloop>
			<cfset ArrayAppend(qArray,StructCopy(qStruct))>
		</cfloop>
		<cfif ArrayIsEmpty(qArray)>
			<cfset ArrayAppend(qArray,QueryNew(columns))>
		</cfif>
		<cfreturn qArray>
	</cffunction>

	<cffunction name="FindTemplate" output="false" returntype="boolean">
		<cfargument name="filePath" type="string" required="false">
		<cfset var result=false>
		<cfset var checkPath="">
		<cfif IsDefined("filePath")>
			<cfif Left(filePath,3) eq "std">
				<cfset checkPath="#application.MapCFPath#\#filePath#">
			<cfelse>
				<cfset checkPath="#application.baseDir##filePath#">
			</cfif>
			<cfset result=FileExists(checkPath)>
		<cfelse>
			<cftrace text="no path specified" />
		</cfif>
		<cfreturn result>
	</cffunction>
	
	<cffunction name="EncryptStr" output="false" returntype="string">
		<cfargument name="pwdStr" type="string" required="false">
		<cfargument name="encStr" type="string" required="false">
		<cfset var mypw="">
		<cfif NOT IsDefined("pwdStr") OR len(pwdStr) EQ 0><cfreturn ""></cfif>		<!--- no string passed, return nothing --->
		<cfif NOT IsDefined("encStr") OR len(encStr) EQ 0><cfreturn pwdStr></cfif>	<!--- no string passed, return original intact --->
		<cftry>
			<cfset mypw=Encrypt(pwdStr,encStr)>		<!--- attempt encryption --->
			<cfset mypw=toBase64(mypw)>				<!--- convert to base64 for storage--->
			<cfcatch type="expression">				<!--- error during encryption --->
				<cfset mypw=pwdStr>					<!--- return original string --->
			</cfcatch>
		</cftry>
		<cfreturn mypw>
	</cffunction>
	
	<cffunction name="DecryptStr" output="false" returntype="string">
		<cfargument name="pwdStr" type="string" required="false">
		<cfargument name="encStr" type="string" required="false">
		<cfset var mypw="">
		<cfif NOT IsDefined("pwdStr") OR len(pwdStr) EQ 0><cfreturn ""></cfif>		<!--- no string passed, return nothing --->
		<cfif NOT IsDefined("encStr") OR len(encStr) EQ 0><cfreturn pwdStr></cfif>	<!--- no string passed, return original intact --->
		<cftry>
			<cfset mypw=toBinary(pwdStr)>					<!--- convert back to string from base64--->
			<cfset mypw=Decrypt(toString(mypw),encStr)>		<!--- Convert to string from binary then decrypt --->
			<cfcatch type="expression">						<!--- error during decryption --->
				<cfset mypw=pwdStr>							<!--- return original string --->
			</cfcatch>
		</cftry>
		<cfreturn mypw>
	</cffunction>
	
	<cffunction name="CreatePassword" access="public" returntype="struct" hint="">
		<cfargument name="CharacterSet" required="no" default="alphanumeric">	<!---[alphanumeric|numeric|alpha]--->
		<cfargument name="Case" required="no" default="mixed">					<!---[mixed|upper|lower]--->
		<cfargument name="Symbols" required="no" default="no">					<!---[yes|no]--->
		<cfargument name="Length" required="no" default="8">
		<cfset var result={}>
		
		<cfset result.args=arguments>
		<cfset result.charArray=[]>	
		<cfif CharacterSet is "alphanumeric" OR CharacterSet is "numeric">		<!--- include numbers --->
			<cfloop from="48" to="57" index="item">
				<cfset ArrayAppend(result.charArray,Chr(item))>
			</cfloop>
		</cfif>
		<cfif CharacterSet is "alphanumeric" OR CharacterSet is "alpha">		<!--- include alphabet --->
			<cfif Case is "mixed" or Case is "upper">							<!--- add upper chars --->
				<cfloop from="65" to="90" index="item">
					<cfset ArrayAppend(result.charArray,Chr(item))>
				</cfloop>
			</cfif>
			<cfif Case eq "mixed" or Case eq "lower">							<!--- add lower chars --->
				<cfloop from="97" to="122" index="item">
					<cfset ArrayAppend(result.charArray,Chr(item))>
				</cfloop>
			</cfif>
		</cfif>
		<cfif Symbols is "yes">													<!--- add symbols --->
			<cfloop list="33,35,36,37,38,42,43,61,63,64" index="item">
				<cfset ArrayAppend(result.charArray,Chr(item))>
			</cfloop>
		</cfif>
		<cfset result.pwd="">
		<cfset result.arrLen=ArrayLen(result.charArray)>
		<cfif result.arrLen eq 0>
			<cfset result.msg="no characters selected for the password, check the parameters">
		<cfelse>
			<cfloop from="1" to="#Length#" index="item">
				<cfset result.pwd="#result.pwd##result.charArray[RandRange(1,result.arrLen)]#">
			</cfloop>
		</cfif>
		<cfset result.pwdlen=Len(result.pwd)>
		<cfreturn result>
	</cffunction>

	<cffunction name="Phoenetic" output="false" returntype="string">
		<cfargument name="pwdStr" type="string" required="false">
		<cfif NOT IsDefined("pwdStr")><cfreturn ""></cfif>	<!--- no string passed --->
		<cfset codes="alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec romeo sierra tango uniform victor whiskey xray yankee zulu">
		<cfset var pwdLen=len(pwdStr)>
		<cfset var phonOut="">
		<cfloop from="1" to="#pwdLen#" index="item">
			<cfset char=mid(pwdStr,item,1)>
			<cfif len(phonOut)><cfset phonOut="#phonOut#-"></cfif>
			<cfif REFind("[[:upper:]]",char,1)>
				<cfset phonOut="#phonOut##UCase(GetToken(codes,asc(char)-64,' '))#">
			<cfelseif REFind("[[:lower:]]",char,1)>
				<cfset phonOut="#phonOut##GetToken(codes,asc(char)-96,' ')#">
			<cfelseif REFind("[0-9]",char,1)>
				<cfset phonOut="#phonOut##GetToken("zero one two three four five six seven eight nine",asc(char)-47,' ')#">
			<cfelse>
				<cfset phonOut="#phonOut##char#">
			</cfif>
		</cfloop>
		<cfreturn phonOut>
	</cffunction>

	<cffunction name="CheckDateStr" returntype="any" output="yes">
		<cfargument name="str" type="string" required="yes">
		<cfargument name="reversed" type="boolean" required="no" default="false">
		<cfargument name="style" type="string" required="no" default="date">
		<cfset var dateStr="">
		<cfset var rev=2*(reversed NEQ 0)>
		<cfset var yy="">
		<cfset var mm="">
		<cfset var dd="">
		<cfset var lastDay="">
		<cfset var timeStr="">
		<cfset var tmp=0>

		<cfif Find(":",str,1)>
			<cfset timeStr=ListLast(str," ")>	<!--- get time portion --->
			<cfset str=ListFirst(str," ")>		<!--- get date portion --->
		</cfif>
		<cfif len(str) gt 0>
			<cfset yy=GetToken(str,3-rev,"/-")>
			<cfset mm=val(GetToken(str,2,"/-"))>
			<cfset dd=GetToken(str,1+rev,"/-")>
			
			<cfif dd gt 1000>	<!--- yy & dd are reversed --->
				<cfset tmp=dd>
				<cfset dd=yy>
				<cfset yy=tmp>
			</cfif>
			
			<cfswitch expression="#mm#">
				<cfcase value="1,3,5,7,8,10,12" delimiters=",">
					<cfset lastDay=31>
				</cfcase>
				<cfcase value="4,6,9,11">
					<cfset lastDay=30>				
				</cfcase>
				<cfcase value="2">
					<cfset lastDay=28>				
					<cfif (yy MOD 4) EQ 0><cfset lastDay=29></cfif>
					<cfif (yy MOD 100) EQ 0 AND (yy MOD 400) NEQ 0><cfset lastDay=28>
						<cfelseif (yy MOD 400) EQ 0><cfset lastDay=29></cfif>
				</cfcase>
			</cfswitch>
			
			<cfif yy LTE 9999 AND mm GT 0 AND mm LTE 12 AND dd GTE 0 AND dd LTE lastDay>
				<cfswitch expression="#style#">
					<cfcase value="date">
						<cfset dateStr=LSDateFormat(CreateDate(yy,mm,dd),"dd/mm/yyyy")>					
					</cfcase>
					<cfcase value="mysqldate">
						<cfset dateStr=LSDateFormat(CreateDate(yy,mm,dd),"yyyy-mm-dd")>					
					</cfcase>
					<cfcase value="mysqldatetime">
						<cfset dateStr=LSDateFormat(CreateDate(yy,mm,dd),"yyyy-mm-dd")>	
						<cfset dateStr="#dateStr# #timeStr#">				
					</cfcase>
					<cfcase value="datetime">
						<cfset dateStr=CreateDate(yy,mm,dd)>
					</cfcase>
					<cfdefaultcase>
						<cfset dateStr=CreateDate(yy,mm,dd)>
					</cfdefaultcase>
				</cfswitch>
			<cfelse><cfreturn JavaCast( "null", 0 )></cfif>
		</cfif>
		<cfreturn dateStr>
	</cffunction>
	
	<cffunction name="ValidEmail" output="false" returnType="boolean">
		<cfargument name="email" type="string" required="false">
		<cfset var posAt=0>
		<cfset var nextAt=0>
		<cfset var posDot=0>
		<cfset var lastDot=0>
		<cfif NOT IsDefined("email")><cfreturn false></cfif>		<!--- no string passed --->
		<cfif Find(" ",email)><cfreturn false></cfif>				<!--- no spaces allowed --->
		<cfset posAt=Find("@",email,1)>
		<cfset nextAt=Find("@",email,posAt+1)>
		<cfif posAt LT 2 OR nextAt GT 1><cfreturn false></cfif>		<!--- too many or no @'s --->
		<cfset domainName=ListLast(email,"@")>
		<cfset posDot=find(".",domainName)>
		<cfset lastDot=find(".",Reverse(domainName))>
		<cfif posDot lt 3 OR lastDot LT 3><cfreturn false></cfif>	<!--- no dots or in wrong place --->
		<cfreturn true>
	</cffunction>
	
	<cffunction name="CleanText" output="false" returnType="boolean">
		<cfargument name="badText" type="string" required="false">	<!--- find this --->
		<cfargument name="yourStr" type="string" required="false">	<!--- in that --->
		<cfif NOT IsDefined("yourStr") OR NOT IsDefined("badText")><cfreturn true></cfif>	<!--- no strings passed so it can't be bad --->
		<cfif len(yourStr) EQ 0 OR len(badText) EQ 0><cfreturn true></cfif>					<!--- strings passed were empty so it can't be bad --->
		<cfreturn ReFind(badText,yourStr,1,false) eq 0>
	</cffunction>

	<cffunction name="extractLinks" output="yes" returntype="struct">
		<cfargument name="urlPath" required="yes" type="string" />
		<cfargument name="urlLink" required="yes" type="string" />
		<cfset var item={}>
		<cfset var result={}>
		<cfset var content="">
		<cfset var line="">
		<cfset var arrayResult={}>
		
		<cfset result.lines=[]>
		<!---<cfset result.images=[]>--->
		<cfset result.linecount=0>
		<cfset result.refcount=0>
		<cfset result.title="(not found)">
		<cfset result.urlPath=urlPath>
		<cfset result.urlLink=urlLink>

		<cfhttp method="get" url="#urlPath##urlLink#" useragent="#CGI.http_user_agent#" resolveurl="no" multipart="yes" result="content">
			<cfhttpparam type="Header" name="Accept-Encoding" value="deflate;q=0" />
			<cfhttpparam type="Header" name="TE" value="deflate;q=0" />
			<cfhttpparam type="cookie" name="CFID" value="#cookie.cfid#" />
			<cfhttpparam type="cookie" name="CFToken" value="#cookie.cftoken#" />
		</cfhttp>
		<cfif find("200",content.statuscode)>
			<cfloop list="#content.filecontent#" delimiters="#chr(10)##chr(13)#" index="line">
				<cfset item={}>
				<cfset result.linecount++>
				<cfif FindNoCase("href",line,1)>
					<cfif FindNoCase("<link",line,1)>
						<cfset item.type="link">
						<cfset item.posn1=ReFindNoCase('<link\s([^>]*)href=\"([^\"]*)\"[^>]*\/>',line,1,true)>
						<cfif ArrayLen(item.posn1.pos)>
							<cfloop from="1" to="#arraylen(item.posn1.pos)#" index="i">
								<cfif item.posn1.pos[i] gt 0>
									<cfset "item.link#i#"=mid(line,item.posn1.pos[i],item.posn1.len[i])>
								</cfif>
							</cfloop>
						</cfif>
						<!---<cfdump var="#item#" label="item" expand="yes" abort="false">--->
						
					<cfelseif FindNoCase("<a",line,1)>
						<cfset item.type="a">
						<cfset item.posn1=ReFindNoCase('<a\s[^>]*href=\"([^\"]*)\"[^>]*>(.*)<\/a>',line,1,true)>
						<cfif ArrayLen(item.posn1.pos) AND item.posn1.pos[1] gt 0>
							<cfloop from="1" to="#arraylen(item.posn1.pos)#" index="i">
								<cfif item.posn1.pos[i] gt 0>
									<cfset "item.link#i#"=mid(line,item.posn1.pos[i],item.posn1.len[i])>
								</cfif>
							</cfloop>
							<!---<cfdump var="#item#" label="item" expand="yes" abort="false">--->
						<cfelse>
							<cfset item.short=ReFindNoCase('<a\s[^>]*href=\"([^\"]*)\"([^>]*)>',line,1,true)>
							<cfloop from="1" to="#arraylen(item.short.pos)#" index="i">
								<cfif item.short.pos[i] gt 0>
									<cfset "item.link#i#"=mid(line,item.short.pos[i],item.short.len[i])>
								<cfelse>
									<cfset item.failed=htmleditformat(line)>
								</cfif>
							</cfloop>
							<!---<cfdump var="#item#" label="short" expand="yes" abort="false">--->
						</cfif>	
					</cfif>
					<cfif NOT StructIsEmpty(item)>
						<cfset ArrayAppend(result.lines,item)>
					</cfif>
					
				<cfelseif FindNoCase("<meta",line,1)>
					<cfset item.line=line>
					<cfset item.type="meta">
					<cfset item.posn1=ReFindNoCase('<meta\s([^>]*)>',line,1,true)>
					<cfif ArrayLen(item.posn1.pos)>
						<cfloop from="1" to="#arraylen(item.posn1.pos)#" index="i">
							<cfif item.posn1.pos[i] gt 0>
								<cfset "item.link#i#"=mid(line,item.posn1.pos[i],item.posn1.len[i])>
							</cfif>
						</cfloop>
					</cfif>
					<cfif NOT StructIsEmpty(item)>
						<cfset ArrayAppend(result.lines,item)>
					</cfif>

				<cfelseif FindNoCase("<script",line,1)>
					<cfset item.type="script">
					<cfset item.posn1=ReFindNoCase('src=\"([^"]*)',line,1,true)>
					<cfset item.link2="">
					<cfif ArrayLen(item.posn1.pos) gt 1>
						<cfset item.link3=mid(line,item.posn1.pos[2],item.posn1.len[2])>		
					<cfelse>
						<cfset item.link3="inline script">			
					</cfif>
					<!---<cfdump var="#item#" label="short" expand="yes" abort="false">--->
					<cfif NOT StructIsEmpty(item)>
						<cfset ArrayAppend(result.lines,item)>
					</cfif>
								
				<cfelseif FindNoCase("<form",line,1)>
					<cfset item.type="form">
					<cfset item.link2="">
					<cfset item.link3=htmleditformat(line)>
					<cfif NOT StructIsEmpty(item)>
						<cfset ArrayAppend(result.lines,item)>
					</cfif>
					
				<cfelseif FindNoCase("<title>",line,1)>
					<cfset arrayResult=ReFindNoCase('<title>([^<]*)</title>',line,1,true)>
					<cfif ArrayLen(arrayResult.pos) gt 1>
						<cfset result.title=mid(line,arrayResult.pos[2],arrayResult.len[2])>					
					</cfif>
				</cfif>

				<cfif FindNoCase("<h1",line,1)>
					<cfset result.h1Line=line>
					<cfset arrayResult=ReFindNoCase('<h1[^>]+>(.+)<\/h1>',line,1,true)>
					<cfif ArrayLen(arrayResult.pos) gt 1>
						<cfset result.h1=mid(line,arrayResult.pos[2],arrayResult.len[2])>					
					</cfif>
				</cfif>
				<cfif FindNoCase("<img",line,1)>
					<cfset item={}>
					<cfset item.posn1=ReFindNoCase('alt=[\"''](.*)[\"'']',line,1,true)>
					<cfif ArrayLen(item.posn1.pos) gt 1>
						<cfset item.type="image">
						<cfset item.AltText=mid(line,item.posn1.pos[2],item.posn1.len[2])>
						<cfset ArrayAppend(result.lines,item)>
					</cfif>
				</cfif>
			</cfloop>
			<cfset result.refcount=ArrayLen(result.lines)>
		</cfif>
		<cfreturn result>
	</cffunction>

	<cffunction name="showLinks" access="public" output="yes" returntype="void" hint="">
		<cfargument name="args" type="struct" required="yes">
		<cfset var lineNo=0>
		<cfoutput>
			<table border="1" width="98%" class="results">
				<tr class="titles">
					<th>&nbsp;</th>
					<th width="5%">Type</th>
					<th width="45%">URL</th>
					<th width="50%">Parameters</th>
				</tr>
				<tr class="header">
					<td>&nbsp;</td>
					<td>Path</td>
					<td>#args.urlPath#</td>
					<td>LINES: #args.lineCount# LINKS: #args.refCount#</td>
				</tr>
				<tr class="header">
					<td>&nbsp;</td>
					<td>Title</td>
					<td>#args.title#</td>
					<td><a href="#args.urlPath##args.urlLink#">#args.urlLink#</a></td>
				</tr>
				<tr class="header">
					<td>&nbsp;</td>
					<td>H1</td>
					<td><cfif StructKeyExists(args,"h1")>#args.h1#<cfelse>NO H1</cfif></td>
					<td></td>
				</tr>
				<cfloop array="#args.lines#" index="item">
					<cfset lineNo++>
					<cfif StructKeyExists(item,"type")>
						<tr class="#item.type#">
							<td>#lineNo#</td>
							<td>#item.type#</td>
							<cfif item.type is "a">
								<cfif StructKeyExists(item,"failed")>
									<td colspan="2">#item.failed#</td>
								<cfelseif StructKeyExists(item,"link3")>
									<cfif FindNoCase("img",item.link3)>
										<cfset link3=ReFindNoCase('src=\"([^\"]*)\"',item.link3,1,true)>
										<cfif link3.pos[1] gt 0>
											<cfset newlink3=mid(item.link3,link3.pos[1],link3.len[1])>
										</cfif>
									<cfelse><cfset newlink3=item.link3></cfif>
									<!---<td><a href="#script_name#?urlPath=#args.urlPath#&amp;urlLink=#ListLast(item.link2,"/")#">#item.link2#</a></td>--->
									<td><a href="#script_name#?urlPath=#args.urlPath#&amp;urlLink=#ListRest(ListRest(item.link2,"/"),"/")#">#item.link2#</a></td>
									<td><a href="#item.link2#">#newlink3#</a></td>
								<cfelse>
									<cfset newlink3="">
									<!---<cfdump var="#item#" label="item" expand="no" abort="false">--->
								</cfif>
							<cfelseif item.type is "meta">
								<td><cfif StructKeyExists(item,"link2")>#item.link2#</cfif></td>
								<td><cfif StructKeyExists(item,"link1")>#item.link1#</cfif></td>
							<cfelseif item.type is "image">
								<td><cfif StructKeyExists(item,"altText")>alt= #item.altText#</cfif></td>
								<td></td>
							<cfelse>
								<td><cfif StructKeyExists(item,"link3")>#item.link3#</cfif></td>
								<td><cfif StructKeyExists(item,"link2")>#item.link2#</cfif></td>
							</cfif>
						</tr>
					</cfif>
				</cfloop>
			</table>
		</cfoutput>
	</cffunction>

	<cfset this.salesSections = ["product", "publication", "paystation", "deal", "supplier"]>
	<cfset this.requiredKeys  = ["product", "publication", "paystation", "deal", "supplier", "payment", "discount", "account"]>

	<cffunction name="GetSalesSections" access="public" returntype="array">
		<cfreturn this.salesSections>
	</cffunction>
	
	<cffunction name="DisableEPOSLaunchTill" access="public" returntype="void">
		<cfset var loc = {}>
		
		<cfquery name="loc.update" datasource="#GetDatasource()#">
			UPDATE tblEmployee
			SET empEPOSLaunchTill = 'No'
			WHERE empID = #val(session.user.id)#
		</cfquery>
		
	</cffunction>
	
	<cffunction name="EnableEPOSLaunchTill" access="public" returntype="void">
		<cfset var loc = {}>
		
		<cfquery name="loc.update" datasource="#GetDatasource()#">
			UPDATE tblEmployee
			SET empEPOSLaunchTill = 'Yes'
			WHERE empID = #val(session.user.id)#
		</cfquery>
		
	</cffunction>
	
	<cffunction name="CalculateAccountTotals" access="public" returntype="void">
		<cfset var loc = {}>
		<cfset loc.basket = session.epos_frame.basket>
		<cfset loc.requiredKeys = ["product", "publication", "paystation"]>
		
		<cftry>
			<cflock scope="session" timeout="10">
				<cfset session.epos_frame.basket.account.cash = 0>
				<cfset session.epos_frame.basket.account.credit = 0>
				<cfloop array="#loc.requiredKeys#" index="loc.section">
					<cfset loc.basketSection=StructFind(loc.basket,loc.section)>
					<cfloop collection="#loc.basketSection#" item="loc.key">
						<cfset loc.item = StructFind(loc.basketSection, loc.key)>
						<cfset loc.lineTotal = val(loc.item.qty * loc.item.price) + loc.item.grossSaving>
						<cfif loc.item.cashOnly>
							<cfset session.epos_frame.basket.account.cash += loc.lineTotal>
						<cfelse>
							<cfset session.epos_frame.basket.account.credit += loc.lineTotal>
						</cfif>
					</cfloop>
				</cfloop>
				<cfset loc.payments = StructFind(loc.basket, "payment")>
				<cfloop collection="#loc.payments#" item="loc.key">
					<cfset loc.item = StructFind(loc.payments, loc.key)>
					<cfif Find("CASH", loc.item.title, "1")>
						<cfset session.epos_frame.basket.account.cash += loc.item.cash>
					<cfelse>
						<cfset session.epos_frame.basket.account.credit += loc.item.credit>
					</cfif>
				</cfloop>
			</cflock>
			
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="" expand="yes" format="html" 
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>
	

	<cffunction name="LoadProductGroups" access="public" returntype="array">
		<cfset var loc = {}>
		
		<cfquery name="loc.groups" datasource="#GetDatasource()#">
			SELECT *
			FROM tblProductGroups
			ORDER BY pgTitle ASC
		</cfquery>
		
		<cfreturn QueryToArrayOfStruct(loc.groups)>
	</cffunction>
	
	<cffunction name="LoadProductCategories" access="public" returntype="array">
		<cfset var loc = {}>
		
		<cfquery name="loc.cats" datasource="#GetDatasource()#">
			SELECT *
			FROM tblProductCats
			ORDER BY pcatTitle ASC
		</cfquery>
		
		<cfreturn QueryToArrayOfStruct(loc.cats)>
	</cffunction>
	
	<cffunction name="LoadDayReport" access="public" returntype="struct">
		<cfargument name="useDate" type="string" required="no" hint="Format as YYYY-MM-DD">
		<cfset var loc = {}>
		<cfset loc.dateQry = "">
		<cfset loc.result = { sales = [], receipts = [] }>
		
		<cfif StructKeyExists(arguments, "useDate")>
			<cfset loc.udArray = ListToArray(arguments.useDate, "-")>
			<cfswitch expression="#ArrayLen(loc.udArray)#">
				<cfcase value="1"><cfset loc.dateQry = "AND YEAR(eiTimestamp) = #val(arguments.useDate)#"></cfcase>
				<cfcase value="2"><cfset loc.dateQry = "AND YEAR(eiTimestamp) = #val( Year(arguments.useDate) )# AND MONTH(eiTimestamp) = #val( Month(arguments.useDate) )#"></cfcase>
				<cfcase value="3"><cfset loc.dateQry = "AND YEAR(eiTimestamp) = #val( Year(arguments.useDate) )# AND MONTH(eiTimestamp) = #val( Month(arguments.useDate) )# AND DAY(eiTimestamp) = #val( Day(arguments.useDate) )#"></cfcase>
			</cfswitch>
		</cfif>
		
		<cfset loc.result.qry = loc.dateQry>
		
		<cfquery name="loc.catItems" datasource="#GetDatasource()#" result="loc.catItems_result">
			SELECT pcatTitle, SUM(eiNet) AS netSum, COUNT(eiID) AS itemCount
			FROM tblEPOS_Items
			INNER JOIN tblProducts ON eiProdID = prodID
			INNER JOIN tblProductCats ON pcatID = prodCatID
			INNER JOIN tblProductGroups ON pcatGroup = pgID
			WHERE eiType = 'Sale'
			AND eiPubID = 1
			#PreserveSingleQuotes(loc.dateQry)#
			GROUP BY pcatID
		</cfquery>
		
		<cfquery name="loc.pubItems" datasource="#GetDatasource()#" result="loc.pubItems_result">
			SELECT "News & Mags" AS pcatTitle, SUM(eiNet) AS netSum, COUNT(eiID) AS itemCount
			FROM tblEPOS_Items
			INNER JOIN tblPublication ON eiPubID = pubID
			WHERE eiType = 'Sale'
			AND eiProdID = 1
			#PreserveSingleQuotes(loc.dateQry)#
		</cfquery>
		
		<cfset loc.result.sales = QueryToArrayOfStruct(loc.catItems)>
		<cfset loc.result.sales.addAll( QueryToArrayOfStruct(loc.pubItems) )><!---Merge publication array to sales array--->
		
		<cfquery name="loc.payments" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_Account
			WHERE eaTillPayment = 'Yes'
			ORDER BY eaTitle ASC
		</cfquery>
		
		<cfloop query="loc.payments">
			<cfquery name="loc.sumPayment" datasource="#GetDatasource()#">
				SELECT SUM(eiNet + eiCashback) AS netSum, SUM(eiCashback) AS cashback, COUNT(eiID) AS netCount
					<!---( SELECT COUNT(eiID) FROM tblEPOS_Items WHERE eiNomID = #val(eaID)# AND eiType = 'Payment' ) AS netCount--->
				FROM tblEPOS_Items
				WHERE eiNomID = #val(eaID)#
				AND eiType = 'Payment'
				#PreserveSingleQuotes(loc.dateQry)#
			</cfquery>
			
			<cfif Len(loc.sumPayment.netSum)>
				<cfset ArrayAppend(loc.result.receipts, {
					account = eaTitle,
					netSum = loc.sumPayment.netSum,
					cashback = loc.sumPayment.cashback,
					count = loc.sumPayment.netCount
				})>
			</cfif>
		</cfloop>
		
		<cfreturn loc.result>
	</cffunction>
	
	<cffunction name="LoadRandomProducts" access="public" returntype="array">
		<cfargument name="count" type="numeric" required="yes">
		<cfset var loc = {}>
		
		<cfquery name="loc.prods" datasource="#GetDatasource()#">
			SELECT tblProducts.*, siOurPrice
			FROM tblProducts
			LEFT JOIN tblStockItem ON prodID = siProduct
			AND tblStockItem.siID = (
				SELECT MAX( siID )
				FROM tblStockItem
				WHERE prodID = siProduct )
			ORDER BY RAND()
			LIMIT #val(count)#
		</cfquery>
		
		<cfreturn QueryToArrayOfStruct(loc.prods)>
	</cffunction>
	
	<cffunction name="CheckProduct" access="public" returntype="struct">
		<cfargument name="prodID" type="numeric" required="yes">
		<cfset var loc = {}>

		<cfquery name="loc.product" datasource="#GetDatasource()#">
			SELECT *
			FROM tblProducts
			WHERE prodID = #val(args.ID)#
		</cfquery>
		
		<cfreturn QueryToStruct(loc.product)>
	</cffunction>
	
	<cffunction name="SendBarcode" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cfif StructKeyExists(args.form, "barcode")>
			<cfquery name="loc.barcode" datasource="#GetDatasource()#">
				SELECT *
				FROM tblBarcodes
				WHERE barCode LIKE '%#args.form.barcode#%'
				LIMIT 1;
			</cfquery>

			<cfif loc.barcode.recordcount is 1>
				<cfset loc.barcodeRec = QueryToStruct(loc.barcode)>
				<cfset loc.result.data = CheckProduct(loc.barcodeRec.barProdID)>
				
				<cfif StructKeyExists(args.form, "supp") AND val(args.form.supp) is loc.result.data.prodSuppID>
					<cfset loc.result.mode = 2>
				<cfelse>
					<cfset loc.result.error = "">
					<cfset loc.result.mode = 3>
				</cfif>
			<cfelse>
				<cfset loc.result.error = "Product not found: #args.form.barcode#">
				<cfset loc.result.mode = 1>
			</cfif>
		<cfelse>
			<cfquery name="loc.product" datasource="#GetDatasource()#">
				SELECT *
				FROM tblProducts, tblAccount
				WHERE prodID = #val(args.form.id)#
				AND prodSuppID = accID
				LIMIT 1;
			</cfquery>
			
			<cfif loc.product.recordcount is 1>
				<cfif val(args.form.supp) is loc.product.prodSuppID>
					<cfset loc.result.data = CheckProduct(loc.product.prodID)>
					<cfset loc.result.mode = 2>
				<cfelse>
					<cfset loc.result.error = "#loc.product.prodTitle# is a #loc.product.accName# product.">
					<cfset loc.result.mode = 3>
				</cfif>
			<cfelse>
				<cfset loc.result.error = "Product not found: #val(args.form.id)#">
				<cfset loc.result.mode = 1>
			</cfif>
		</cfif>

		<cfreturn loc.result>
	</cffunction>
	
	<cffunction name="EnableEPOSTutorial" access="public" returntype="void">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.disable" datasource="#GetDatasource()#">
			UPDATE tblEmployee
			SET empEPOSTutorial = 0
			WHERE empID = #val(session.user.id)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="DisableEPOSTutorial" access="public" returntype="void">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.disable" datasource="#GetDatasource()#">
			UPDATE tblEmployee
			SET empEPOSTutorial = 1
			WHERE empID = #val(session.user.id)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="AddIntroSlide" access="public" returntype="numeric">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.add" datasource="#GetDatasource()#" result="loc.add_result">
			INSERT INTO tblEPOS_Intro (
				eiText,
				eiNext,
				eiBack
			) VALUES (
				'#args.ia_text#',
				'#args.ia_next#',
				'#args.ia_back#'
			)
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.add_result.generatedkey>
	</cffunction>
	
	<cffunction name="DeleteIntroSlide" access="public" returntype="void">
		<cfargument name="args" type="numeric" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.del" datasource="#GetDatasource()#">
			DELETE FROM tblEPOS_Intro
			WHERE eiID = #val(args)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="UpdateIntroOrder" access="public" returntype="void">
		<cfargument name="args" type="array" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfloop array="#args#" index="loc.item">
			<cfquery name="loc.update" datasource="#GetDatasource()#">
				UPDATE tblEPOS_Intro
				SET eiOrder = #val(loc.item.index)#
				WHERE eiID = #val(loc.item.id)#
			</cfquery>
		</cfloop>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="UpdateIntroTooltipText" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.update" datasource="#GetDatasource()#">
			UPDATE tblEPOS_Intro
			SET eiText = '#args.text#',
				eiNext = '#args.next#',
				eiBack = '#args.back#'
			WHERE eiID = #val(args.id)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="UpdateIntroTooltip" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfif args.scale_w gt 0 AND args.scale_h gt 0>
			<cfquery name="loc.checkScale" datasource="#GetDatasource()#">
				SELECT eisID
				FROM tblEPOS_IntroScale
				WHERE eisParent = #val(args.id)#
				AND eisScreenWidth = #val(args.scale_w)#
				AND eisScreenHeight = #val(args.scale_h)#
			</cfquery>
			
			<cfif loc.checkScale.recordcount gt 0>
				<cfquery name="loc.updateScale" datasource="#GetDatasource()#">
					UPDATE tblEPOS_IntroScale
					SET eisScreenWidth = #val(args.scale_w)#,
						eisScreenHeight = #val(args.scale_h)#,
						eisNewT = #val(args.top)#,
						eisNewL = #val(args.left)#
					WHERE eisParent = #val(args.id)#
					AND eisScreenWidth = #val(args.scale_w)#
					AND eisScreenHeight = #val(args.scale_h)#
				</cfquery>
			<cfelse>
				<cfquery name="loc.newScale" datasource="#GetDatasource()#">
					INSERT INTO tblEPOS_IntroScale (
						eisParent,
						eisScreenWidth,
						eisScreenHeight,
						eisNewT,
						eisNewL
					) VALUES (
						#val(args.id)#,
						#val(args.scale_w)#,
						#val(args.scale_h)#,
						#val(args.top)#,
						#val(args.left)#
					)
				</cfquery>
			</cfif>
		<cfelse>
			<cfquery name="loc.update" datasource="#GetDatasource()#" result="loc.update_result">
				UPDATE tblEPOS_Intro
				SET eiPositionX = #val(args.left)#,
					eiPositionY = #val(args.top)#
				WHERE eiID = #val(args.id)#
			</cfquery>
		</cfif>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="UpdateIntroBox" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfif args.scale_w gt 0 AND args.scale_h gt 0>
			<cfquery name="loc.checkScale" datasource="#GetDatasource()#">
				SELECT eisID
				FROM tblEPOS_IntroScale
				WHERE eisParent = #val(args.id)#
				AND eisScreenWidth = #val(args.scale_w)#
				AND eisScreenHeight = #val(args.scale_h)#
			</cfquery>
			
			<cfif loc.checkScale.recordcount gt 0>
				<cfquery name="loc.updateScale" datasource="#GetDatasource()#">
					UPDATE tblEPOS_IntroScale
					SET eisScreenWidth = #val(args.scale_w)#,
						eisScreenHeight = #val(args.scale_h)#,
						eisNewBoxT = #val(args.top)#,
						eisNewBoxL = #val(args.left)#,
						eisNewW = #val(args.width)#,
						eisNewH = #val(args.height)#
					WHERE eisParent = #val(args.id)#
					AND eisScreenWidth = #val(args.scale_w)#
					AND eisScreenHeight = #val(args.scale_h)#
				</cfquery>
			<cfelse>
				<cfquery name="loc.newScale" datasource="#GetDatasource()#">
					INSERT INTO tblEPOS_IntroScale (
						eisParent,
						eisScreenWidth,
						eisScreenHeight,
						eisNewBoxT,
						eisNewBoxL,
						eisNewW,
						eisNewH
					) VALUES (
						#val(args.id)#,
						#val(args.scale_w)#,
						#val(args.scale_h)#,
						#val(args.top)#,
						#val(args.left)#,
						#val(args.width)#,
						#val(args.height)#
					)
				</cfquery>
			</cfif>
		<cfelse>
			<cfquery name="loc.update" datasource="#GetDatasource()#">
				UPDATE tblEPOS_Intro
				SET eiBoxPosX = #val(args.left)#,
					eiBoxPosY = #val(args.top)#,
					eiBoxSizeX = #val(args.width)#,
					eiBoxSizeY = #val(args.height)#
				WHERE eiID = #val(args.id)#
			</cfquery>
		</cfif>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="LoadIntroSlides" access="public" returntype="array">
		<cfset var loc = {}>
		<cfset loc.result = []>
		
		<cftry>
		
		<cfquery name="loc.slides" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_Intro
			ORDER BY eiOrder ASC
		</cfquery>
		
		<cfloop query="loc.slides">
			<cfset loc.item = {}>
			<cfset loc.item.id = eiID>
			<cfset loc.item.text = eiText>
			<cfset loc.item.next = eiNext>
			<cfset loc.item.back = eiBack>
			<cfset loc.item.position = [eiPositionX, eiPositionY]>
			<cfset loc.item.box = [eiBoxPosX, eiBoxPosY, eiBoxSizeX, eiBoxSizeY]>
			<cfset loc.item.scale = []>
			
			<cfquery name="loc.introScales" datasource="#GetDatasource()#">
				SELECT *
				FROM tblEPOS_IntroScale
				WHERE eisParent = #val(loc.item.id)#
				ORDER BY eisScreenWidth DESC
			</cfquery>
			
			<cfloop query="loc.introScales">
				<cfset loc.s = {}>
				<cfset loc.s.screen_width = eisScreenWidth>
				<cfset loc.s.screen_height = eisScreenHeight>
				<cfset loc.s.new_w = eisNewW>
				<cfset loc.s.new_h = eisNewH>
				<cfset loc.s.new_t = eisNewT>
				<cfset loc.s.new_l = eisNewL>
				<cfset loc.s.new_box_t = eisNewBoxT>
				<cfset loc.s.new_box_l = eisNewBoxL>
				<cfset ArrayAppend(loc.item.scale, loc.s)>
			</cfloop>
			
			<cfset ArrayAppend(loc.result, loc.item)>
		</cfloop>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.result>
	</cffunction>
	
	<cffunction name="AddAlert" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.add" datasource="#GetDatasource()#">
			INSERT INTO tblEPOS_Alerts (
				altTimestamp,
				altType,
				altRecipient,
				altRecur,
				altContent
			) VALUES (
				<cfif StructKeyExists(args, "r_date")>
					'#LSDateFormat(args.r_date, "yyyy-mm-dd")# #LSTimeFormat(args.r_time, "HH:mm")#:00',
				<cfelse>
					'#LSDateFormat(Now(), "yyyy-mm-dd")# #LSTimeFormat(args.r_time, "HH:mm")#:00',
				</cfif>
				'Global',
				0,
				<cfif StructKeyExists(args, "r_recur")>
					'Yes',
				<cfelse>
					'No',
				</cfif>
				'#args.r_desc#'
			)
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	<cffunction name="AddBookmark" access="public" returntype="struct">
		<cfargument name="text" type="string" required="yes">
		<cfargument name="time" type="string" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.new" datasource="#GetDatasource()#" result="loc.new_result">
			INSERT INTO tblEPOS_Bookmarks (
				ebTitle,
				ebTime
			) VALUES (
				'#text#',
				'#time#:00'
			)
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.new_result>
	</cffunction>
	
	<cffunction name="DeleteBookmark" access="public" returntype="void">
		<cfargument name="bookID" type="numeric" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.del" datasource="#GetDatasource()#">
			DELETE FROM tblEPOS_Bookmarks
			WHERE ebID = #val(bookID)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="UpdateBookmarkTime" access="public" returntype="void">
		<cfargument name="bookID" type="numeric" required="yes">
		<cfargument name="newTime" type="string" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.update" datasource="#GetDatasource()#">
			UPDATE tblEPOS_Bookmarks
			SET ebTime = '#newTime#:00'
			WHERE ebID = #val(bookID)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="UpdateBookmarkTitle" access="public" returntype="void">
		<cfargument name="bookID" type="numeric" required="yes">
		<cfargument name="newText" type="string" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.update" datasource="#GetDatasource()#">
			UPDATE tblEPOS_Bookmarks
			SET ebTitle = '#newText#'
			WHERE ebID = #val(bookID)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="LoadBookmarks" access="public" returntype="array">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.bookmarks" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_Bookmarks
			ORDER BY ebTime ASC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (loc.bookmarks.recordcount gt 0) ? QueryToArrayOfStruct(loc.bookmarks) : []>
	</cffunction>
	
	<cffunction name="FlagAlerts" access="public" returntype="void">
		<cfargument name="alerts" type="array" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfloop array="#alerts#" index="loc.item">
			<cfquery name="loc.flag" datasource="#GetDatasource()#">
				UPDATE tblEPOS_Alerts
				SET altFlag = 'Checked',
					altLastChecked = #Now()#
				WHERE altID = #val(loc.item)#
			</cfquery>
		</cfloop>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="UpdateDeal" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.update" datasource="#GetDatasource()#">
			UPDATE tblEPOS_Deals
			SET edTitle = '#args.ndf_title#',
				edStarts = '#LSDateFormat(args.ndf_start, "yyyy-mm-dd")#',
				edEnds = '#LSDateFormat(args.ndf_end, "yyyy-mm-dd")#',
				edType = '#args.ndf_type#',
				edAmount = #val(args.ndf_amount)#,
				edQty = #val(args.ndf_qty)#
			WHERE edID = #val(args.ndf_id)#
		</cfquery>
		
		<cfquery name="loc.updateitems" datasource="#GetDatasource()#">
			UPDATE tblEPOS_DealItems
			SET ediProduct = #val(args.ndf_item_id)#
			WHERE ediParent = #val(args.ndf_id)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="LoadDealItems" access="public" returntype="array">
		<cfargument name="dealID" type="numeric" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = []>
		
		<cftry>
		
		<cfquery name="loc.items" datasource="#GetDatasource()#">
			SELECT tblEPOS_DealItems.*, tblProducts.prodTitle
			FROM tblEPOS_DealItems, tblProducts
			WHERE ediParent = #val(dealID)#
			AND ediProduct = prodID
		</cfquery>
		
		<cfloop query="loc.items">
			<cfset loc.item = {}>
			<cfset loc.item.id = ediProduct>
			<cfset loc.item.title = prodTitle>
			<cfset loc.item.cashOnly = 0>
			<cfset ArrayAppend(loc.result, loc.item)>
		</cfloop>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.result>
	</cffunction>
	
	<cffunction name="UpdateAutoLogout" access="public" returntype="void">
		<cfargument name="autologout_ms" type="numeric" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.update" datasource="#GetDatasource()#">
			UPDATE tblEmployee
			SET empAutoLogout = #val(autologout_ms)#
			WHERE empID = #val(session.user.id)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="LoadOldAlerts" access="public" returntype="array">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.alerts" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_Alerts
			WHERE ( altRecipient = 0 OR altRecipient = #val(session.user.id)# )
			AND altFlag = 'Checked'
			ORDER BY altTimestamp DESC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (loc.alerts.recordcount gt 0) ? QueryToArrayOfStruct(loc.alerts) : []>
	</cffunction>
	
	<cffunction name="LoadAlerts" access="public" returntype="array">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.alerts" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_Alerts
			WHERE ( altRecipient = 0 OR altRecipient = #val(session.user.id)# )
			AND ( altFlag = 'Unchecked' OR altRecur = 'Yes' )
			AND ( DAY(altLastChecked) != #LSDateFormat(Now(), "dd")# OR altLastChecked IS NULL )
			ORDER BY altTimestamp DESC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (loc.alerts.recordcount gt 0) ? QueryToArrayOfStruct(loc.alerts) : []>
	</cffunction>
	<cffunction name="UpdateBackground" access="public" returntype="void">
		<cfargument name="newBG" type="string" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.update" datasource="#GetDatasource()#">
			UPDATE tblEmployee
			SET empBackground = '#newBG#'
			WHERE empID = #val(session.user.id)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	<cffunction name="LoadDealByID" access="public" returntype="struct">
		<cfargument name="dealID" type="numeric" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.deal" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_Deals
			WHERE edID = #val(dealID)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToStruct(loc.deal)>
	</cffunction>
	<cffunction name="AddDeal" access="public" returntype="string">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.newDealHeader" datasource="#GetDatasource()#" result="loc.newDealHeader_result">
			INSERT INTO tblEPOS_Deals (
				edTitle,
				edStarts,
				edEnds,
				edType,
				edAmount,
				edQty,
				edStatus
			) VALUES (
				'#args.ndf_title#',
				<cfqueryparam value="#LSDateFormat(args.ndf_start, 'yyyy-mm-dd')#" cfsqltype="cf_sql_timestamp">,
				<cfqueryparam value="#LSDateFormat(args.ndf_end, 'yyyy-mm-dd')#" cfsqltype="cf_sql_timestamp">,
				'#args.ndf_type#',
				#val(args.ndf_amount)#,
				#val(args.ndf_qty)#,
				'Active'
			)
		</cfquery>
		
		<cfquery name="loc.newDealItem" datasource="#GetDatasource()#">
			INSERT INTO tblEPOS_DealItems (
				ediParent,
				ediProduct,
				ediMinQty,
				ediMaxQty
			) VALUES (
				#val(loc.newDealHeader_result.generatedkey)#,
				#val(args.dpf_prodid)#,
				#val(args.dpf_minqty)#,
				#val(args.dpf_maxqty)#
			)
		</cfquery>

		<cfcatch type="any">
			<cfreturn "There was an error">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn "Deal Added Successfully">
	</cffunction>
	<cffunction name="SetEmpCats" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfif !ArrayIsEmpty(args.items)>
			<cfquery name="loc.delOld" datasource="#GetDatasource()#">
				DELETE FROM tblEPOS_EmpCats
				WHERE eecEmployee = #val(args.empID)#
			</cfquery>
			
			<cfquery name="loc.insert" datasource="#GetDatasource()#">
				INSERT INTO tblEPOS_EmpCats (
					eecEmployee,
					eecCategory
				) VALUES
				<cfset loc.counter = 0>
				<cfloop array="#args.items#" index="loc.item">
					<cfset loc.counter++>
					(
						#val(args.empID)#,
						#val(loc.item)#
					)<cfif loc.counter neq ArrayLen(args.items)>,</cfif>
				</cfloop>
			</cfquery>
		</cfif>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	<cffunction name="IsCatAssigned" access="public" returntype="boolean">
		<cfargument name="catID" type="numeric" required="yes">
		<cfargument name="empID" type="numeric" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.check" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_EmpCats
			WHERE eecEmployee = #val(empID)#
			AND eecCategory = #val(catID)#
			LIMIT 1;
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (loc.check.recordcount is 0) ? false : true>
	</cffunction>
	<cffunction name="LoadBasketSteven" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<!---Go--->
		

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc>
	</cffunction>
	<cffunction name="UpdateEmpCatOrders" access="public" returntype="void">
		<cfargument name="items" type="array" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfloop array="#items#" index="loc.item">
			<cfquery name="loc.update" datasource="#GetDatasource()#">
				UPDATE tblEPOS_EmpCats
				SET eecOrder = #val(loc.item.order)#
				WHERE eecEmployee = #val(session.user.id)#
				AND eecCategory = #val(loc.item.id)#
			</cfquery>
		</cfloop>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	<cffunction name="DeleteCategory" access="public" returntype="void">
		<cfargument name="catID" type="numeric" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.del" datasource="#GetDatasource()#">
			DELETE FROM tblEPOS_Cats
			WHERE epcID = #val(catID)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	<cffunction name="UpdateCategory" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.update" datasource="#GetDatasource()#">
			UPDATE tblEPOS_Cats
			SET epcTitle = '#args.catTitle#'
			WHERE epcID = #val(args.catID)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	<cffunction name="AddCategory" access="public" returntype="void">
		<cfargument name="catTitle" type="string" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.checkexists" datasource="#GetDatasource()#">
			SELECT epcID
			FROM tblEPOS_Cats
			WHERE epcTitle = '#catTitle#'
		</cfquery>
		
		<!---<cfif loc.checkexists.recordcount is 0>--->
			<cfquery name="loc.newcat" datasource="#GetDatasource()#" result="loc.newcat_result">
				INSERT INTO tblEPOS_Cats (
					epcOrder,
					epcTitle,
					epcPMAllow
				) VALUES (
					0,
					'#catTitle#',
					'Yes'
				)
			</cfquery>
			
			<cfquery name="loc.updateempcats" datasource="#GetDatasource()#">
				INSERT INTO tblEPOS_EmpCats (
					eecEmployee,
					eecCategory
				) VALUES (
					#val(session.user.id)#,
					#val(loc.newcat_result.generatedkey)#
				)
			</cfquery>
		<!---</cfif>--->

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	<cffunction name="LoadProductsInCat" access="public" returntype="array">
		<cfargument name="catID" type="numeric" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.prods" datasource="#GetDatasource()#">
			SELECT *
			FROM tblProducts
			WHERE prodEposCatID = #val(catID)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (loc.prods.recordcount gt 0) ? QueryToArrayOfStruct(loc.prods) : []>
	</cffunction>
	<cffunction name="UpdateProduct" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.update" datasource="#GetDatasource()#">
			UPDATE tblProducts
			SET prodTitle = '#args.epf_title#',
				prodRecordTitle = '#args.epf_title#',
				<cfif StructKeyExists(args, "epf_cashonly")>prodCashOnly = 1,</cfif>
				<cfif StructKeyExists(args, "epf_prodcat")>prodCatID = #val(args.epf_prodcat)#,</cfif>
				prodEposCatID = #val(args.epf_cat)#
			WHERE prodID = #val(args.epf_id)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	<cffunction name="DeleteProductByID" access="public" returntype="void">
		<cfargument name="productID" type="numeric" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.delProd" datasource="#GetDatasource()#">
			DELETE FROM tblProducts
			WHERE prodID = #val(productID)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	<cffunction name="LoadProductsByKeyword" access="public" returntype="array">
		<cfargument name="keyword" type="string" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.prods" datasource="#GetDatasource()#">
			SELECT *
			FROM tblProducts
			WHERE prodTitle LIKE '%#keyword#%'
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (loc.prods.recordcount gt 0) ? QueryToArrayOfStruct(loc.prods) : []>
	</cffunction>
	<cffunction name="LoadLotteryPrizes" access="public" returntype="numeric">
		<cfset var loc = {}>
		<cfset loc.today_start = '#LSDateFormat(Now(), "yyyy-mm-dd")# 00:00:00'>
		<cfset loc.today_end = '#LSDateFormat(Now(), "yyyy-mm-dd")# 23:59:59'>
		
		<cftry>
		
		<cfquery name="loc.prizes" datasource="#GetDatasource()#">
			SELECT SUM(eiNet) AS PrizesTotal
			FROM tblEPOS_Items
			WHERE eiProdID = 28622
			AND eiType = 'Sale'
			AND eiNomID = 2
			AND eiTimestamp >= '#loc.today_start#'
			AND eiTimestamp <= '#loc.today_end#'
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (len(loc.prizes.PrizesTotal)) ? loc.prizes.PrizesTotal : 0>
	</cffunction>
	<cffunction name="LoadScratchcardPrizes" access="public" returntype="numeric">
		<cfset var loc = {}>
		<cfset loc.today_start = '#LSDateFormat(Now(), "yyyy-mm-dd")# 00:00:00'>
		<cfset loc.today_end = '#LSDateFormat(Now(), "yyyy-mm-dd")# 23:59:59'>
		
		<cftry>
		
		<cfquery name="loc.prizes" datasource="#GetDatasource()#">
			SELECT SUM(eiNet) AS PrizesTotal
			FROM tblEPOS_Items
			WHERE eiProdID = 28642
			AND eiType = 'Sale'
			AND eiNomID = 2
			AND eiTimestamp >= '#loc.today_start#'
			AND eiTimestamp <= '#loc.today_end#'
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (len(loc.prizes.PrizesTotal)) ? loc.prizes.PrizesTotal : 0>
	</cffunction>
	<cffunction name="LoadLotteryDrawsForToday" access="public" returntype="numeric">
		<cfset var loc = {}>
		<cfset loc.today_start = '#LSDateFormat(Now(), "yyyy-mm-dd")# 00:00:00'>
		<cfset loc.today_end = '#LSDateFormat(Now(), "yyyy-mm-dd")# 23:59:59'>
		<cfset loc.lottoIDArr = "28392, 28402, 28412, 28422">
		
		<cftry>
		
		<cfquery name="loc.lotto" datasource="#GetDatasource()#">
			SELECT SUM(eiNet) AS lottoDraws
			FROM tblEPOS_Items
			WHERE eiType = 'Sale'
			AND eiNomID = 2
			AND eiTimestamp >= '#loc.today_start#'
			AND eiTimestamp <= '#loc.today_end#'
			AND eiProdID IN (#loc.lottoIDArr#)
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (len(loc.lotto.lottoDraws)) ? loc.lotto.lottoDraws : 0>
	</cffunction>
	<cffunction name="LoadZCashForToday" access="public" returntype="numeric">
		<cfset var loc = {}>
		<cfset loc.today_start = '#LSDateFormat(Now(), "yyyy-mm-dd")# 00:00:00'>
		<cfset loc.today_end = '#LSDateFormat(Now(), "yyyy-mm-dd")# 23:59:59'>
		
		<cftry>
		
		<cfquery name="loc.cash" datasource="#GetDatasource()#">
			SELECT SUM(eiNet) AS zCash
			FROM tblEPOS_Items
			WHERE eiType = 'CASHINDW'
			AND eiTimestamp >= '#loc.today_start#'
			AND eiTimestamp <= '#loc.today_end#'
		</cfquery>
		
		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (len(loc.cash.zCash)) ? loc.cash.zCash : 0>
	</cffunction>
	<cffunction name="LoadApps" access="public" returntype="array">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.apps" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_Apps
			WHERE appStatus = 'Active'
			ORDER BY appOrder ASC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToArrayOfStruct(loc.apps)>
	</cffunction>
	<cffunction name="LoadNewsStoriesIntoSession" access="public" returntype="struct">
		<cfset var loc = {}>
		<cfset loc.bbcNewsResult = []>
		<cfset loc.grocerResult = []>
		<cfset loc.bbcrssfeed = "http://feeds.bbci.co.uk/news/world/rss.xml">
		<cfset loc.grocerfeed = "http://www.thegrocer.co.uk/XmlServers/navsectionRSS.aspx?navsectioncode=33">
		
		<cftry>
		
		<cffeed action="read" source="#loc.bbcrssfeed#" query="loc.newsQuery">
		<cffeed action="read" source="#loc.grocerfeed#" query="loc.grocerQuery">
		
		<cfloop query="loc.newsQuery">
			<cfset ArrayAppend(loc.bbcNewsResult, {
				title = title,
				content = content
			})>
		</cfloop>
		
		<cfloop query="loc.grocerQuery">
			<cfset ArrayAppend(loc.grocerResult, {
				title = title,
				content = content
			})>
		</cfloop>
		
		<cfset session.news_stories = loc.bbcNewsResult>
		<cfset session.grocer_stories = loc.grocerResult>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc>
	</cffunction>
	<cffunction name="LoadPayments" access="public" returntype="array">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.payments" datasource="#args.datasource#">
			SELECT *
			FROM tblEPOS_Account
			WHERE eaTillPayment = 'Yes'
			ORDER BY eaOrder ASC, eaID ASC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToArrayOfStruct(loc.payments)>
	</cffunction>
	<cffunction name="SaveDayHeader" access="public" returntype="boolean">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.insertHeader" datasource="#args.datasource#">
			INSERT INTO tblEPOS_DayHeader (
				<!---CASH IN DRAWER--->
				dhCID_5000,
				dhCID_2000,
				dhCID_1000,
				dhCID_0500,
				dhCID_0200,
				dhCID_0100,
				dhCID_0050,
				dhCID_0020,
				dhCID_0010,
				dhCID_0005,
				dhCID_0002,
				dhCID_0001,
				
				<!---SCRATCH CARDS--->
				dhSC_G1_Start,
				dhSC_G1_End,
				dhSC_G2_Start,
				dhSC_G2_End,
				dhSC_G3_Start,
				dhSC_G3_End,
				dhSC_G4_Start,
				dhSC_G4_End,
				dhSC_G5_Start,
				dhSC_G5_End,
				dhSC_G6_Start,
				dhSC_G6_End,
				dhSC_G7_Start,
				dhSC_G7_End,
				dhSC_G8_Start,
				dhSC_G8_End<!---,
				dhSC_G9_Start,
				dhSC_G9_End,
				dhSC_G10_Start,
				dhSC_G10_End,
				dhSC_G11_Start,
				dhSC_G11_End,
				dhSC_G12_Start,
				dhSC_G12_End--->
			) VALUES (
				<!---CASH IN DRAWER--->
				#val(args.form.cid5000)#,
				#val(args.form.cid2000)#,
				#val(args.form.cid1000)#,
				#val(args.form.cid500)#,
				#val(args.form.cid200)#,
				#val(args.form.cid100)#,
				#val(args.form.cid50)#,
				#val(args.form.cid20)#,
				#val(args.form.cid10)#,
				#val(args.form.cid5)#,
				#val(args.form.cid2)#,
				#val(args.form.cid1)#,
				
				<!---SCRATCH CARDS--->
				#val(args.form.sc1_start)#,
				#val(args.form.sc1_end)#,
				#val(args.form.sc2_start)#,
				#val(args.form.sc2_end)#,
				#val(args.form.sc3_start)#,
				#val(args.form.sc3_end)#,
				#val(args.form.sc4_start)#,
				#val(args.form.sc4_end)#,
				#val(args.form.sc5_start)#,
				#val(args.form.sc5_end)#,
				#val(args.form.sc6_start)#,
				#val(args.form.sc6_end)#,
				#val(args.form.sc7_start)#,
				#val(args.form.sc7_end)#,
				#val(args.form.sc8_start)#,
				#val(args.form.sc8_end)#<!---,
				#val(args.form.sc9_start)#,
				#val(args.form.sc9_end)#,
				#val(args.form.sc10_start)#,
				#val(args.form.sc10_end)#,
				#val(args.form.sc11_start)#,
				#val(args.form.sc11_end)#,
				#val(args.form.sc12_start)#,
				#val(args.form.sc12_end)#--->
			)
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn true>
	</cffunction>
	<cffunction name="AddProduct" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.addproduct" datasource="#GetDatasource()#">
			INSERT INTO tblProducts (
				prodRecordTitle,
				prodTitle,
				prodEposCatID,
				prodCashOnly
			) VALUES (
				'#args.npf_title#',
				'#args.npf_title#',
				#val(args.npf_cat)#,
				<cfif StructKeyExists(args, "npf_cashonly")>1<cfelse>0</cfif>
			)
		</cfquery>
		
		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc>
	</cffunction>
	<cffunction name="ParseToJava" access="public" returntype="string">
		<cfargument name="dataToParse" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = "">
		
		<cftry>
		
		<cfloop collection="#dataToParse#" item="loc.key">
			<cfset loc.value = StructFind(dataToParse, loc.key)>
			<cfif IsStruct(loc.value)>
				<cfset loc.result &= ParseToJava(loc.value)>
			<cfelse>
				<cfset loc.hasSpaces = REMatchNoCase("[\s]", toString(loc.value))>
				<cfset loc.hasBinds = REMatchNoCase("[=&]", toString(loc.value))>
				
				<cfif ArrayIsEmpty(loc.hasSpaces) AND !ArrayIsEmpty(loc.hasBinds)>
					<cfset loc.strSplit = ListToArray(loc.value, "&")>
					<cfloop array="#loc.strSplit#" index="loc.part">
						<cfset loc.partSplit = ListToArray(loc.part, "=")>
						<cfset loc.result &= "@#LCase(loc.partSplit[1])#: #URLDecode(toString(loc.partSplit[2]))#">
					</cfloop>
				<cfelse>
					<cfset loc.result &= "@#LCase(loc.key)#: #toString(loc.value)#">
				</cfif>
			</cfif>
		</cfloop>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.result>
	</cffunction>
	<cffunction name="LoadDataForSpeedTest" access="public" returntype="any">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.data" datasource="#args.datasource#">
			SELECT *
			FROM tblProducts
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.data>
	</cffunction>
	<cffunction name="CheckProductExistsByTitle" access="public" returntype="string">
		<cfargument name="checkThisTitle" type="string" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.product" datasource="#GetDatasource()#">
			SELECT prodID
			FROM tblProducts
			WHERE prodTitle = '#checkThisTitle#'
			LIMIT 1;
		</cfquery>
		
		<cfif loc.product.recordcount is 1>
			<cfreturn "true">
		<cfelse>
			<cfreturn "false">
		</cfif>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	<cffunction name="LoadZReading" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.groups = {}>
		<cfset loc.dayStart = "#LSDateFormat(Now(), 'yyyy-mm-dd')# 07:00:00">
		<cfset loc.dayEnd = "#LSDateFormat(Now(), 'yyyy-mm-dd')# 19:00:00">
		
		<cfquery name="loc.loadGroups" datasource="#args.datasource#">
			SELECT *
			FROM tblProductGroups
		</cfquery>
		
		<cfloop query="loc.loadGroups">
			<cfset loc.grp = {}>
			<cfset loc.grp.title = pgTitle>
			<cfset loc.grp.qty = 0>
			<cfset loc.grp.total = 0>
			<cfset StructInsert(loc.groups, pgID, loc.grp)>
		</cfloop>
		
		<cfset StructInsert(loc.groups, "newsmags", {
			title = "News & Mags",
			qty = 0,
			total = 0
		})>
		
		<cfset StructInsert(loc.groups, "unknown", {
			title = "Unknown",
			qty = 0,
			total = 0
		})>
		
		<cfquery name="loc.headers" datasource="#args.datasource#">
			SELECT tblEPOS_Header.*, empFirstName, empLastName
			FROM tblEPOS_Header, tblEmployee
			WHERE ehStatus = 'Active'
			AND ehTimestamp >= '#loc.dayStart#'
			AND ehTimestamp <= '#loc.dayEnd#'
			AND ehEmployee = empID
			ORDER BY ehTimestamp ASC
		</cfquery>
		
		<cfloop query="loc.headers">
			<cfset loc.row = {}>
			<cfset loc.row.id = ehID>
			<cfset loc.row.items = []>
			
			<cfquery name="loc.items" datasource="#args.datasource#">
				SELECT *
				FROM tblEPOS_Items
				WHERE eiParent = #val(loc.row.id)#
			</cfquery>
			
			<cfloop query="loc.items">
				<cfif eiProdID gt 1>
					<cfquery name="loc.group" datasource="#args.datasource#">
						SELECT pcatGroup, prodEposCatID, prodCatID, epcTitle
						FROM tblProducts, tblProductCats, tblEPOS_Cats
						WHERE prodID = #val(eiProdID)#
						AND (prodCatID = pcatID OR prodEposCatID = epcID)
						LIMIT 1;
					</cfquery>
					<cfif loc.group.recordcount is 1>
						<cfif loc.group.prodCatID is 0>
							<cfif loc.group.prodEposCatID is 0>
								<cfset StructUpdate(loc.groups, "unknown", {
									qty = loc.groups.unknown.qty + 1,
									total = loc.groups.unknown.total + val(eiNet + eiDiscount)
								})>
							<cfelse>
								<cfif StructKeyExists(loc.groups, loc.group.epcTitle)>
									<cfset StructUpdate(loc.groups, loc.group.epcTitle, {
										title = loc.group.epcTitle,
										qty = loc.groups[loc.group.epcTitle].qty + 1,
										total = loc.groups[loc.group.epcTitle].total + val(eiNet + eiDiscount)
									})>
								<cfelse>
									<cfset StructInsert(loc.groups, loc.group.epcTitle, {
										title = loc.group.epcTitle,
										qty = 1,
										total = val(eiNet + eiDiscount)
									})>
								</cfif>
							</cfif>
						<cfelse>
							<cfset loc.groups[loc.group.pcatGroup].qty++>
							<cfset loc.groups[loc.group.pcatGroup].total += val(eiNet + eiDiscount)>
						</cfif>
					</cfif>
				</cfif>
				
				<cfif eiPubID gt 1>
					<cfset loc.groups.newsmags.qty++>
					<cfset loc.groups.newsmags.total += val(eiNet + eiDiscount)>
				</cfif>
				
				<cfif eiNomID gt 1>
				</cfif>
			</cfloop>
		</cfloop>
		
		<cfreturn loc>
	</cffunction>
	<cffunction name="LoadTransactions" access="public" returntype="array">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = []>
		
		<cfquery name="loc.header" datasource="#args.datasource#">
			SELECT tblEPOS_Header.*, empFirstName, empLastName
			FROM tblEPOS_Header, tblEmployee
			WHERE ehEmployee = empID
			ORDER BY ehTimestamp DESC
		</cfquery>
		
		<cfloop query="loc.header">
			<cfset loc.row = {}>
			<cfset loc.row.id = ehID>
			<cfset loc.row.timestamp = "#LSDateFormat(ehTimestamp, 'dd/mm/yyyy')# @ #LSTimeFormat(ehTimestamp, 'HH:mm')#">
			<cfset loc.row.employee = "#empFirstName# #Left(empLastName, 1)#">
			<cfset loc.row.net = DecimalFormat(ehNet)>
			<cfset loc.row.vat = DecimalFormat(ehVAT)>
			<cfset loc.row.status = ehStatus>
			<cfset loc.row.mode = ehMode>
			<cfset loc.row.items = []>
			
			<cfquery name="loc.items" datasource="#args.datasource#">
				SELECT tblEPOS_Items.*, prodTitle, pubTitle, eaTitle
				FROM tblEPOS_Items, tblProducts, tblPublication, tblEPOS_Account
				WHERE eiParent = #val(loc.row.id)#
				AND eiProdID = prodID
				AND eiPubID = pubID
				AND eiNomID = eaID
			</cfquery>
			
			<cfloop query="loc.items">
				<cfset loc.item = {}>
				<cfset loc.item.id = eiID>
				<cfset loc.item.type = eiType>
				<cfset loc.item.product = prodTitle>
				<cfset loc.item.publication = pubTitle>
				<cfset loc.item.account = eaTitle>
				<cfset loc.item.qty = eiQty>
				<cfset loc.item.net = DecimalFormat(eiNet)>
				<cfset loc.item.discount = DecimalFormat(eiDiscount)>
				<cfset loc.item.vat = DecimalFormat(eiVAT)>
				<cfset ArrayAppend(loc.row.items, loc.item)>
			</cfloop>
			<cfset ArrayAppend(loc.result, loc.row)>
		</cfloop>
		
		<cfreturn loc.result>
	</cffunction>
	<cffunction name="GetEPOSAccount" access="public" returntype="numeric">
		<cfargument name="type" type="string" required="yes">
		<cfset var loc = {}>
		
		<cfquery name="loc.account" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_Account
			WHERE eaCode = '#UCase(type)#'
			LIMIT 1;
		</cfquery>
		
		<cfif loc.account.recordcount is 1>
			<cfreturn loc.account.eaID>
		<cfelse>
			<cfreturn 0>
		</cfif>
		
	</cffunction>
	<cffunction name="GetVATOfProduct" access="public" returntype="numeric">
		<cfargument name="prodID" type="numeric" required="yes">
		<cfargument name="prodGross" type="numeric" required="yes">
		<cfset var loc = {}>
		
		<cfset prodGross = val(abs(prodGross))>
		
		<cfquery name="loc.prod" datasource="#GetDatasource()#">
			SELECT prodVatRate
			FROM tblProducts
			WHERE prodID = #val(prodID)#
		</cfquery>
		
		<cfif val(loc.prod.prodVatRate) gt 0>
			<cfset loc.net = val(prodGross) / (1 + (val(loc.prod.prodVatRate) / 100))>
			<cfset loc.vat = val(prodGross) - val(loc.net)>
		<cfelse>
			<cfset loc.vat = 0>
		</cfif>
		
		<cfreturn loc.vat>
	</cffunction>
	<cffunction name="IsPayingSupplier" access="public" returntype="boolean">
		<cfset var loc = {}>
		<cfset loc.result = false>
		
		<cftry>
		
		<cfset loc.productCount = StructCount(session.epos_frame.basket.product)>
		<cfset loc.publicationCount = StructCount(session.epos_frame.basket.publication)>
		<cfset loc.dealCount = StructCount(session.epos_frame.basket.deal)>
		<cfset loc.paystationCount = StructCount(session.epos_frame.basket.paystation)>
		<cfset loc.paymentCount = StructCount(session.epos_frame.basket.payment)>
		<cfset loc.supplierCount = StructCount(session.epos_frame.basket.supplier)>
		
		<cfif loc.productCount is 0 AND loc.publicationCount is 0 AND loc.dealCount is 0 AND loc.paystationCount is 0>
			<cfif loc.supplierCount gt 0>
				<cfset loc.result = true>
			</cfif>
		</cfif>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.result>
	</cffunction>
	<cffunction name="CloseTransaction" access="public" returntype="numeric">
		<cfset var loc = {}>
		<cfset loc.frame = StructCopy(session.epos_frame)>
		
		<cftry>
				
		<!---WRITE HEADER RECORD--->
		<cfquery name="loc.insertHeader" datasource="#GetDatasource()#" result="loc.insertHeader_result">
			INSERT INTO tblEPOS_Header (
				ehEmployee,
				ehNet,
				ehVAT,
				ehStatus,
				ehMode
			) VALUES (
				#val(session.user.id)#,
				#val(loc.frame.result.balanceDue)#,
				0.00,<!---VAT TODO--->
				'Active',
				'#loc.frame.mode#'
			)
		</cfquery>
		
		<!---WRITE PRODUCT RECORDS--->
		<cfif StructCount(loc.frame.basket.product) gt 0>
			<cfquery name="loc.insertProduct" datasource="#GetDatasource()#">
				INSERT INTO tblEPOS_Items (
					eiParent,
					eiType,
					eiProdID,
					eiNomID,
					eiQty,
					eiNet,
					eiDiscount,
					eiVAT
				) VALUES
					<cfset loc.counter = 0>
					<cfloop collection="#loc.frame.basket.product#" item="loc.key">
						<cfset loc.counter++>
						<cfset loc.item = StructFind(loc.frame.basket.product, loc.key)>
						<cfset loc.countSaving = (StructKeyExists(loc.item, "saving") AND StructKeyExists(loc.item, "eligibleQty") AND loc.item.eligibleQty gt 0) ? val(loc.item.saving) : 0.00>
						(
							#val(loc.insertHeader_result.generatedkey)#,
							'Sale',
							#val(loc.item.id)#,
							'#GetEPOSAccount("Sale")#',
							#val(loc.item.qty)#,
							#val(loc.item.qty) * val(loc.item.price) + val(loc.countSaving)#,
							#val(loc.countSaving)#,
							#val(GetVATOfProduct(loc.item.id, (val(loc.item.qty) * val(loc.item.price) + val(loc.countSaving))))#
						)<cfif loc.counter neq StructCount(loc.frame.basket.product)>,</cfif>
					</cfloop>
			</cfquery>
		</cfif>

		<!---WRITE SUPPLIER RECORDS--->
		<cfif StructCount(loc.frame.basket.supplier) gt 0>
			<cfquery name="loc.insertSupplier" datasource="#GetDatasource()#">
				INSERT INTO tblEPOS_Items (
					eiParent,
					eiType,
					eiAccID,
					eiQty,
					eiNet,
					eiDiscount,
					eiVAT
				) VALUES
					<cfset loc.counter = 0>
					<cfloop collection="#loc.frame.basket.supplier#" item="loc.key">
						<cfset loc.counter++>
						<cfset loc.item = StructFind(loc.frame.basket.supplier, loc.key)>
						<cfset loc.countSaving = (StructKeyExists(loc.item, "saving") AND StructKeyExists(loc.item, "eligibleQty") AND loc.item.eligibleQty gt 0) ? val(loc.item.saving) : 0.00>
						(
							#val(loc.insertHeader_result.generatedkey)#,
							'Sale',
							#val(loc.item.id)#,
							#val(loc.item.qty)#,
							#val(loc.item.qty) * val(loc.item.price) + val(loc.countSaving)#,
							#val(loc.countSaving)#,
							#val(GetVATOfProduct(loc.item.id, (val(loc.item.qty) * val(loc.item.price) + val(loc.countSaving))))#
						)<cfif loc.counter neq StructCount(loc.frame.basket.supplier)>,</cfif>
					</cfloop>
			</cfquery>
		</cfif>

		<!---WRITE PUBLICATION RECORDS--->
		<cfif StructCount(loc.frame.basket.publication) gt 0>
			<cfquery name="loc.insertPublication" datasource="#GetDatasource()#">
				INSERT INTO tblEPOS_Items (
					eiParent,
					eiType,
					eiPubID,
					eiNomID,
					eiQty,
					eiNet
				) VALUES
					<cfset loc.counter = 0>
					<cfloop collection="#loc.frame.basket.publication#" item="loc.key">
						<cfset loc.counter++>
						<cfset loc.item = StructFind(loc.frame.basket.publication, loc.key)>
						(
							#val(loc.insertHeader_result.generatedkey)#,
							'Sale',
							#val(loc.item.id)#,
							'#GetEPOSAccount("Sale")#',
							#val(loc.item.qty)#,
							#val(loc.item.qty) * val(loc.item.price)#
						)<cfif loc.counter neq StructCount(loc.frame.basket.publication)>,</cfif>
					</cfloop>
			</cfquery>
		</cfif>

		<!---WRITE PAYMENT RECORDS--->
		<cfset loc.cashBackVal = ( StructKeyExists(loc.frame.basket.payment, "cashback") ) ? val(loc.frame.basket.payment.cashback.value) : 0>
		<cfif StructKeyExists(loc.frame.basket.payment, "cashback")><cfset StructDelete(loc.frame.basket.payment, "cashback")></cfif>
		
		<cfloop collection="#loc.frame.basket.payment#" item="loc.key">
			<cfset loc.item = StructFind(loc.frame.basket.payment, loc.key)>
			<cfif UCase(loc.item.title) eq "PRIZE">
				<cfset StructDelete(loc.frame.basket.payment, loc.key)>
				<cfquery name="loc.insertPrizePayment" datasource="#GetDatasource()#">
					INSERT INTO tblEPOS_Items (
						eiParent,
						eiType,
						eiNomID,
						eiQty,
						eiNet
					) VALUES (
						#val(loc.insertHeader_result.generatedkey)#,
						'Payment',
						12,
						1,
						#-val(loc.item.value)#
					)
				</cfquery>
			</cfif>
		</cfloop>
		<cfif StructCount(loc.frame.basket.payment) gt 0>
			<cfquery name="loc.insertPayment" datasource="#GetDatasource()#">
				INSERT INTO tblEPOS_Items (
					eiParent,
					eiType,
					eiNomID,
					eiQty,
					eiNet,
					eiCashback
				) VALUES
					<cfset loc.counter = 0>
					<cfloop collection="#loc.frame.basket.payment#" item="loc.key">
						<cfset loc.counter++>
						<cfset loc.item = StructFind(loc.frame.basket.payment, loc.key)>
						(
							#val(loc.insertHeader_result.generatedkey)#,
							'Payment',
							'#GetEPOSAccount("#loc.item.title#")#',
							1,
							<cfif loc.item.title eq "CARD">
								#val(loc.item.credit)#,
								#val(loc.item.cash)#
							<cfelse>
								#val(loc.item.credit)#,
								0.00
							</cfif>
						)<cfif loc.counter neq StructCount(loc.frame.basket.payment)>,</cfif>
					</cfloop>
			</cfquery>
		</cfif>
		
		<cfset session.epos_frame.archived = StructCopy(session.epos_frame.basket)>
		
		<cfset session.epos_frame.result.balanceDue = 0>
		<cfset session.epos_frame.result.totalGiven = 0>
		<cfset session.epos_frame.result.changeDue = 0>
		<cfset session.epos_frame.result.discount = 0>
		<cfset loc.requiredKeys = ["product", "publication", "paystation", "deal", "payment", "discount", "supplier"]>
		<cfset session.epos_frame.basket = {}>
		<cfloop array="#loc.requiredKeys#" index="loc.key">
			<cfset StructInsert(session.epos_frame.basket, loc.key, {})>
		</cfloop>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn val(loc.insertHeader_result.generatedkey)>
	</cffunction>
	<cffunction name="UpdateReminderStatus" access="public" returntype="void">
		<cfargument name="remID" type="numeric" required="yes">
		<cfargument name="newStatus" type="string" required="yes">
		<cfargument name="remScope" type="string" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfif remScope eq "global">
			<cfquery name="loc.update" datasource="#GetDatasource()#">
				UPDATE tblEPOS_GlobalReminders
				SET egrStatus = '#newStatus#'
				WHERE egrID = #val(remID)#
			</cfquery>
		<cfelseif remScope eq "local">
			<cfquery name="loc.update" datasource="#GetDatasource()#">
				UPDATE tblEPOS_LocalReminders
				SET elrStatus = '#newStatus#'
				WHERE elrID = #val(remID)#
			</cfquery>
		</cfif>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	<cffunction name="LoadGlobalReminders" access="public" returntype="array">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.globalReminders" datasource="#args.datasource#">
			SELECT *
			FROM tblEPOS_GlobalReminders
			WHERE (
				(egrStart >= '#LSDateFormat(Now()-1, "yyyy-mm-dd")#' AND egrEnd >= '#LSDateFormat(Now(), "yyyy-mm-dd")#')
				OR
				(egrRecurring = 'hourly' OR egrRecurring = 'daily' OR egrRecurring = 'weekly')
			)
			ORDER BY egrStart ASC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (loc.globalReminders.recordcount gt 0) ? QueryToArrayOfStruct(loc.globalReminders) : []>
	</cffunction>
	<cffunction name="LoadLocalReminders" access="public" returntype="array">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.localReminders" datasource="#args.datasource#">
			SELECT *
			FROM tblEPOS_LocalReminders
			WHERE (
				(elrStart >= '#LSDateFormat(Now()-1, "yyyy-mm-dd")#' AND elrEnd >= '#LSDateFormat(Now(), "yyyy-mm-dd")#')
				OR
				(elrRecurring = 'hourly' OR elrRecurring = 'daily' OR elrRecurring = 'weekly')
			)
			ORDER BY elrStart ASC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn (loc.localReminders.recordcount gt 0) ? QueryToArrayOfStruct(loc.localReminders) : []>
	</cffunction>
	<cffunction name="LoadHomeFunctions" access="public" returntype="array">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.homeFunctions" datasource="#args.datasource#">
			SELECT *
			FROM tblEPOS_Home
			ORDER BY ehOrder ASC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToArrayOfStruct(loc.homeFunctions)>
	</cffunction>
	<cffunction name="ProcessDiscounts" access="public" returntype="string">
		<cfset var loc = {}>
		<cfset loc.sign = (2 * int(session.basket.info.mode eq "reg")) - 1>
		<cfset loc.grossValue = 0>
		<cfset loc.discount = 0>
		<cfset loc.message = "">
		
		<cftry>
		
		<cfloop collection="#session.epos_frame.basket.product#" item="loc.key">
			<cfset loc.item = StructFind(session.epos_frame.basket.product, loc.key)>
			<cfset loc.product = LoadProductByID(loc.item.id)>
			
			<cfif StructKeyExists(loc.product, "prodStaffDiscount")>
				<cfif loc.product.prodStaffDiscount eq "Yes">
					<cfset loc.grossValue += ( loc.item.price * loc.item.qty )>
				</cfif>
			</cfif>
		</cfloop>
		
		<cfset loc.dcCount = StructCount(session.epos_frame.basket.discount)>
		<cfif loc.dcCount gt 1>
			<cfif StructKeyExists(session.epos_frame.basket.discount, "staffdiscount")>
				<cfset StructDelete(session.epos_frame.basket.discount, "staffdiscount")>
				<cfset loc.message = "Staff Discount Removed">
			</cfif>
		</cfif>
		
		<cfloop collection="#session.epos_frame.basket.discount#" item="loc.key">
			<cfset loc.dItem = StructFind(session.epos_frame.basket.discount, loc.key)>
			<cfif abs(loc.grossValue) gte abs(loc.dItem.minbalance)>
				<cfset loc.dItem.value = abs(loc.dItem.value)>
				<cfif loc.dItem.unit eq "pound">
					<cfset loc.dItem.amount = -val(loc.dItem.value)>
					<cfset loc.discount += -val(loc.dItem.value)>
				<cfelse>
					<cfset loc.dItem.amount = (val(loc.dItem.value) / 100) * loc.grossValue>
					<cfset loc.discount += (val(loc.dItem.value) / 100) * loc.grossValue>
				</cfif>
			<cfelse>
				<cfset loc.message = "Balance must be greater than &pound;#DecimalFormat(abs(loc.dItem.minbalance))# for voucher to apply">
				<cfset StructDelete(session.epos_frame.basket.discount, loc.key)>
			</cfif>
		</cfloop>
		
		<cfset session.epos_frame.result.discount = NumberFormat(loc.discount, "0.00")>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.message>
	</cffunction>
	<cffunction name="LoadDealsIntoSession" access="public" returntype="struct">
		<cfset var loc = {}>
		<cfset loc.deals = []>
		
		<cfquery name="loc.allValidDeals" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_Deals
			WHERE edStarts <= '#LSDateFormat(Now(), "yyyy-mm-dd")#'
			AND edEnds >= '#LSDateFormat(Now(), "yyyy-mm-dd")#'
			AND edStatus = 'Active'
			AND edType != 'Selection'<!---TEMP--->
		</cfquery>
		
		<cfloop query="loc.allValidDeals">
			<cfset loc.i = {}>
			<cfset loc.i.edID = edID>
			<cfset loc.i.edTitle = edTitle>
			<cfset loc.i.edStarts = edStarts>
			<cfset loc.i.edEnds = edEnds>
			<cfset loc.i.edType = edType>
			<cfset loc.i.edAmount = -val(edAmount)>
			<cfset loc.i.edQty = edQty>
			<cfset loc.i.edStatus = edStatus>
			<cfset loc.i.children = []>
			<cfquery name="loc.dealChildren" datasource="#GetDatasource()#">
				SELECT *
				FROM tblEPOS_DealItems
				WHERE ediParent = #val(loc.i.edID)#
			</cfquery>
			<cfloop query="loc.dealChildren">
				<cfset loc.c = {}>
				<cfset loc.c.ediID = ediID>
				<cfset loc.c.ediParent = ediParent>
				<cfset loc.c.ediProduct = ediProduct>
				<cfset loc.c.ediMinQty = ediMinQty>
				<cfset loc.c.ediMaxQty = ediMaxQty>
				<cfset ArrayAppend(loc.i.children, loc.c)>
			</cfloop>
			<cfset ArrayAppend(loc.deals, loc.i)>
		</cfloop>
		
		<cfset session.epos_frame.deals = loc.deals>
		
		<cfreturn loc>
	</cffunction>
	<cffunction name="ProcessDeals" access="public" returntype="struct">
		<cfset var loc = {}>
		<cfset loc.sign = (2 * int(session.basket.info.mode eq "reg")) - 1>
		<cfset loc.basket = session.epos_frame.basket>
		
		<cftry>
		
		<cfif StructCount(session.epos_frame.basket.product) gt 0>
			<cfloop array="#session.epos_frame.deals#" index="loc.deal">
				<cfset loc.selRating = 0>
				<cfset loc.selGrouped = false>
				<cfset loc.grpTotal = 0>
				<cfset loc.grpEligibleQty = 0>
				<cfloop collection="#session.epos_frame.basket.product#" item="loc.key">
					<cfset loc.item = StructFind(session.epos_frame.basket.product, loc.key)>
					<cfloop array="#loc.deal.children#" index="loc.child">
						<cfif loc.item.id is loc.child.ediProduct>
							<cfset loc.grpTotal += loc.item.price>
							<cfswitch expression="#loc.deal.edType#">
								<cfcase value="Quantity">
									<cfset loc.item.eligibleQty = int(loc.item.qty / loc.deal.edQty)>
									<cfset loc.item.saving = -((loc.deal.edQty * loc.item.price) - loc.deal.edAmount * loc.sign)>
									<cfset loc.item.dealTitle = loc.deal.edTitle>
									<cfset loc.item.grossSaving = loc.item.eligibleQty * loc.item.saving>
									<cfif loc.item.eligibleQty gt 0>
										<cfif StructKeyExists(session.epos_frame.basket.deal, loc.item.id)>
											<cfset StructUpdate(session.epos_frame.basket.deal, loc.item.id, {
												title = loc.deal.edTitle,
												price = loc.item.saving,
												qty = loc.item.eligibleQty,
												product = loc.item.id,
												index = loc.item.id,
												cashOnly = 0
											})>
										<cfelse>
											<cfset StructInsert(session.epos_frame.basket.deal, loc.item.id, {
												title = loc.deal.edTitle,
												price = loc.item.saving,
												qty = loc.item.eligibleQty,
												product = loc.item.id,
												index = loc.item.id,
												cashOnly = 0
											})>
										</cfif>
									</cfif>
								</cfcase><!---Quantity--->
								<cfcase value="Discount">
									<cfset loc.item.eligibleQty = int(loc.item.qty / loc.deal.edQty)>
									<cfset loc.item.saving = -(loc.deal.edAmount * loc.sign)>
									<cfset loc.item.dealTitle = loc.deal.edTitle>
									<cfset loc.item.grossSaving = loc.item.eligibleQty * loc.item.saving>
									<cfif loc.item.eligibleQty gt 0>
										<cfif StructKeyExists(session.epos_frame.basket.deal, loc.item.id)>
											<cfset StructUpdate(session.epos_frame.basket.deal, loc.item.id, {
												title = loc.deal.edTitle,
												price = loc.item.saving,
												qty = loc.item.eligibleQty,
												product = loc.item.id,
												index = loc.item.id,
												cashOnly = 0
											})>
										<cfelse>
											<cfset StructInsert(session.epos_frame.basket.deal, loc.item.id, {
												title = loc.deal.edTitle,
												price = loc.item.saving,
												qty = loc.item.eligibleQty,
												product = loc.item.id,
												index = loc.item.id,
												cashOnly = 0
											})>
										</cfif>
									</cfif>
								</cfcase><!---Discount--->
								<!---<cfcase value="Selection">
									<cfset loc.location = "0">
									<!---<cfif loc.item.qty gt ArrayLen(loc.deal.children)>
										<cfset loc.selRating++>
										<cfset loc.location = loc.location & "A">
									<cfelse>--->
										<!---<cfif loc.item.qty gte loc.child.ediMinQty AND loc.item.qty lte loc.child.ediMaxQty>--->
										<cfif loc.item.qty MOD loc.child.ediMinQty is 0 AND loc.item.qty MOD loc.child.ediMaxQty is 0>
											<cfset loc.selRating++>
											<cfset loc.location = loc.location & "1">
											
											<!---<cfset loc.selDivided = loc.item.qty / loc.child.ediMinQty>
											<cfset loc.grpEligibleQty = loc.selDivided>--->
										<cfelse>
											<cfset loc.qtyMinMultiple = loc.child.ediMinQty MOD loc.item.qty>
											<cfset loc.qtyMaxMultiple = loc.child.ediMaxQty MOD loc.item.qty>
											<cfif loc.qtyMinMultiple is loc.child.ediMinQty AND loc.qtyMaxMultiple is loc.child.ediMaxQty>
												<cfset loc.selRating++>
												<cfset loc.grpEligibleQty++>
												<cfset loc.selGrouped = true>
												<cfset loc.location = loc.location & "2">
											</cfif>
										</cfif>
									<!---</cfif>--->
									
									<cfset loc.location = loc.location & "~SELRAT:#loc.selRating#~">
									
									<cfif loc.selRating is ArrayLen(loc.deal.children) OR loc.selRating MOD ArrayLen(loc.deal.children) is ArrayLen(loc.deal.children)>
										<cfif NOT loc.selGrouped>
											<cfset loc.grpEligibleQty++>
											<cfset loc.location = loc.location & "4">
										</cfif>
										<cfset loc.item.eligibleQty = loc.grpEligibleQty>
										<cfset loc.location = loc.location & "~ELIQTY:#loc.item.eligibleQty#~">
										<cfset loc.item.saving = -((abs(loc.grpTotal) - abs(loc.deal.edAmount)) * loc.sign)>
										<cfset loc.item.dealTitle = loc.deal.edTitle>
										<cfset loc.item.grossSaving = loc.item.eligibleQty * loc.item.saving>
										<cfif loc.item.eligibleQty gt 0>
											<cfif StructKeyExists(session.epos_frame.basket.deal, loc.item.id)>
												<cfset StructUpdate(session.epos_frame.basket.deal, loc.item.id, {
													title = loc.deal.edTitle,
													price = -loc.item.saving,
													qty = loc.item.eligibleQty,
													product = loc.item.id,
													index = loc.item.id
												})>
												<cfset loc.location = loc.location & "5">
											<cfelse>
												<cfset StructInsert(session.epos_frame.basket.deal, loc.item.id, {
													title = loc.deal.edTitle,
													price = -loc.item.saving,
													qty = loc.item.eligibleQty,
													product = loc.item.id,
													index = loc.item.id
												})>
												<cfset loc.location = loc.location & "6">
											</cfif><!---StructKeyExists(session.epos_frame.basket.deal, loc.item.id)--->
										</cfif><!---loc.item.eligibleQty gt 0--->
									</cfif><!---loc.selRating is ArrayLen(loc.deal.children) OR loc.selRating MOD ArrayLen(loc.deal.children) is 0--->
								</cfcase>---><!---Selection--->
							</cfswitch><!---loc.deal.edType--->
						</cfif><!---loc.item.id is loc.child.ediProduct--->
					</cfloop><!---loc.deal.children--->
				</cfloop><!---session.epos_frame.basket.product--->
			</cfloop><!---loc.deals--->
		<cfelse>
			<cfset StructClear(session.epos_frame.basket.deal)>
		</cfif>
		
		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc>
	</cffunction>

	<cffunction name="CheckUserPin" access="public" returntype="string">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.currentPin" datasource="#args.datasource#">
			SELECT empPin
			FROM tblEmployee
			WHERE empID = #val(args.userID)#
		</cfquery>
		
		<cfif VerifyEncryptedString(args.pin, loc.currentPin.empPin)>
			<cfreturn "true">
		<cfelse>
			<cfreturn "false">
		</cfif>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="UpdateUserPin" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.currentPin" datasource="#args.datasource#">
			SELECT empPin
			FROM tblEmployee
			WHERE empID = #val(args.userID)#
		</cfquery>
		
		<cfif VerifyEncryptedString(args.oldpin, loc.currentPin.empPin)>
			<cfquery name="loc.newPin" datasource="#args.datasource#">
				UPDATE tblEmployee
				SET empPin = DES_ENCRYPT("#args.newpin#")
				WHERE empID = #val(args.userID)#
			</cfquery>
			<cfset loc.result.msg = "Pin number changed">
			<cfset loc.result.error = 0>
		<cfelse>
			<cfset loc.result.msg = "Pin number invalid">
			<cfset loc.result.error = 1>
		</cfif>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.result>
	</cffunction>
	
	<cffunction name="UpdateAccentColour" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cftry>
		
		<cfquery name="loc.update" datasource="#args.datasource#">
			UPDATE tblEmployee
			SET empAccent = '#args.form.colour#'
			WHERE empID = #val(args.form.employee)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="LoadUserPreferencesMinimal" access="public" returntype="struct">
		<cfargument name="userID" type="numeric" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
		
		<cfquery name="loc.user" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEmployee
			WHERE empID = #val(userID)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfset loc.result = QueryToStruct(loc.user)>
		
		<cfif StructKeyExists(loc.result, "empPin")>
			<cfset StructDelete(loc.result, "empPin")>
		</cfif>
		
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="LoadUserPreferences" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
		
		<cfquery name="loc.user" datasource="#args.datasource#">
			SELECT *
			FROM tblEmployee
			WHERE empID = #val(args.userID)#
		</cfquery>

		<cfset loc.result = QueryToStruct(loc.user)>
		
		<cfif StructKeyExists(loc.result, "empPin")>
			<cfset StructDelete(loc.result, "empPin")>
		</cfif>
		
		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.result>
	</cffunction>
	
	<cffunction name="LoadSuppliers" access="public" returntype="array">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = []>
		
		<cftry>
		
		<cfquery name="loc.suppliers" datasource="#args.datasource#">
			SELECT *
			FROM tblAccount
			WHERE accType = 'purch'
			AND accPayAcc = 181
			AND accStatus = 'active'
			ORDER BY accName
		</cfquery>
		
		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToArrayOfStruct(loc.suppliers)>
	</cffunction>

	<cffunction name="LoadSuppliersForStockControl" access="public" returntype="array">
		<cfset var loc = {}>
		<cfset loc.result = []>
		
		<cftry>
		
		<cfquery name="loc.suppliers" datasource="#GetDatasource()#">
			SELECT *
			FROM tblAccount
			WHERE accType = 'purch'
			AND accStockControlType = 'scan'
			ORDER BY accName ASC
		</cfquery>
		
		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToArrayOfStruct(loc.suppliers)>
	</cffunction>

	<cffunction name="LoadNewspapers" access="public" returntype="array">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = []>
		
		<cftry>
		
		<cfquery name="loc.pubs" datasource="#args.datasource#">
			SELECT pubID, pubTitle, pubRoundTitle, pubPrice
			FROM tblPublication
			WHERE pubGroup = 'news'
			<cfif args.daynow is "saturday">
				AND pubType IN ('saturday', 'weekly')
			<cfelseif args.daynow is "sunday">
				AND pubType IN ('sunday', 'weekly')
			<cfelse>
				AND pubType IN ('morning', 'weekly')
			</cfif>
			AND pubSaleType = 'variable'
			AND pubEPOS
			AND pubActive
			ORDER BY pubType ASC, pubTitle ASC
		</cfquery>
		
		<cfloop query="loc.pubs">
			<cfset loc.item = {}>
			<cfset loc.item.id = pubID>
			<cfset loc.item.title = (Len(pubRoundTitle)) ? pubRoundTitle : pubTitle>
			<cfset loc.item.price = pubPrice>
			<cfset ArrayAppend(loc.result, loc.item)>
		</cfloop>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="BasketItemCount" access="public" returntype="numeric">
		<cfset var loc = {}>
		<cfset loc.totalCount = 0>	<!--- added in case of error in cftry 12/6/15 SMK --->
		<cftry>
		
		<cfset loc.productCount = StructCount(session.epos_frame.basket.product)>
		<cfset loc.publicationCount = StructCount(session.epos_frame.basket.publication)>
		<cfset loc.dealCount = StructCount(session.epos_frame.basket.deal)>
		<cfset loc.paystationCount = StructCount(session.epos_frame.basket.paystation)>
		<cfset loc.paymentCount = StructCount(session.epos_frame.basket.payment)>
		<cfset loc.supplierCount = StructCount(session.epos_frame.basket.supplier)>
		
		<cfset loc.totalCount = loc.productCount + loc.publicationCount + loc.dealCount + loc.paystationCount + loc.paymentCount + loc.supplierCount>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.totalCount>
	</cffunction>

	<cffunction name="SearchProductByName" access="public" returntype="array" hint="load products and stock items for items actually stocked and active.">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.prods" datasource="#args.datasource#">
			SELECT tblProducts.*, siUnitSize,siOurPrice, epcKey
			FROM tblProducts
			INNER JOIN tblStockItem ON prodID = siProduct
			AND tblStockItem.siID = (
				SELECT MAX( siID )
				FROM tblStockItem
				WHERE prodID = siProduct 
				AND siStatus NOT IN ('returned','inactive','promo'))
			INNER JOIN tblEPOS_Cats ON prodEposCatID=epcID
			WHERE prodTitle LIKE '%#args.form.title#%'
			ORDER BY prodTitle ASC, siUnitSize ASC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfif loc.prods.recordcount gt 0>
			<cfreturn QueryToArrayOfStruct(loc.prods)>
		<cfelse>
			<cfreturn []>
		</cfif>
	</cffunction>

	<cffunction name="LoadPublicationByID" access="public" returntype="struct">
		<cfargument name="publicationID" type="numeric" required="yes">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.publication" datasource="#GetDatasource()#">
			SELECT tblPublication.*, 'MEDIA' AS epcKey
			FROM tblPublication
			WHERE pubID = #val(publicationID)#
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToStruct(loc.publication)>
	</cffunction>

	<cffunction name="LoadProductByID" access="public" returntype="struct">
		<cfargument name="productID" type="numeric" required="yes">

		<cfset var loc = {}>
		<cfset loc.result = {}>

		<cftry>
			<cfquery name="loc.product" datasource="#GetDatasource()#" result="loc.prodres">
				SELECT prodID,prodStaffDiscount,prodRef,prodRecordTitle,prodTitle,prodCountDate,prodStockLevel,prodLastBought,prodStaffDiscount
						prodPackPrice,prodValidTo,prodPriceMarked,prodCatID,prodVATRate,prodSign,prodCashOnly,prodClass,
						siID,siRef,siOrder,siUnitSize,siPackQty,siQtyPacks,siQtyItems,siWSP,siUnitTrade,siRRP,siOurPrice,siPOR,siReceived,siBookedIn,siExpires,siStatus,
						epcKey
				FROM tblProducts
				INNER JOIN tblEPOS_Cats ON epcID = prodEposCatID
				LEFT JOIN tblStockItem ON prodID = siProduct
				AND tblStockItem.siID = (
					SELECT MAX( siID )
					FROM tblStockItem
					WHERE prodID = siProduct )
				WHERE prodID=#val(productID)#
				LIMIT 1;
			</cfquery>

			<cfset loc.result = QueryToStruct(loc.product)>

            <cfcatch type="any">
                <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
                    output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
            </cfcatch>
		</cftry>

		<cfreturn loc.result>
	</cffunction>

	<cffunction name="CheckBarcodeExists" access="public" returntype="struct">
		<cfargument name="barcode" type="string" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {
			signal = false,
			data = {}
		}>
		
		<cftry>
		
		<cfquery name="loc.barcode" datasource="#GetDatasource()#">
			SELECT barCode, barType, barProdID
			FROM tblBarcodes
			WHERE barCode = '#barcode#'
			LIMIT 1;
		</cfquery>
		
		<cfif loc.barcode.recordcount gt 0>
<!---			<cfquery name="loc.product" datasource="#GetDatasource()#">
				SELECT *
				FROM tblProducts
				WHERE prodID = #val(loc.barcode.barProdID)#
			</cfquery>
--->			
			<cfset loc.result.signal = true>
			<!---<cfset loc.result.data = QueryToStruct(loc.product)>--->
			<cfset loc.result.data = LoadProductByID(loc.barcode.barProdID)>
		<cfelse>
			<cfset loc.ibResult = InterrogateBarcode(barcode)>
			<cfif StructKeyExists(loc.ibResult, "id")>
				<cfswitch expression="#loc.ibResult.type#">
					<cfcase value="product">
						<cfset loc.result.data = LoadProductByID(loc.ibResult.id)>
					</cfcase>
					<cfcase value="publication">
						<cfset loc.result.data = LoadPublicationByID(loc.ibResult.id)>
					</cfcase>
				</cfswitch>
				<cfset loc.result.signal = true>
				<cfset loc.result.data.type = loc.ibResult.type>
				<cfset loc.result.data.encodedValue = loc.ibResult.value>
				<cfset loc.result.data.minBalance = loc.ibResult.minBalance>
			<cfelse>
				<cfset loc.result.signal = false>
				<cfset loc.result.data = {}>
			</cfif>
		</cfif>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>

		<cfreturn loc.result>
	</cffunction>

	<cffunction name="LoadProductByBarcode" access="public" returntype="struct">
		<cfargument name="barcode" type="string" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>		
			<cfset loc.result.barcode = NumberFormat(Left(barcode,15),"0000000000000")>
			<cfquery name="loc.barcode" datasource="#GetDatasource()#">
				SELECT barCode, barType, barProdID
				FROM tblBarcodes
				WHERE barCode = '#loc.result.barcode#'
				LIMIT 1;
			</cfquery>
			<cfset loc.result.Qbarcode = loc.barcode>
			<cfif loc.barcode.recordcount gt 0>
				<cfloop query="loc.barcode">
					<cfswitch expression="#barType#">
						<cfcase value="product">
							<cfset loc.result = LoadProductByID(barProdID)>
						</cfcase>
						<cfcase value="publication">
							<cfset loc.result = LoadPublicationByID(barProdID)>
						</cfcase>
					</cfswitch>
					<cfset loc.result.type = barType>
					<cfset loc.result.minBalance = 0>
				</cfloop>
			<cfelse>
				<cfset loc.ibResult = InterrogateBarcode(barcode)>
				<cfif StructKeyExists(loc.ibResult, "id")>
					<cfswitch expression="#loc.ibResult.type#">
						<cfcase value="product">
							<cfset loc.result = LoadProductByID(loc.ibResult.id)>
						</cfcase>
						<cfcase value="publication">
							<cfset loc.result = LoadPublicationByID(loc.ibResult.id)>
						</cfcase>
					</cfswitch>
					<cfset loc.result.type = loc.ibResult.type>
					<cfset loc.result.encodedValue = loc.ibResult.value>
					<cfset loc.result.minBalance = loc.ibResult.minBalance>
				<cfelse>
					<cfset loc.result.msg = "#barcode# barcode not found">
				</cfif>
			</cfif>
			
		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="InterrogateBarcode" access="public" returntype="struct">
		<cfargument name="barcode" type="string" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
		
		<cfquery name="loc.samples" datasource="#GetDatasource()#">
			SELECT *
			FROM tblCodeSamples
			WHERE csCode = SUBSTRING("#barcode#", 1, LENGTH(csCode))
			AND (	(csStart <= '#LSDateFormat(Now(), "yyyy-mm-dd")#' AND csEnd >= '#LSDateFormat(Now(), "yyyy-mm-dd")#')
					OR csDateRestrict = 'No'	)
			LIMIT 1;
		</cfquery>
		<cfif loc.samples.recordcount is 1>
			<cfset loc.result.id = val(loc.samples.csItemID)>
			<cfset loc.result.type = loc.samples.csItemType>
			<cfset loc.result.extract = loc.samples.csExtract>
			<cfset loc.result.minBalance = val(loc.samples.csMinBalance)>
			<cfset loc.result.error = false>
			<cfset loc.result.value = 0>
			
			<cfif Len(loc.samples.csRegExp)>
				<cfset loc.processed = REFindNoCase(loc.samples.csRegExp, barcode, 0, true)>
				<cfif arrayLen(loc.processed.len) eq 2>
					<cfset loc.extracted = mid(barcode, loc.processed.pos[2], loc.processed.len[2])>
					<cfif Len(loc.samples.csOperator)>
						<cfswitch expression="#loc.samples.csOperator#">
							<cfcase value="+"><cfset loc.extracted = val(loc.extracted) + loc.samples.csModifier></cfcase>
							<cfcase value="-"><cfset loc.extracted = val(loc.extracted) - loc.samples.csModifier></cfcase>
							<cfcase value="*"><cfset loc.extracted = val(loc.extracted) * loc.samples.csModifier></cfcase>
							<cfcase value="/"><cfset loc.extracted = val(loc.extracted) / loc.samples.csModifier></cfcase>
							<cfdefaultcase><cfset loc.extracted = loc.extracted></cfdefaultcase>
						</cfswitch>
					</cfif>
					
					<cfset loc.result.value = val(loc.extracted)>
					
					<cfif loc.samples.csSign eq "negative">
						<cfif loc.result.value gt 0>
							<cfset loc.result.value = -loc.result.value>
						</cfif>
					</cfif>
				</cfif>
			</cfif>
		</cfif>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
				
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="LoadProductsByCategory" access="public" returntype="array">
		<cfargument name="catID" type="numeric" required="yes">
		<cfset var loc = {}>
		<cftry>
			<cfquery name="loc.products" datasource="#GetDatasource()#">
				SELECT prodID,prodTitle,prodOurPrice,prodStaffDiscount,prodClass,prodVatRate,prodCashOnly,prodSign, siOurPrice, epcKey,epcOrder
				FROM tblProducts
				LEFT JOIN tblStockItem ON prodID = siProduct
				AND tblStockItem.siID = (
					SELECT MAX( siID )
					FROM tblStockItem
					WHERE prodID = siProduct )
				INNER JOIN tblEPOS_Cats ON prodEposCatID=epcID
				WHERE epcParent = #val(catID)#
				AND prodStatus = 'active'
				ORDER BY epcOrder
			</cfquery>
			<cfcatch type="any">
				 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
				 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
			</cfcatch>
		</cftry>
		<cfreturn QueryToArrayOfStruct(loc.products)>
	</cffunction>
	
	<cffunction name="LoadCategories" access="public" returntype="array">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.cats" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_Cats
			WHERE epcPMAllow = 'Yes'
			ORDER BY epcOrder ASC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToArrayOfStruct(loc.cats)>
	</cffunction>

	<cffunction name="LoadAllCategories" access="public" returntype="array">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.cats" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEPOS_Cats
			ORDER BY epcOrder ASC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToArrayOfStruct(loc.cats)>
	</cffunction>

	<cffunction name="LoadCategoriesForEmployeeMin" access="public" returntype="array">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.cats" datasource="#GetDatasource()#">
			SELECT epcID, epcTitle, epcFile
			FROM tblEPOS_Cats, tblEPOS_EmpCats
			WHERE eecCategory = epcID
			AND eecEmployee = #val(session.user.id)#
			ORDER BY eecOrder ASC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToArrayOfStruct(loc.cats)>
	</cffunction>

	<cffunction name="LoadCategoriesForEmployee" access="public" returntype="array">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cftry>
			<cfquery name="loc.cats" datasource="#args.datasource#">
				SELECT epcID, epcTitle, epcFile
				FROM tblEPOS_Cats, tblEPOS_EmpCats
				WHERE eecCategory = epcID
				AND eecEmployee = #val(session.user.id)#
				AND epcParent = 0
				ORDER BY eecOrder ASC
			</cfquery>
		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			 	output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToArrayOfStruct(loc.cats)>
	</cffunction>

	<cffunction name="VerifyEncryptedString" access="public" returntype="boolean">
		<cfargument name="stringToTest" type="string" required="yes">
		<cfargument name="originalString" type="binary" required="yes">
		<cfset var loc = {}>
		<cftry>
		
		<cfquery name="loc.enc" datasource="#GetDatasource()#">
			SELECT (DES_ENCRYPT("#stringToTest#")) AS encryptedString
		</cfquery>
		<cfset loc.result = (ToString(loc.enc.encryptedString) eq ToString(originalString)) ? true : false>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="Login" access="public" returntype="boolean">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = false>
		
		<cftry>
		
		<cfquery name="loc.employee" datasource="#args.datasource#">
			SELECT empID, empFirstName, empLastName, empPin, empEPOSLevel
			FROM tblEmployee
			WHERE empID = #val(args.form.employee)#
		</cfquery>
		
		<cfif VerifyEncryptedString(args.form.pin, loc.employee.empPin)>
			<cfset session.user.id = loc.employee.empID>
			<cfset session.user.firstName = loc.employee.empFirstName>
			<cfset session.user.lastName = loc.employee.empLastName>
			<cfset session.user.eposLevel = loc.employee.empEPOSLevel>
			<cfset session.user.loggedin = true>
			<cfset session.user.prefs = LoadUserPreferencesMinimal(loc.employee.empID)>
			<cfset loc.result = true>
		</cfif>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="LoadEmployees" access="public" returntype="array">
		<cfset var loc = {}>
		
		<cftry>
		
		<cfquery name="loc.employees" datasource="#GetDatasource()#">
			SELECT *
			FROM tblEmployee
			WHERE empEPOS = 'Yes'
			AND empStatus = 'active'
			ORDER BY empFirstName ASC
		</cfquery>

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		
		<cfreturn QueryToArrayOfStruct(loc.employees)>
	</cffunction>
	
	<cffunction name="MonthName" access="public" returntype="string">
		<cfargument name="int" type="numeric" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = "">
		
		<cfswitch expression="#int#">
			<cfcase value="1"><cfset loc.result = "January"></cfcase>
			<cfcase value="2"><cfset loc.result = "Febuary"></cfcase>
			<cfcase value="3"><cfset loc.result = "March"></cfcase>
			<cfcase value="4"><cfset loc.result = "April"></cfcase>
			<cfcase value="5"><cfset loc.result = "May"></cfcase>
			<cfcase value="6"><cfset loc.result = "June"></cfcase>
			<cfcase value="7"><cfset loc.result = "July"></cfcase>
			<cfcase value="8"><cfset loc.result = "August"></cfcase>
			<cfcase value="9"><cfset loc.result = "September"></cfcase>
			<cfcase value="10"><cfset loc.result = "October"></cfcase>
			<cfcase value="11"><cfset loc.result = "November"></cfcase>
			<cfcase value="12"><cfset loc.result = "December"></cfcase>
		</cfswitch>
		
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="ValidateBasket" access="public" returntype="struct">
		<cfargument name="reset" type="boolean" required="no">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
			<cfset loc.result.requiredKeys = this.requiredKeys>
			<cfset loc.result.newBasket = false>
			<cfif reset>	<!--- reset till --->
				<cfset StructDelete(session.epos_frame, "basket")>
			</cfif>
			<cfif NOT StructKeyExists(session.epos_frame, "basket")>
				<cfset StructInsert(session.epos_frame, "basket", {})>
				<!---<cfset LoadDealsIntoSession()>--->
				<cfset loc.result.newBasket = true>
			</cfif>
<!---
				<cfset session.epos_frame.basket = {product = {}, publication = {}, paystation = {}, deal = {}, payment = {}, discount = {}, supplier = {}}>
				<cfset session.epos_frame.basket.account = {credit = 0, cash = 0}>
				<!---<cfset session.epos_frame.header = {}>--->
				<cfset loc.result.newBasket = true>
			<cfelse>
--->
				<cfloop array="#this.requiredKeys#" index="loc.key">
					<cfif NOT StructKeyExists(session.epos_frame.basket, loc.key)>
						<cfset StructInsert(session.epos_frame.basket, loc.key, {})>
					</cfif>
				</cfloop>
				<cfif NOT StructKeyExists(session.epos_frame.basket.account, "credit")>
					<cfset StructInsert(session.epos_frame.basket, "account", {credit = 0, cash = 0},true)>
				</cfif>
			
			<cfcatch type="any">
				<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
			</cfcatch>
		</cftry>
		
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="CleanUpSession" access="public" returntype="void">
		<cftry>
		
		<cfset var loc = {}>
		<cfset loc.result = ValidateBasket(true)>
		
		<!---<cfset loc.requiredKeys = ["product", "publication", "paystation", "deal", "payment", "discount", "supplier"]>
		
		<cfset StructDelete(session.epos_frame, "header")>
		<cfif NOT StructKeyExists(session.epos_frame, "header")>
			<cfset StructInsert(session.epos_frame, "header", {totalDue = 0, cashOnly = 0})>
		</cfif>
		
		<cfset StructDelete(session.epos_frame, "basket")>
		<cfif NOT StructKeyExists(session.epos_frame, "basket")>
			<cfset StructInsert(session.epos_frame, "basket", {})>
		</cfif>
		
		
		<cfloop array="#loc.requiredKeys#" index="loc.key">
			<cfif NOT StructKeyExists(session.epos_frame.basket, loc.key)>
				<cfset StructInsert(session.epos_frame.basket, loc.key, {})>
			</cfif>
		</cfloop>--->

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="GetVersion" access="public" returntype="string">
		<cftry>
		
		<cfreturn "1.0.0.0">

		<cfcatch type="any">
			 <cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="CalculateEasyDateTime" access="public" returntype="string">
		<cfargument name="testDateTime" type="string" required="yes">
		<cfset var result="">
		<cfset var currentDateTime=now()>
		<cfset var difference=DateDiff("s", testDateTime, currentDateTime)>
		<cfif difference gt 0>
			<cfset result="Just now">
		</cfif>
		<cfif difference gt 1>
			<cfset result="1 second ago">
		</cfif>
		<!---SECONDS--->
		<cfif difference gte 2 and difference lte 59>
			<cfset result="#difference# seconds ago">
		</cfif>
		<!---MINUTES--->
		<cfif difference gte 60>
			<cfset result="1 minute ago">
		</cfif>
		<cfif difference gte 120 and difference lte 3599>
			<cfset result="#NumberFormat(difference/60)# minutes ago">
		</cfif>
		<!---HOURS--->
		<cfif difference gte 3600>
			<cfset result="1 hour ago">
		</cfif>
		<cfif difference gte 7200 and difference lte 86399>
			<cfset result="#NumberFormat(difference/3600)# hours ago">
		</cfif>
		<!---DAYS--->
		<cfif difference gte 86400>
			<cfset result="1 day ago">
		</cfif>
		<cfif difference gte 172800 and difference lte 604799>
			<cfset result="#NumberFormat(difference/86400)# days ago">
		</cfif>
		<!---WEEKS--->
		<cfif difference gte 604800>
			<cfset result="1 week ago">
		</cfif>
		<cfif difference gte 1209600 and difference lte 2419199>
			<cfset result="#NumberFormat(difference/604800)# weeks ago">
		</cfif>
		<!---TOO LONG--->
		<cfif difference gte 2419200>
			<cfset result="#DateFormat(testDateTime, 'd mmm YYYY')#">
		</cfif>
		<cfreturn result>
	</cffunction>
</cfcomponent>