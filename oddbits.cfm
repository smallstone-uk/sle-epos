	<cffunction name="CheckDealsyy" access="public" returntype="void" hint="check basket for qualifying deals.">
		<cftry>
			<cfset var loc = {}>
			<cfloop collection="#session.basket.prodKeys#" item="loc.key">
				<cfset loc.item = StructFind(session.basket.prodKeys,loc.key)>
				<cfset loc.item.retail = loc.item.qty * loc.item.unitPrice>
				<cfloop collection="#session.basket.deals#" item="loc.dealKey">
					<cfset loc.dealData = StructFind(session.dealData,loc.dealKey)>
					<cfset loc.dealRec = StructFind(session.basket.deals,loc.dealKey)>
					<cfset ArraySort(loc.dealRec.prices,"text","ASC")>	<!--- change to DESC to optimise for customer --->
					<!---<cfset loc.dealRec.retail = 0>--->
					<cfset loc.dealRec.netTotal = 0>
					<cfset loc.dealRec.dealCount = 0>
					<cfset loc.dealRec.dealTotal = 0>
					<cfset loc.dealRec.totalCharge = 0>
					<cfset loc.dealRec.savingGross = 0>
					<cfset loc.dealRec.groupRetail = 0>
					<cfset loc.dealRec.VAT = {}>
					<cfset loc.dealRec.itemCount = 0>
					<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
						<cfset loc.dealRec.itemCount++>
						<cfset loc.price = ListFirst(loc.priceKey," ")>
						<cfset loc.prodID = ListLast(loc.priceKey," ")>
						<cfset loc.item = StructFind(session.basket.prodKeys,loc.prodID)>
						<cfset loc.style = "blue">
						<cfset loc.dealRec.retail += loc.price>
						<cfset loc.net = loc.price / (1 + (loc.item.vrate /100))>
						<cfset loc.dealRec.netTotal += loc.net>
						<cfif NOT StructKeyExists(loc.dealRec.VAT,loc.item.vrate)>
							<cfset StructInsert(loc.dealRec.VAT,loc.item.vrate,loc.net)>
						<cfelse>
							<cfset loc.vatRec = StructFind(loc.dealRec.VAT,loc.item.vrate)>
							<cfset StructUpdate(loc.dealRec.VAT,loc.item.vrate,loc.vatRec + loc.net)>
						</cfif>
						<cfset loc.dealRec.groupRetail += loc.price>
						<cfif loc.dealData.edEnds gt Now()>
							<cfif loc.dealRec.itemCount MOD loc.dealData.edQty eq 0>
								<cfset loc.dealRec.dealCount++>
								<cfset loc.style = "red">
								<cfswitch expression="#loc.dealData.edDealType#">
									<cfcase value="anyfor">
										<cfset loc.dealRec.dealTotal = loc.dealRec.dealCount * loc.dealData.edAmount>
										<cfset loc.item.dealTitle = "#loc.dealData.edTitle# &pound;#DecimalFormat(loc.dealData.edAmount)#">
									</cfcase>
									<cfcase value="twofor">
										<cfset loc.dealRec.dealCount = int(loc.dealRec.itemCount / 2)>
										<cfset loc.dealRec.remQty = loc.dealRec.itemCount mod 2>
										<cfset loc.dealRec.dealTotal = loc.dealRec.dealCount * loc.dealData.edAmount + (loc.dealRec.remQty * loc.price)>
										<cfset loc.item.dealTitle = "#loc.dealData.edTitle# &pound;#DecimalFormat(loc.dealData.edAmount)#">
									</cfcase>
									<cfcase value="bogof">
										<cfset loc.dealRec.dealCount = int(loc.dealRec.itemCount / 2)>
										<cfset loc.dealRec.remQty = loc.dealRec.itemCount mod 2>
										<cfset loc.dealRec.dealTotal = (loc.dealRec.dealCount * loc.price) + (loc.dealRec.remQty * loc.price)>
										<cfset loc.item.dealTitle = loc.dealData.edTitle>
									</cfcase>
								</cfswitch>
								<cfset loc.dealRec.groupRetail = 0>
							</cfif>
						</cfif>
						<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
						<cfset loc.dealRec.savingGross = loc.dealRec.totalCharge - loc.dealRec.retail>
					</cfloop>
					<cfset loc.dealRec.savingNet = 0>
					<cfset loc.dealRec.savingVAT = 0>
					<cfloop collection="#loc.dealRec.VAT#" item="loc.vatKey">
						<cfset loc.netAmnt = StructFind(loc.dealRec.VAT,loc.vatKey)>
						<cfset loc.prop = loc.netAmnt / loc.dealRec.netTotal>
						<cfset loc.dealRec.savingNet += (loc.dealRec.savingGross * loc.prop) / (1 + (loc.vatKey /100))>
					</cfloop>
					<cfset loc.dealRec.savingVAT += loc.dealRec.savingGross - loc.dealRec.savingNet>
				</cfloop>
			</cfloop>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="" expand="yes" format="html" 
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

<!---
			<cfif loc.deal.edDealType eq "anyfor">
				<cfloop collection="#session.basket.deals#" item="loc.key">
					<cfset loc.dealRec = StructFind(session.basket.deals,loc.key)>
					<cfset loc.deal = StructFind(session.dealdata,loc.item.dealID)>
					<cfset ArraySort(loc.dealRec.prices,"text","ASC")>
					<cfset loc.count = 0>
					<cfset loc.saving = 0>
					<cfset loc.lastProd = 0>
					<cfset loc.value = 0>
					<cfloop array="#loc.dealRec.prices#" index="loc.price">
						<cfset loc.count++>
						<cfset loc.prodID = ListLast(loc.price," ")>
						<cfset loc.item = StructFind(session.basket.prodKeys,loc.prodID)>
						<cfset loc.value += loc.item.unitPrice>
						<cfif loc.count MOD loc.deal.edQty eq 0>
							<cfset loc.saving += (loc.value - loc.deal.edAmount)>
							<cfdump var="#loc#" label="deal #loc.price#" expand="no">
							<cfset loc.value = 0>
						</cfif>
						<cfset loc.lastProd = loc.prodID>
					</cfloop>
				</cfloop>
				<!--- last item on deal --->
				<cfset loc.item.totalGross = loc.dealRec.retail - loc.saving>
				<cfset loc.item.totalNet = loc.item.totalGross / loc.item.vatRate>
				<cfset loc.item.totalVAT = loc.item.totalGross - loc.item.totalNet>
			</cfif>
--->			


	<cffunction name="CheckDealsXX" access="public" returntype="void" hint="check basket for qualifying deals.">
		<cfset var loc = {}>

		<cftry>
			<cfset loc.regMode = (2 * int(session.basket.info.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
			<cfset loc.calcValue = true>
			<cfset loc.tranType = -1>
			<cfset session.basket.deals = {}>
			<cfloop collection="#session.basket.prodKeys#" item="loc.key">
				<cfset loc.item = StructFind(session.basket.prodKeys,loc.key)>
				<cfset loc.item.dealQty = 0>
				<cfset loc.item.dealTitle = ''>
				<cfset loc.item.dealTotal = 0>
				<cfset loc.item.discount = 0>
				<cfset loc.item.remQty = 0>
				<cfset loc.item.vatRate = 1 + (val(loc.item.vrate) / 100)>
				<cfset loc.item.retail = loc.item.qty * loc.item.unitPrice>
				<cfif loc.item.dealID gt 0>
					<cfset loc.deal = StructFind(session.dealdata,loc.item.dealID)>
					<cfif loc.item.qty gte loc.deal.edQty OR loc.deal.edDealType eq "anyfor">	<!--- eeewww --->
						<!---<cfset loc.item.dealQty = loc.deal.edQty>--->
						<cfset loc.item.edAmount = loc.deal.edAmount>
						<cfset loc.item.discountable = false>
						<cfswitch expression="#loc.deal.edDealType#">
							<cfcase value="bogof">
								<cfset loc.item.dealQty = int(loc.item.qty / 2)>
								<cfset loc.item.remQty = loc.item.qty mod 2>
								<cfset loc.item.dealTitle = loc.deal.edTitle>
								<cfset loc.item.dealTotal = loc.item.dealQty * loc.item.unitPrice>
								<cfset loc.item.totalGross = loc.item.dealTotal + (loc.item.remQty * loc.item.unitPrice)>
							</cfcase>
							<cfcase value="twofor">
								<cfset loc.item.dealQty = int(loc.item.qty / 2)>
								<cfset loc.item.remQty = loc.item.qty mod 2>
								<cfset loc.item.dealTitle = "#loc.deal.edTitle# &pound;#loc.deal.edAmount#">
								<cfset loc.item.totalGross = loc.item.dealQty * loc.deal.edAmount + (loc.item.remQty * loc.item.unitPrice)>
								<cfset loc.item.dealTotal = loc.item.retail - loc.item.totalGross>
							</cfcase>
							<cfcase value="anyfor">
								<cfset loc.calcValue = false>
								<cfset loc.item.retail = 0>
								<cfif StructKeyExists(session.basket.deals,loc.item.dealID)>
									<cfset loc.dealRec = StructFind(session.basket.deals,loc.item.dealID)>
								<cfelse>
									<cfset loc.dealRec = {}>
									<cfset loc.dealRec.prices = []>
									<cfset loc.dealRec.count = 0>
									<cfset loc.dealRec.retail = 0>
									<cfset StructInsert(session.basket.deals,loc.item.dealID,loc.dealRec)>
								</cfif>
								<cfset loc.dealRec.count += loc.item.qty>
								<cfset loc.dealRec.dealQty = int(loc.dealRec.count / loc.deal.edQty)>
								<cfset loc.dealRec.remQty = loc.dealRec.count mod loc.deal.edQty>
								<cfset loc.dealRec.dealPrice = loc.dealRec.dealQty * loc.deal.edAmount>
								<cfset loc.dealRec.retail += (loc.item.qty * loc.item.unitPrice)>
								<cfset loc.dealRec.dealTitle = "#loc.deal.edTitle# &pound;#loc.deal.edAmount#">
								<cfloop from="1" to="#loc.item.qty#" index="loc.i">
									<cfset ArrayAppend(loc.dealRec.prices,loc.item.unitPrice)>
								</cfloop>
								<cfset loc.dealRec.lastProd = loc.key>
								<cfset StructUpdate(session.basket.deals,loc.item.dealID,loc.dealRec)>
							</cfcase>
							<cfcase value="mealdeal">
							</cfcase>
							<cfcase value="halfprice">
							</cfcase>
							<cfcase value="nodeal">
							</cfcase>
							<cfdefaultcase>
							</cfdefaultcase>
						</cfswitch>
					<cfelse>
						<cfset loc.item.dealTitle = "">
						<cfset loc.item.dealQty = "">
						<cfset loc.item.dealTotal = 0>
					</cfif>
				</cfif>
				<cfif loc.item.dealTotal eq 0>
					<cfset loc.item.totalGross = loc.item.qty * loc.item.unitPrice>
					<cfif session.basket.info.staff AND loc.item.discountable>	<!--- staff sale and is a discountable item --->
						<cfset loc.item.discount = round(loc.item.retail * 100 * session.till.prefs.discount) / 100>	<!--- item discount in pence --->
						<cfset loc.item.totalGross -= loc.item.discount>
					</cfif>	
				</cfif>
				<cfif loc.calcValue>
					<cfset loc.item.totalNet = loc.item.totalGross / loc.item.vatRate>
					<cfset loc.item.totalVAT = loc.item.totalGross - loc.item.totalNet>
					
					<cfset loc.item.retail = loc.item.retail * loc.regMode * loc.tranType>
					<cfset loc.item.totalGross = loc.item.totalGross * loc.regMode * loc.tranType>
					<cfset loc.item.totalNet = loc.item.totalNet * loc.regMode * loc.tranType>
					<cfset loc.item.totalVAT = loc.item.totalVAT * loc.regMode * loc.tranType>
					<cfif loc.item.cashOnly>
						<cfset loc.item.cash = loc.item.totalGross>
					<cfelse>
						<cfset loc.item.credit = loc.item.totalGross>
					</cfif>
				</cfif>
			</cfloop>
<!---
			<cfif NOT StructIsEmpty(session.basket.deals)>
				<cfloop collection="#session.basket.deals#" item="loc.key">
					<cfset loc.dealRec = StructFind(session.basket.deals,loc.key)>
					<cfset ArraySort(loc.dealRec.prices,"numeric","asc")>
					<cfset loc.dealRec.lastItem = loc.dealRec.dealQty * loc.deal.edQty>
					<cfif loc.dealRec.lastItem lte ArrayLen(loc.dealRec.prices)>
						<cfset loc.dealRec.value = 0>
						<cfloop from="1" to="#loc.dealRec.lastItem#" index="loc.price">
							<cfset loc.dealRec.value += loc.dealRec.prices[loc.price]>
						</cfloop>
					</cfif>
					<cfif loc.dealRec.dealQty gt 0>
						<cfset loc.item = StructFind(session.basket.prodKeys,loc.dealRec.lastProd)>
						<cfset loc.item.dealTitle = loc.dealRec.dealTitle>
						<cfset loc.item.dealQty = loc.dealRec.dealQty>
						<cfset loc.item.dealTotal = loc.dealRec.retail - loc.dealRec.dealPrice>
						<cfset loc.item.totalGross = loc.item.dealQty * loc.deal.edAmount + (loc.item.remQty * loc.item.unitPrice)>
						<cfset loc.item.dealTotal = loc.dealRec.value - loc.dealRec.dealPrice>
						<!--- update last product in deal set --->
						<cfset loc.item.totalNet = loc.item.totalGross / loc.item.vatRate>
						<cfset loc.item.totalVAT = loc.item.totalGross - loc.item.totalNet>

						<cfset loc.item.totalGross = loc.item.totalGross * loc.regMode * loc.tranType>
						<cfset loc.item.totalNet = loc.item.totalNet * loc.regMode * loc.tranType>
						<cfset loc.item.totalVAT = loc.item.totalVAT * loc.regMode * loc.tranType>
						<cfif loc.item.cashOnly>
							<cfset loc.item.cash = loc.item.totalGross>
						<cfelse>
							<cfset loc.item.credit = loc.item.totalGross>
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
--->
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="CheckDeals" expand="yes" format="html" 
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>


		<!---
			PARAMETER(S):
				0: STRING - the var expected is one of these (x,y,z)
				1: SCALAR - the var expected is one of these (1,2,3,4)
				2: BOOLEAN - the var expected is one of these (true, false)
				3: ARRAY - array in the format [x,y,z,n]
				4: OBJECT - object in the format (date, time, query)
			
			args.form - the form posted from the till
			args.form.account - used to assign a basket payment to a selected customer account (Timmy,Owners,etc)
			args.form.AddToBasket - assume selected product is to be added unless it already exists in the basket
			args.form.btnSend - the function to call
			args.form.cash - cash value of transaction.
			args.form.cashonly - a flag passed from the products table
			args.form.credit credit value of transaction (most products are these)
			args.form.prodTitle - the product title for display
			args.form.qty - qty required (usually 1) can be negative to reduce basket quantity
			args.form.type - the product type followed by the product ID
			args.form.vrate - the VAT rate passed from the products table
			
			The following fields are added to the form:-
			args.form.prodID - the ure product record ID
			args.form.type - converted from its complex value to "SALE" if it was a product
			args.form.class - transaction type "item" or "payment"
			args.form.discount - amount of discount allowed. Always set to zero until later
			args.form.vcode - stores the related VAT code based on the rate passed in
			args.form.title - an alternative title to the product title
			args.form.gross - gross value of product including VAT. Usually this is the same as the retail value
			session.basket.bod - used as title in the receipt "customer" or "supplier"
		---->

<!---
		<cfset session.basket.received = session.basket.header.cashtaken + session.basket.total.cardINDW + 
			session.basket.total.chqINDW>
		<cfset session.basket.items = ArrayLen(session.basket.products) + ArrayLen(session.basket.suppliers) + 
			ArrayLen(session.basket.prizes) + ArrayLen(session.basket.vouchers) + ArrayLen(session.basket.news)>
--->
