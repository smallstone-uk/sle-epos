

<!--- save daysheet data v3 --->

<cfobject component="code/epos15" name="ecfc">
<cfobject component="code/reports" name="rep">
<cfflush interval="20">
<cfsetting requesttimeout="900">

	<cffunction name="InsertNomItem" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfargument name="epos" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>

		<cftry>
			<cfquery name="loc.QTranItemInsert" datasource="#args.datasource#">
				INSERT INTO tblNomItems
				(niNomID,niTranID,niAmount,niVATAmount) VALUES
				(#epos.nomID#,#args.tranID#,#epos.gross#,0)
			</cfquery>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>
	
	<cffunction name="UpdateNomItem" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfargument name="nom" type="struct" required="yes">
		<cfargument name="newValue" type="numeric" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>

		<cftry>
			<cfquery name="loc.QTranItemUpdate" datasource="#args.datasource#">
				UPDATE tblNomItems
				SET niAmount = #newValue#
				WHERE niID = #nom.niID#
			</cfquery>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="ValidateData" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.data = {}>
		<cftry>
			<cfoutput>
				<cfset loc.drTotal = 0>
				<cfset loc.crTotal = 0>
				<cfset loc.nomTotal = 0>
				<cfset loc.grossTotal = 0>
				<cfset loc.data = rep.LoadData(args)>
				<cfset loc.keys = ListSort(StructKeyList(loc.data.EPOSData,","),"text","asc")>
				<cfif StructKeyExists(loc.data,"nomItems")>
					<table class="tableList" width="400">
						<tr>
							<th colspan="5">Sales Transaction ID: <a href="#application.site.parentURL#salesMain3.cfm?acc=1&tran=#args.tranID#" target="#args.tranID#">#args.tranID#</a></th>
						</tr>
						<tr>
							<th>Key</th><th align="right">EPOS Value</th><th align="right">Nom Value</th><th align="right">Diff</th><th>Status</th>
						</tr>
						<cfloop list="#loc.keys#" index="loc.key" delimiters=",">
							<cfif StructKeyExists(loc.data.EPOSData,loc.key)>
								<cfset loc.epos = StructFind(loc.data.EPOSData,loc.key)>
								<cfset loc.drTotal += loc.epos.drValue>
								<cfset loc.crTotal += loc.epos.crValue>
								<cfset loc.value = Iif(loc.epos.crValue neq 0,loc.epos.crValue,loc.epos.drValue)>
								<cfset loc.grossTotal += loc.value>
								<cfif StructKeyExists(loc.data.nomItems,loc.key)>
									<cfset loc.nom = StructFind(loc.data.nomItems,loc.key)>
									<cfset loc.nomTotal += loc.nom.net>
									<cfset loc.diff = loc.value - loc.nom.net>
									<tr>
										<cfif abs(loc.diff) gte 0.01>
											<cfset UpdateNomItem(parm,loc.nom,loc.value)>
											<td>#loc.key#</td><td align="right">#loc.value#</td><td align="right">#loc.nom.net#</td><td align="right">#loc.diff#</td><td align="center">NEQ</td>
										<cfelse>
											<td>#loc.key#</td><td align="right">#loc.value#</td><td align="right">#loc.nom.net#</td><td align="right">#loc.diff#</td><td align="center">OK</td>
										</cfif>
									</tr>
								<cfelse>
									<!--- add new entry --->
									<cfset InsertNomItem(parm,loc.epos)>
									<tr>
										<td>#loc.key#</td><td align="right">#loc.value#</td><td align="right"></td><td align="right"></td><td align="center">Added</td>
									</tr>
								</cfif>
							</cfif>
						</cfloop>
						<cfif abs(loc.grossTotal) lte 0.01><cfset loc.grossTotal = 0></cfif>
						<cfif abs(loc.nomTotal) lte 0.01><cfset loc.nomTotal = 0></cfif>
						<tr>
							<th>Totals</th>
							<th align="right">#loc.grossTotal#</th>
							<th align="right">#loc.nomTotal#</th>
							<th></th>
							<th></th>
						</tr>
					</table>
				<cfelse>
					<cfset loc.lfcr = "#chr(13)##chr(10)#">
					<cfset loc.str = "">
					<cfset loc.dl = ",">
					<cfset loc.str = "#loc.str#INSERT INTO tblNomItems#loc.lfcr#">
					<cfset loc.str = "#loc.str#(niNomID,niTranID,niAmount,niVATAmount) VALUES#loc.lfcr#">
					<table class="tableList" width="400">
						<tr>
							<th colspan="5">Transaction ID: <a href="#application.site.parentURL#salesMain3.cfm?acc=1&tran=#args.tranID#" target="#args.tranID#">#args.tranID#</a></th>
						</tr>
						<tr>
							<th>Key</th><th align="right">EPOS Value</th><th align="right">Nom Value</th><th align="right">Diff</th><th>Status</th>
						</tr>
						<cfloop list="#loc.keys#" index="loc.key" delimiters=",">
							<cfif StructKeyExists(loc.data.EPOSData,loc.key)>
								<cfset loc.epos = StructFind(loc.data.EPOSData,loc.key)>
								<cfset loc.str = "#loc.str#(#loc.epos.nomID#,#args.tranID#,#loc.epos.gross#,0)#loc.dl##loc.lfcr#">
								<cfset loc.drTotal += loc.epos.drValue>
								<tr>
									<td>#loc.key#</td><td align="right">#loc.epos.gross#</td>
								</tr>
							</cfif>
						</cfloop>
						<tr>
							<th>Totals</th>
							<th align="right">#loc.grossTotal#</th>
							<th align="right">#loc.nomTotal#</th>
							<th></th>
							<th></th>
						</tr>
					</table>
					<cfset loc.str = RemoveChars(loc.str,len(loc.str)-2,1)>
					<cfquery name="loc.QTranItemInsert" datasource="#args.datasource#">
						#loc.str#
					</cfquery>
				</cfif>
				<cfset loc.tranUpdate = rep.UpdateTransaction(args,loc.drTotal)>
			</cfoutput>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

<cfoutput>
	<cfset parm = {}>
	<cfset parm.form = form>
	<cfset parm.datasource = application.site.datasource1>
	<cfset parm.url = application.site.normal>
	<cfset parm.grossMode = StructKeyExists(form,"grossMode")>
	<cfif StructKeyExists(form,"reportDateFrom")>
		<cfset parm.reportDateFrom = reportDateFrom>
	<cfelseif StructKeyExists(session,"till")>
		<cfset parm.reportDateFrom = session.till.prefs.reportDate>
	<cfelse>
		<cfset parm.reportDateFrom = Now()>
	</cfif>
	<cfset parm.reportDateTo = Now()>
	<cfset parm.tranID = rep.LoadTransaction(parm)>
	<cfset result = ValidateData(parm)>
</cfoutput>