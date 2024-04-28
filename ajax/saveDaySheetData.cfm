<!--- saveDaySheetData --->

checking data...
<cfdump var="#form#" label="form" expand="true">

	<cffunction name="LoadSalesData" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset loc = {}>
		<cfset loc.result = {}>
		<cfset loc.endofDay = DateFormat(DateAdd("d",1,args.form.reportDateFrom),"yyyy-mm-dd")>
		
		<!--- check for existing sales transaction --->
		<cfquery name="loc.QTran" datasource="#args.datasource#">
			SELECT trnID
			FROM tblTrans
			WHERE trnDate = '#args.form.reportDateFrom#'
			AND trnLedger = 'sales'
			AND trnAccountID = 1
			AND trnType = 'inv'
			LIMIT 1;
		</cfquery>
		<cfif loc.QTran.recordcount eq 1>
			<!--- found it --->
			<cfset loc.tranID = loc.QTran.trnID>
		<cfelse>
			<!--- create a new transaction --->
			<cfquery name="loc.QTran" datasource="#args.datasource#" result="loc.QTranResult">
				INSERT INTO tblTrans
				(trnLedger,trnAccountID,trnType,trnDate)
				VALUES
				('sales',1,'inv','#args.form.reportDateFrom#')
			</cfquery>
			<cfset loc.tranID = loc.QTranResult.generatedKey>
			<cfquery name="loc.QTran" datasource="#args.datasource#">
				SELECT trnID
				FROM tblTrans
				WHERE trnID = #loc.tranID#
				LIMIT 1;
			</cfquery>
		</cfif>

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
			<!--- found EPOS sales data for specified day --->
			<!--- create struct of structs of EPOS data --->
			<cfset loc.eposData = {}>
			<cfloop query="loc.QEPOSItems">
				<cfset StructInsert(loc.eposData,nomID,{
					"nomTitle" = nomTitle,
					"Net" = net,
					"VAT" = vat,
					"Count" = itemCount
				})>
			</cfloop>
			
			<!--- get existing transaction analysis records --->
			<cfquery name="loc.QTranItems" datasource="#args.datasource#">
				SELECT tblNominal.nomCode, tblNomItems.*
				FROM tblNomItems
				INNER JOIN tblNominal ON nomID = niNomID
				WHERE niTranID = #val(loc.tranID)#
			</cfquery>
			<cfif loc.QTranItems.recordcount gt 0>
				<!--- found them --->
				<cfoutput>
					found tran items...<br />
					<cfset loc.cr = 0>
					<cfset loc.dr = 0>
					<cfset loc.vat = 0>
					<table width="400">
					<cfloop query="loc.QTranItems">
						<tr>
							<td>#niID#</td><td>#niNomID#</td><td>#nomCode#</td><td> #niAmount#</td><td> #niVATAmount#</td>
							<cfset loc.data = StructFind(loc.eposData,niNomID)>
							<cfif loc.data.net neq niAmount OR loc.data.vat neq niVATAmount>
								<td>unmatched</td>
							<cfelse>
								<td>match</td>
							</cfif>
						</tr>
						<cfif niAmount lte 0>
							<cfset loc.cr += (niAmount + niVATAmount)>
						<cfelse>
							<cfset loc.dr += (niAmount + niVATAmount)>
						</cfif>
						<cfset loc.vat += niVATAmount>
					</cfloop>
					</table>
				</cfoutput>					
			<cfelse>
				<cfoutput>
					<cfset loc.cr = 0>
					<cfset loc.dr = 0>
					<cfset loc.vat = 0>
					<cfset loc.lfcr = "#chr(13)##chr(10)#">
					<cfset loc.str = "">	
					<cfset loc.str = "#loc.str#INSERT INTO tblNomItems#loc.lfcr#">
					<cfset loc.str = "#loc.str#(niNomID,niTranID,niAmount,niVATAmount) VALUES#loc.lfcr#">
					<cfset loc.checkTotal = 0>
					<cfloop query="loc.QEPOSItems">
						<cfif currentrow lt loc.QEPOSItems.recordcount><cfset loc.dl = ","><cfelse><cfset loc.dl = ""></cfif>
						<cfset loc.str = "#loc.str#(#nomID#,#loc.tranID#,#net#,#vat#)#loc.dl##loc.lfcr#">
						<cfset loc.checkTotal += (net + vat)>check: #loc.checkTotal#<br>
						<cfif net lte 0>
							<cfset loc.cr += (net + vat)>
						<cfelse>
							<cfset loc.dr += (net + vat)>
						</cfif>
						<cfset loc.vat += vat>
					</cfloop>
					<cfif abs(loc.checkTotal) lte 0.01><cfset loc.checkTotal = 0></cfif>
					checkTotal #loc.checkTotal#<br>
					#loc.str#
					<cfquery name="loc.QTranItemInsert" datasource="#args.datasource#">
						#loc.str#
					</cfquery>
					<cfquery name="loc.QTranItems" datasource="#args.datasource#">
						SELECT tblNominal.nomCode, tblNomItems.*
						FROM tblNomItems
						INNER JOIN tblNominal ON nomID = niNomID
						WHERE niTranID = #val(loc.tranID)#
					</cfquery>
				</cfoutput>					
				<cfquery name="loc.QTranUpdate" datasource="#args.datasource#">
					UPDATE tblTrans
					SET trnAmnt1 = #loc.cr#,
						trnAmnt2 = #loc.vat#
					WHERE trnID = #val(loc.tranID)#
				</cfquery>
			</cfif>
		</cfif>
		<cfquery name="loc.QTran" datasource="#args.datasource#">
			SELECT *
			FROM tblTrans
			WHERE trnID = #loc.tranID#
			LIMIT 1;
		</cfquery>
		<cfdump var="#loc#" label="loc" expand="true">
		<cfreturn loc.result>
	</cffunction>
	
	<cfset parm = {}>
	<cfset parm.datasource = application.site.datasource1>
	<cfset parm.form = form>
	<cfset data = LoadSalesData(parm)>
	<!---<cfdump var="#data#" label="data" expand="true">--->