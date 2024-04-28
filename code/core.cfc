<cfcomponent displayname="core">
	<cfset this.salesSections = ["product", "publication", "paystation", "deal", "supplier"]>
	<cfset this.requiredKeys  = ["product", "publication", "paystation", "deal", "supplier", "payment", "discount", "account"]>

	<cffunction name="SearchClients" access="public" returntype="array">
		<cfargument name="keyword" type="string" required="yes">
		<cfset var result=[]>
		<cfset var item={}>
		<cfset var QClients="">

		<cftry>
			<cfquery name="QClients" datasource="#getDatasource()#">
				SELECT * <!--- TODO Add outstanding balance --->
				FROM tblClients,tblStreets2
				WHERE <cfif val(keyword) neq 0>1<cfelse>cltAccountType <> 'N'</cfif>
				AND cltStreetCode=stID
				AND (
				<cfloop list="#keyword#" delimiters=" " index="i">
					<cfif val(keyword) neq 0>
						cltRef=#val(i)# OR
					<cfelse>
						cltName LIKE '%#i#%'
						OR cltCompanyName LIKE '%#i#%'
						OR cltDelHouseName LIKE '%#i#%'
						OR cltDelHouseNumber LIKE '%#i#%'
						OR cltDelTown LIKE '%#i#%'
						OR cltDelCity LIKE '%#i#%'
						OR cltDelPostcode LIKE '%#i#%'
						OR stName LIKE '%#i#%' OR
					</cfif>
				</cfloop>
				cltID=0
				)
				ORDER BY cltRef asc
			</cfquery>
			<cfloop query="QClients">
				<cfset item={}>
				<cfset item.ID=cltID>
				<cfset item.Ref=cltRef>
				<cfif len(cltName) AND len(cltCompanyName)>
					<cfset item.Name="#cltName# #cltCompanyName#">
				<cfelse>
					<cfset item.Name="#cltName##cltCompanyName#">
				</cfif>
				<cfif len(cltDelHouseName) AND len(cltDelHouseNumber)>
					<cfset item.House="#cltDelHouseName#, #cltDelHouseNumber#">
				<cfelse>
					<cfset item.House="#cltDelHouseName##cltDelHouseNumber#">
				</cfif>
				<cfset item.Street="#stName#">
				<!--- TODO Add outstanding balance --->
				<cfset ArrayAppend(result,item)>
			</cfloop>
	
			<cfcatch type="any">
				<cfdump var="#cfcatch#" label="cfcatch" expand="no">
			</cfcatch>
		</cftry>
		
		<cfreturn result>
	</cffunction>
	
	<cffunction name="addToBasket" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cfset loc.result.requiredKeys = this.requiredKeys>
		<cfset loc.result.newBasket = false>
		
		<cfif NOT StructKeyExists(session.epos_frame, "basket")>
			<cfset StructInsert(session.epos_frame, "basket", {})>
			<cfset loc.result.newBasket = true>
		</cfif>
		
		<cfloop array="#this.requiredKeys#" index="loc.key">
			<cfif NOT StructKeyExists(session.epos_frame.basket, loc.key)>
				<cfset StructInsert(session.epos_frame.basket, loc.key, {})>
			</cfif>
		</cfloop>
		
		<cfif NOT StructKeyExists(session.epos_frame.basket.account, "credit")>
			<cfset StructInsert(session.epos_frame.basket, "account", {credit = 0, cash = 0}, true)>
		</cfif>
		
		<cfset loc.index = "#args.id#-#args.price#">
		<cfset loc.barcode = (StructKeyExists(args, "barcode")) ? args.barcode : 0>
		<cfset loc.basketSubType = StructFind(session.epos_frame.basket, args.type)>
		<cfset loc.cashAcc = StructFind(session.epos_frame.basket.account, "cash")>
		<cfset loc.creditAcc = StructFind(session.epos_frame.basket.account, "credit")>
		<cfset loc.sign = (2 * int(session.basket.info.mode neq "rfd")) - 1>	<!--- modes: reg = 1 waste = 1 refund = -1 --->
		
		<cfswitch expression="#args.type#">
			<cfcase value="product|publication|paystation|deal" delimiters="|">
				<cfset args.price = (-val(args.price)) * loc.sign>
			</cfcase>
		</cfswitch>
		
		<cfif NOT StructKeyExists(loc.basketSubType, loc.index)>
			<cfset StructInsert(loc.basketSubType, loc.index, {
				id = args.id,
				index = loc.index,
				title = args.title,
				price = args.price,
				qty = 1,
				grossSaving = 0,
				linetotal = val(args.price),
				barcode = loc.barcode,
				cashonly = args.cashonly,
				timestamp = "#DateFormat(Now(), 'yyyymmdd')##TimeFormat(Now(), 'HHmmss')#"
			})>
		<cfelse>
			<cfset loc.inBasket = StructFind(loc.basketSubType, loc.index)>
			<cfif loc.inBasket.id eq args.id AND loc.inBasket.price eq args.price>
				<cfset loc.inBasket.qty++>
				<cfset loc.inBasket.linetotal = val(loc.inBasket.price) * val(loc.inBasket.qty)>
			</cfif>
		</cfif>
		
		<cfreturn StructFind(session.epos_frame.basket, args.type)>
	</cffunction>
</cfcomponent>
