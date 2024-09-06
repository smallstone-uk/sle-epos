

<cfcomponent displayname="EPOS15" hint="version 15. EPOS Till Functions">

	<cffunction name="LoadTransaction" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
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
				<cfset loc.result.tranID = loc.QTranResult.generatedKey>
			<cfelse>
				<cfset loc.result.tranID = loc.QTran.trnID>
			</cfif>

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
		<cfdump var="#args#" label="LoadData" expand="false">
		
		<cftry>
			<!--- get the sales data --->
			<cfquery name="loc.QEPOSItems" datasource="#args.datasource#">
				SELECT pcatGroup, prodCatID,prodEposCatID, eiClass,eiType, pgTitle,pgNomGroup, nomID,nomTitle, SUM(eiNet) AS net, SUM(eiVAT) as vat, Count(*) AS itemCount
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
				<cfloop query="loc.QEPOSItems">
					<cfset StructInsert(loc.result.eposData,nomID,{
						"nomTitle" = nomTitle,
						"Net" = net,
						"VAT" = vat,
						"Count" = itemCount
					})>
				</cfloop>
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
					<cfset StructInsert(loc.result.nomItems,nomCode,{
						"nomTitle" = nomTitle,
						"Net" = niAmount,
						"VAT" = niVATAmount
					})>
				</cfloop>			
			</cfif>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

</cfcomponent>