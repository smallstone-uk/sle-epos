

<cfcomponent displayname="SalesReports" hint="version 1.0 EPOS Reporting Functions">

	<cffunction name="UpdateTransaction" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfargument name="drTotal" type="numeric" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>

		<cftry>
			<cfquery name="loc.QUpdate" datasource="#args.datasource#" result="loc.QQueryResult">
				UPDATE tblTrans
				SET trnAmnt1 = #val(drTotal)#
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

	<cffunction name="LoadData" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.endofDay = DateFormat(DateAdd("d",1,args.form.reportDateFrom),"yyyy-mm-dd")>
		
		<cftry>
			<!--- get the sales data --->
			<cfquery name="loc.QEPOSItems" datasource="#args.datasource#">
				SELECT pcatGroup, prodCatID,prodEposCatID, eiClass,eiType, pgTitle,pgNomGroup,pgTarget, nomID,nomCode,nomTitle, SUM(eiNet) AS net, SUM(eiVAT) as vat, SUM(eiTrade) AS trade, Count(*) AS itemCount
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