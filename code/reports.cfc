

<cfcomponent displayname="SalesReports" hint="version 1.0 EPOS Reporting Functions">

	<cffunction name="formatNum" access="public" returntype="string">
		<cfargument name="num" type="numeric" required="yes">
		<cfargument name="style" type="string" required="no" default="">
		<cfif num lt 0>
			<cfif len(style)>
				<cfreturn '<span class="negativeNum">#NumberFormat(num,style)#</span>'>
			<cfelse>
				<cfreturn '<span class="negativeNum">#DecimalFormat(num)#</span>'>			
			</cfif>
		<cfelseif num gt 0>
			<cfif len(style)>
				<cfreturn '<span>#NumberFormat(num,style)#</span>'>
			<cfelse>
				<cfreturn '<span>#DecimalFormat(num)#</span>'>			
			</cfif>
		<cfelse>
			<cfreturn "">	<!--- zero returns blank --->
		</cfif>
	</cffunction>

	<cffunction name="UpdateTransaction" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfargument name="drTotal" type="numeric" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>

		<cftry>
			<cfquery name="loc.QUpdate" datasource="#args.datasource#" result="loc.QQueryResult">
				UPDATE tblTrans
				SET trnAmnt1 = -#val(drTotal)#
				WHERE trnID = #val(args.tranID)#
			</cfquery>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="LoadTransaction" access="public" returntype="numeric">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.tranID = 0>
		<cfset loc.endofDay = DateFormat(DateAdd("d",1,args.form.reportDateFrom),"yyyy-mm-dd")>
		
		<cftry>
			<cfquery name="loc.QTran" datasource="#args.datasource#">
				SELECT trnID
				FROM tblTrans
				WHERE trnDate = '#args.form.reportDateFrom#'
				AND trnLedger = 'sales'
				AND trnAccountID = 1
				AND trnType = 'inv'
				LIMIT 1;
			</cfquery>
			<cfif loc.QTran.recordcount eq 0>
				<!--- not found, create a new transaction --->
				<cfquery name="loc.QTran" datasource="#args.datasource#" result="loc.QTranResult">
					INSERT INTO tblTrans
					(trnLedger,trnAccountID,trnType,trnDate)
					VALUES
					('sales',1,'inv','#args.form.reportDateFrom#')
				</cfquery>
				<cfset loc.tranID = loc.QTranResult.generatedKey>
			<cfelse>
				<cfset loc.tranID = loc.QTran.trnID>
			</cfif>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.tranID>
	</cffunction>

	<cffunction name="FormatDate" returntype="string">
		<cfargument name="dateStr" type="string" required="yes">
		<cfargument name="returnStr" type="string" required="no" default="dd-mmm-yyyy">
		
		<cfset var loc = {}>
		<cfset loc.result = "">
		<!--- <cfset loc.pattern = "^(?:(\d{4})[-\/.](\d{2})[-\/.](\d{2})|(\d{2})[-\/.](\d{2})[-\/.](\d{4}))$">	--->
		<cfset loc.pattern = "^(?:(\d{4})[-\/.](\d{2})[-\/.](\d{2})|(\d{2})[-\/.](\d{2})[-\/.](\d{4})|\{ts '\s*(\d{4})-(\d{2})-(\d{2})\s+\d{2}:\d{2}:\d{2}'\})$">
		<cfset loc.matchGroups = REFind(loc.pattern, dateStr, 1, "TRUE")>
		<cfif ArrayLen(loc.matchGroups.len) gt 1>
			<cfif loc.matchGroups.len[2] GT 0>
				<!--- Format is YYYY-MM-DD --->
				<cfset loc.lyear  = Mid(dateStr, loc.matchGroups.pos[2], loc.matchGroups.len[2])>
				<cfset loc.lmonth = Mid(dateStr, loc.matchGroups.pos[3], loc.matchGroups.len[3])>
				<cfset loc.lday   = Mid(dateStr, loc.matchGroups.pos[4], loc.matchGroups.len[4])>
			<cfelseif loc.matchGroups.len[5] GT 0>
				<!--- Format is DD-MM-YYYY --->
				<cfset loc.lday   = Mid(dateStr, loc.matchGroups.pos[5], loc.matchGroups.len[5])>
				<cfset loc.lmonth = Mid(dateStr, loc.matchGroups.pos[6], loc.matchGroups.len[6])>
				<cfset loc.lyear  = Mid(dateStr, loc.matchGroups.pos[7], loc.matchGroups.len[7])>
			<cfelseif loc.matchGroups.len[8] GT 0>
				<!--- Format is {ts '2025-03-07 00:00:00'} --->
				<cfset loc.lday   = Mid(dateStr, loc.matchGroups.pos[10], loc.matchGroups.len[10])>
				<cfset loc.lmonth = Mid(dateStr, loc.matchGroups.pos[9], loc.matchGroups.len[9])>
				<cfset loc.lyear  = Mid(dateStr, loc.matchGroups.pos[8], loc.matchGroups.len[8])>
			</cfif>
			<cfset loc.dateCheck = loc.lyear & "-" & loc.lmonth & "-" & loc.lday>
			<cfif IsDate(loc.dateCheck)>
				<cfset loc.realDate = CreateDate(loc.lyear,loc.lmonth,loc.lday)>
				<cfset loc.result = LSDateFormat(loc.realDate,returnStr)>
			</cfif>
		</cfif>
		<cfreturn loc.result> 
	</cffunction>

	<cffunction name="LoadEPOSTransactions" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cftry>
			<cfset var loc = {}>
			<cfset loc.result = {}>
			<cfset loc.startDay = FormatDate(args.form.srchDateFrom,"yyyy-mm-dd")>
			<cfset loc.endDay = FormatDate(args.form.srchDateTo,"yyyy-mm-dd")>
			<cfif !IsDate(loc.startDay) OR !IsDate(loc.endDay)>
				<cfreturn {"msg" = "Date range not specified"}>
			</cfif>
			<cfset loc.nextDay = DateAdd("d",1,loc.endDay)>
			<cfset loc.endDay = FormatDate(loc.nextDay,"yyyy-mm-dd")>
			<cfset loc.data = {}>
			<cfset loc.totals = {}>
			<!--- get the sales transactions --->
			<cfquery name="loc.result.QEPOSItems" datasource="#args.datasource#">
				SELECT pgID,pgTitle,pgNomGroup,pgTarget, pcatID,pcatTitle, prodID,prodTitle, eiParent,eiTimeStamp,eiClass,eiType,eiQty,eiNet,eiVAT,eiTrade
				FROM tblEPOS_Items
				INNER JOIN tblEPOS_Header ON ehID = eiParent
				INNER JOIN tblProducts ON prodID = eiProdID
				INNER JOIN tblProductCats ON pcatID = prodCatID
				INNER JOIN tblProductGroups ON pgID = pcatGroup
				WHERE ehTimeStamp > '#loc.startDay#'
				AND ehTimeStamp < '#loc.endDay#'
				AND eiClass = 'sale'
				<cfif len(args.form.reportMode)>AND ehMode = '#args.form.reportMode#'</cfif>
				ORDER BY pgNomGroup, pcatID, prodID, eiTimeStamp ASC
			</cfquery>
			
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="LoadSalesData" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cftry>
			<cfset var loc = {}>
			<cfset loc.result = {}>
			<cfset loc.startDay = FormatDate(args.form.srchDateFrom,"yyyy-mm-dd")>
			<cfset loc.endDay = FormatDate(args.form.srchDateTo,"yyyy-mm-dd")>
			<cfif !IsDate(loc.startDay) OR !IsDate(loc.endDay)>
				<cfreturn {"msg" = "Date range not specified"}>
			</cfif>
			<cfset loc.nextDay = DateAdd("d",1,loc.endDay)>
			<cfset loc.endDay = FormatDate(loc.nextDay,"yyyy-mm-dd")>
			<cfset loc.data = {}>
			<cfset loc.totals = {}>
			<!--- get the sales data --->
			<cfquery name="loc.result.QEPOSItems" datasource="#args.datasource#">
				SELECT pgNomGroup,pgTitle, eiClass,eiType, SUM(eiNet) AS net, SUM(eiVAT) as vat, SUM(eiTrade) AS trade, Count(*) AS itemCount, HOUR(ehTimeStamp) AS theHour
				FROM tblEPOS_Items
				INNER JOIN tblEPOS_Header ON ehID = eiParent
				INNER JOIN tblProducts ON prodID = eiProdID
				INNER JOIN tblProductCats ON pcatID = prodCatID
				INNER JOIN tblProductGroups ON pgID = pcatGroup
				WHERE ehTimeStamp > '#loc.startDay#'
				AND ehTimeStamp < '#loc.endDay#'
				<cfif len(args.form.reportMode)>AND ehMode = '#args.form.reportMode#'</cfif>
				GROUP BY eiClass, pgNomGroup, theHour
			</cfquery>
			<!--- set-up ordered class keys --->
			<cfset loc.classkeys = {
				"sale" = "1sale",
				"item" = "2item",
				"pay" =  "3pay",
				"supp" = "4supp"
			}>
			<!--- create container for hourly totals --->
			<cfset loc.slots = {}>
			<cfloop from="#args.form.srchHourFrom#" to="#args.form.srchHourTo#" index="loc.i">
				<cfset StructInsert(loc.slots,NumberFormat(loc.i,'00'), {
					"Qty" = 0,
					"Net" = 0,
					"VAT" = 0,
					"Trade" = 0
				})>
			</cfloop>
			<!--- create column totals --->
			<cfloop collection="#loc.classkeys#" item="loc.key">
				<cfset StructInsert(loc.totals,loc.key,Duplicate(loc.slots))>
			</cfloop>
			<!--- loop the dataset --->
			<cfif loc.result.QEPOSItems.recordcount gt 0>
				<cfloop query="loc.result.QEPOSItems">
					<cfif theHour lt args.form.srchHourFrom AND theHour gt args.form.srchHourTo>
						<cfset loc.result.errMsg = "Data was found outside of the time parameters. (#currentRow#)">
					<cfelse>
						<cfset loc.classKey = StructFind(loc.classkeys,eiClass)>	<!--- get sorting class --->
						<cfset loc.compKey = "#loc.classKey#-#pgNomGroup#">		<!--- create a sorting key --->
						<cfif !StructKeyExists(loc.data,loc.compKey)>
							<cfset StructInsert(loc.data,loc.compKey, {
								"pgNomGroup" = pgNomGroup,
								"pgTitle" = pgTitle,
								"eiClass" = eiClass,
								"eiType" = eiType,
								"slots" = Duplicate(loc.slots),
								"rowTotalQty" = 0,
								"rowTotalNet" = 0,
								"rowTotalVAT" = 0,
								"rowTotalTrade" = 0
							})>
						</cfif>
						<cfset loc.slot = NumberFormat(theHour,'00')>
						<cfset loc.total = StructFind(loc.totals,eiClass)>
						<cfset loc.group = StructFind(loc.data,loc.compKey)>
						<cfset loc.group.rowTotalQty += itemCount>
						<cfset loc.group.rowTotalNet += Net>
						<cfset loc.group.rowTotalVAT += VAT>
						<cfset loc.group.rowTotalTrade += Trade>
						<cfif StructKeyExists(loc.group.slots,loc.slot)>
							<cfset loc.item = StructFind(loc.group.slots,loc.slot)>
							<cfset loc.item.qty += itemCount>
							<cfset loc.item.Net += Net>
							<cfset loc.item.VAT += VAT>
							<cfset loc.item.Trade += Trade>	
						</cfif>			
						<cfif StructKeyExists(loc.total,loc.slot)>
							<cfset loc.classTotal = StructFind(loc.total,loc.slot)>
							<cfset loc.classTotal.qty += itemCount>
							<cfset loc.classTotal.Net += Net>
							<cfset loc.classTotal.VAT += VAT>
							<cfset loc.classTotal.Trade += Trade>
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
			<cfset loc.result.data = loc.data>
			<cfset loc.result.totals = loc.totals>
			<cfset loc.result.keys = ListSort(StructKeyList(loc.data,","),"text","asc")>
			
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="LoadData" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.endofDay = DateFormat(DateAdd("d",1,args.form.reportDateFrom),"yyyy-mm-dd")>
		
		<cftry>
			<!--- get the sales data --->
			<cfquery name="loc.QEPOSItems" datasource="#args.datasource#">
				SELECT pcatGroup, prodCatID,prodEposCatID, eiClass,eiType, pgTitle,pgNomGroup,pgTarget, nomID,nomCode,nomTitle, SUM(eiNet) AS net, SUM(eiVAT) as vat, 
					SUM(eiTrade) AS trade, Count(*) AS itemCount
				FROM tblEPOS_Items
				INNER JOIN tblEPOS_Header ON ehID = eiParent
				INNER JOIN tblProducts ON prodID = eiProdID
				INNER JOIN tblProductCats ON pcatID = prodCatID
				INNER JOIN tblProductGroups ON pgID = pcatGroup
				INNER JOIN tblNominal ON pgNomGroup = nomCode
				WHERE ehTimeStamp > '#args.form.reportDateFrom#'
				AND ehTimeStamp < '#loc.endofDay#'
				GROUP by pgNomGroup
			</cfquery>
			<cfif loc.QEPOSItems.recordcount gt 0>
				<!--- found EPOS sales data for specified day. Create struct of structs of EPOS data --->
				<cfset loc.result.eposData = {}>
				<cfset loc.result.totals = {}>
				<cfset loc.drTotal = 0>
				<cfset loc.crTotal = 0>
				<cfset loc.vatTotal = 0>
				<cfset loc.result.totals.saletotal = 0>
				<cfset loc.result.totals.drtotal = 0>
				<cfset loc.result.totals.crtotal = 0>
				<cfset loc.result.totals.vattotal = 0>
				<cfset loc.result.totals.tradetotal = 0>
				<cfset loc.result.totals.profittotal = 0>
				
				<cfloop query="loc.QEPOSItems">
					<cfset loc.gross = net + vat>
					<cfset loc.retailPrice = 0>
					<cfset loc.profit = 0>
					<cfset loc.targetPOR = 0>
					<cfset loc.actualProfit = 0>
					<cfset loc.actualPOR = 0>
					<cfset loc.drValue = 0>
					<cfset loc.crValue = 0>
					
					<cfswitch expression="#eiClass#">
						<cfcase value="sale|item" delimiters="|">
							<cfif pgTarget gt 0>
								<cfset loc.retailPrice = 1 + (pgTarget / 100)>
								<cfset loc.profit = loc.retailPrice - 1>
								<cfset loc.targetPOR = int((loc.profit / loc.retailPrice) * 10000) / 100>
								<cfset loc.actualProfit = -(net + trade)>
								<cfif net neq 0>
									<cfset loc.actualPOR = int((loc.actualProfit / -net) * 10000) / 100>
								</cfif>
							</cfif>
							<cfif eiType eq 'VOUCHER'>
								<cfset loc.drValue = loc.gross>
								<cfset loc.drTotal += loc.gross>
								<cfset loc.result.totals.drtotal += loc.drValue>
							<cfelse>
								<cfset loc.crValue = net>
								<cfset loc.vatValue = vat>
								<cfset loc.crTotal -= net>
								<cfset loc.vatTotal -= vat>
								<cfif args.grossMode>
									<cfset loc.crValue = net + vat>
								</cfif>
								<cfset loc.result.totals.crtotal -= loc.crValue>
								<cfset loc.result.totals.vatTotal -= loc.vatValue>
								<cfset loc.result.totals.tradeTotal += trade>
								<cfset loc.result.totals.profittotal += loc.actualProfit>
								<cfif eiClass eq "sale">
									<cfset loc.result.totals.saletotal -= loc.crValue>
								</cfif>
							</cfif>
						</cfcase>
						<cfcase value="pay|supp" delimiters="|">
							<!---<cfif eiType neq 'WASTE'>--->
								<cfset loc.drValue = loc.gross>
								<cfset loc.drTotal += loc.gross>
								<cfset loc.result.totals.drtotal += loc.drValue>
							<!---<cfelse>
								<cfset loc.crValue = loc.gross>
								<cfset loc.crTotal -= loc.gross>
								<cfset loc.result.totals.crtotal += loc.crValue>
							</cfif>--->
						</cfcase>
					</cfswitch>
<!---					
					<cfif Find(eiClass,"supp,pay")>
						<cfif eiType neq 'WASTE'>
							<cfset loc.drValue = loc.gross>
							<cfset loc.drTotal += loc.gross>
							<cfset loc.result.totals.drtotal += loc.drValue>
						<cfelse>
							<cfset loc.crValue = loc.gross>
							<cfset loc.crTotal -= loc.gross>
							<cfset loc.result.totals.crtotal += loc.crValue>
						</cfif>
					<cfelseif Find(eiClass,"sale,item")>
						<cfif pgTarget gt 0>
							<cfset loc.retailPrice = 1 + (pgTarget / 100)>
							<cfset loc.profit = loc.retailPrice - 1>
							<cfset loc.targetPOR = int((loc.profit / loc.retailPrice) * 10000) / 100>
							<cfset loc.actualProfit = -(net + trade)>
							<cfset loc.actualPOR = int((loc.actualProfit / -net) * 10000) / 100>
						</cfif>
						<cfif eiType eq 'VOUCHER'>
							<cfset loc.drValue = loc.gross>
							<cfset loc.drTotal += loc.gross>
							<cfset loc.result.totals.drtotal += loc.drValue>
						<cfelse>
							<cfset loc.crValue = net>
							<cfset loc.vatValue = vat>
							<cfset loc.crTotal -= net>
							<cfset loc.vatTotal -= vat>
							<cfif args.grossMode>
								<cfset loc.crValue = net + vat>
							</cfif>
							<cfset loc.result.totals.crtotal -= loc.crValue>
							<cfset loc.result.totals.vatTotal -= loc.vatValue>
							<cfset loc.result.totals.tradeTotal += trade>
							<cfset loc.result.totals.profittotal += loc.actualProfit>
							<cfif eiClass eq "sale">
								<cfset loc.result.totals.saletotal -= loc.crValue>
							</cfif>
						</cfif>
					</cfif>
					
--->
					<cfset loc.cellClass = "porNone">
					<cfif loc.actualPOR gt loc.targetPOR>
						<cfset loc.cellClass = "porGood">
					<cfelseif loc.actualPOR lt loc.targetPOR AND loc.targetPOR gt 0>
						<cfset loc.cellClass = "porBad">
						<cfif loc.actualPOR gt (loc.targetPOR * 0.9)>
							<cfset loc.cellClass = "porNear">
						</cfif>
					</cfif>
					<cfset StructInsert(loc.result.eposData,nomCode,{
						"nomID" = nomID,
						"nomCode" = nomCode,
						"nomTitle" = nomTitle,
						"pgTitle" = pgTitle,
						"pgNomGroup" = pgNomGroup,
						"pgTarget" = pgTarget,
						"class" = eiClass,
						"net" = net,
						"vat" = vat,
						"gross" = loc.gross,
						"trade" = trade,
						"count" = itemCount,
						"targetPOR" = loc.targetPOR,
						"drValue" = loc.drValue,
						"crValue" = loc.crValue,
						"actualProfit" = loc.actualProfit,
						"actualPOR" = loc.actualPOR,
						"cellClass" = loc.cellClass
					})>
				</cfloop>
			<cfelse>
				<cfset loc.result.errEPOS = "No EPOS sales items found.">		
			</cfif>
			
			<!--- get existing transaction analysis records --->
			<cfquery name="loc.QTranItems" datasource="#args.datasource#">
				SELECT tblNominal.nomCode,tblNominal.nomTitle, tblNomItems.*
				FROM tblNomItems
				INNER JOIN tblNominal ON nomID = niNomID
				WHERE niTranID = #val(args.tranID)#
			</cfquery>
			<cfif loc.QTranItems.recordcount gt 0>
				<cfset loc.result.nomItems = {}>
				<cfloop query="loc.QTranItems">
					<cfif !StructKeyExists(loc.result.nomItems,nomCode)>
						<cfset StructInsert(loc.result.nomItems,nomCode,{
							"niID" = niID,
							"nomTitle" = nomTitle,
							"Net" = niAmount,
							"VAT" = niVATAmount
						})>
					<cfelse>
						<cfoutput>Duplicate: #nomCode#<br></cfoutput>
					</cfif>
				</cfloop>
			<cfelse>
				<cfset loc.result.errTran = "No nominal items found.">		
			</cfif>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

</cfcomponent>