
<!---
	VERSION 15a
	1.	Stores products and services correctly.
	2.	Process deals correctly.
	3.	No rounding issues when writing data.
	4.	Writes transactions and till totals correctly.
	5.	Refund mode reverses transactions without rounding errors.
--->

<cfcomponent displayname="EPOS" hint="version 15. EPOS Till Functions">

	<cffunction name="GetDataSource" access="public" returntype="string">
		<cfreturn application.site.datasource1>
	</cffunction>

	<cffunction name="ZTill" access="public" returntype="void" hint="initialise till at start of day.">
		<cfargument name="loadDate" type="date" required="yes">
		<cfset StructDelete(session,"till",false)>
		<cfset session.till = {}>

		<cfset session.till.isTranOpen = true>	<!---Transaction in progress flag--->

		<cfset session.till.total = {}>
		<cfset session.till.header = {}>
		<cfset session.till.info = {}>
		<cfset session.till.prevtran = {}>
		<cfset session.till.catKeys = []>
		<cfset session.till.total.float = -200>
		<cfset session.till.total.cashINDW = 200>
		<cfset session.till.prefs.mincard = 3.00>
		<cfset session.till.prefs.service = 0.50>
		<cfset session.till.prefs.discount = 0.10>
		<cfset session.till.prefs.reportDate = LSDateFormat(loadDate,"yyyy-mm-dd")>
		<cfif StructKeyExists(application,"siteclient")>
			<cfset session.till.prefs.vatno = application.siteclient.cltvatno>
		<cfelse>
			<cfset session.till.prefs.vatno = "152 5803 21">
		</cfif>
		<cfset session.till.prefs.started = Now()>
		<cfset ClearBasket()>
	</cffunction>

	<cffunction name="ClearBasket" access="public" returntype="void" hint="clear current transaction without affecting till totals.">
		<cfset StructDelete(session,"basket",false)>
		<cfset session.basket = {}>
		<cfset session.basket.deals = {}>
		<cfset session.basket.header = {}>
		<cfset session.basket.total = {}>
		<cfset session.basket.info = {}>
      	<cfset session.basket.shopItems = {}>
      	<cfset session.basket.mediaItems = {}>
		<cfset LoadCatKeys()>

		<cfset session.basket.info.mode = "reg">
		<cfset session.basket.info.type = "SALE">
		<cfset session.basket.info.bod = "Customer">
		<cfset session.basket.info.service = 0>
		<cfset session.basket.info.errMsg = "">
		<cfset session.basket.info.itemcount = 0>
		<cfset session.basket.info.totaldue = 0>
		<cfset session.till.info.staff = false>

		<cfset session.basket.payments = []>
		<cfset session.basket.news = []>
		<cfset session.basket.vatAnalysis = {}>
<!---
		<cfset session.basket.header.aRetail = 0>
		<cfset session.basket.header.aNet = 0>
		<cfset session.basket.header.aDiscDeal = 0>
		<cfset session.basket.header.aDiscStaff = 0>
		<cfset session.basket.header.bNews = 0>
		<cfset session.basket.header.bMedia = 0>
		<cfset session.basket.header.cAcct = 0>
		<cfset session.basket.header.cPaypoint = 0>
		<cfset session.basket.header.cLottery = 0>
		<cfset session.basket.total.cashback = 0>
		<cfset session.basket.header.supplies = 0>
		<cfset session.basket.total.supplies = 0>
		<cfset session.basket.header.change = 0>
--->

		<cfset session.basket.header.aVAT = 0>
		<cfset session.basket.header.bCash = 0>
		<cfset session.basket.header.bCredit = 0>
		<cfset session.basket.header.Prize = 0>
		<cfset session.basket.header.vchn = 0>
		<cfset session.basket.header.cpn = 0>

		<cfset session.basket.header.cashtaken = 0>
		<cfset session.basket.header.cardsales = 0>
		<cfset session.basket.header.chqsales = 0>
		<cfset session.basket.header.accsales = 0>
		<cfset session.basket.header.discdeal = 0>
		<cfset session.basket.header.discstaff = 0>
		<cfset session.basket.header.cashback = 0>
		<cfset session.basket.header.balance = 0>

		<cfset session.basket.total.chqINDW = 0>
		<cfset session.basket.total.accINDW = 0>
		<cfset session.basket.total.balance = 0>
		<cfset session.basket.total.discount = 0>
		<cfset session.basket.total.discstaff = 0>
	</cffunction>

	<cffunction name="ProcessDeals" access="public" returntype="void">
		<cfset var loc = {}>
		<cfset loc.rec.regMode = (2 * int(session.basket.info.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
		<cftry>
			<cfloop collection="#session.basket.deals#" item="loc.dealKey">
				<cfset loc.dealData = StructFind(session.dealData,loc.dealKey)>
				<cfset loc.dealRec = StructFind(session.basket.deals,loc.dealKey)>
				<cfset ArraySort(loc.dealRec.prices,"text","ASC")>	<!--- use DESC to optimise for customer --->
				<cfset loc.dealRec.VATTable = {}>
				<cfset loc.dealRec.dealQty = 0>
				<cfset loc.dealRec.netTotal = 0>
				<cfset loc.dealRec.dealTotal = 0>
				<cfset loc.dealRec.groupRetail = 0>
				<cfset loc.dealRec.savingGross = 0>
				<cfset loc.dealRec.lastQual = 0>
				<cfset loc.dealRec.remQty = 0>
				<cfset loc.count = 0>
				<cfswitch expression="#loc.dealData.edDealType#">

					<cfcase value="anyfor">
						<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
							<cfset loc.count++>
							<cfset loc.price = ListFirst(loc.priceKey," ")>
							<cfset loc.prodID = ListLast(loc.priceKey," ")>
							<cfset loc.data = StructFind(session.basket.shopItems,loc.prodID)>
							<cfset loc.data.discount = 0>
							<cfset loc.dealRec.groupRetail += loc.price>
							<cfif NOT StructKeyExists(loc.dealRec.VATTable,loc.data.vcode)>
								<cfset loc.prop = loc.price / loc.dealRec.retail>
								<cfset StructInsert(loc.dealRec.VATTable,loc.data.vcode,{"rate" = loc.data.vrate, "gross" = loc.price * 1, "prop" = loc.prop})>
							<cfelse>
								<cfset loc.vatRec = StructFind(loc.dealRec.VATTable,loc.data.vcode)>
								<cfset loc.gross = loc.vatRec.gross + loc.price>
								<cfset loc.prop = loc.gross / loc.dealRec.retail>
								<cfset StructUpdate(loc.dealRec.VATTable,loc.data.vcode,{"rate" = loc.data.vrate, "gross" = loc.gross, "prop" = loc.prop})>
							</cfif>
							<cfif loc.dealData.edEnds gt Now()>
								<cfset loc.dealRec.remQty = loc.count MOD loc.dealData.edQty>
								<cfif loc.count MOD loc.dealData.edQty eq 0>
									<cfset loc.dealRec.lastQual = loc.count>
									<cfset loc.dealRec.dealQty++>
									<cfset loc.data.style = "red">
									<cfset loc.dealRec.dealTotal = loc.dealRec.dealQty * loc.dealData.edAmount>
									<cfset loc.dealRec.groupRetail = 0>
								</cfif>
							</cfif>
						</cfloop>
						<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
						<cfset loc.dealRec.savingGross = loc.dealRec.retail - loc.dealRec.totalCharge>
					</cfcase>

					<cfcase value="twofor">
						<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
							<cfset loc.count++>
							<cfset loc.price = ListFirst(loc.priceKey," ")>
							<cfset loc.prodID = ListLast(loc.priceKey," ")>
							<cfset loc.data = StructFind(session.basket.shopItems,loc.prodID)>
							<cfset loc.data.discount = 0>
							<cfif loc.dealData.edEnds gt Now()>
								<cfif loc.count MOD loc.dealData.edQty eq 0>
									<cfif NOT StructKeyExists(loc.dealRec.VATTable,loc.data.vcode)>
										<cfset StructInsert(loc.dealRec.VATTable,loc.data.vcode,{"rate" = loc.data.vrate, "gross" = loc.price * 1, "prop" = 1})>
									<cfelse>
										<cfset loc.vatRec = StructFind(loc.dealRec.VATTable,loc.data.vcode)>
										<cfset StructUpdate(loc.dealRec.VATTable,loc.data.vcode,{"rate" = loc.data.vrate, "gross" = loc.vatRec.gross + loc.price, "prop" = 1})>
									</cfif>
									<cfset loc.dealRec.dealQty++>
									<cfset loc.data.style = "red">
									<cfset loc.dealRec.dealQty = int(loc.dealRec.count / 2)>
									<cfset loc.dealRec.remQty = loc.dealRec.count mod 2>
									<cfset loc.dealRec.dealTotal = loc.dealRec.dealQty * loc.dealData.edAmount + (loc.dealRec.remQty * loc.price * 1)>
								</cfif>
							</cfif>
						</cfloop>
						<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
						<cfset loc.dealRec.savingGross = loc.dealRec.retail - loc.dealRec.totalCharge>
					</cfcase>

					<cfcase value="bogof">
						<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
							<cfset loc.count++>
							<cfset loc.price = ListFirst(loc.priceKey," ")>
							<cfset loc.prodID = ListLast(loc.priceKey," ")>
							<cfset loc.data = StructFind(session.basket.shopItems,loc.prodID)>
							<cfset loc.data.discount = 0>
							<cfif loc.dealData.edEnds gt Now()>
								<cfif loc.count MOD loc.dealData.edQty eq 0>
									<cfif NOT StructKeyExists(loc.dealRec.VATTable,loc.data.vcode)>
										<cfset StructInsert(loc.dealRec.VATTable,loc.data.vcode,{"rate" = loc.data.vrate, "gross" = loc.price * 1, "prop" = 1})>
									<cfelse>
										<cfset loc.vatRec = StructFind(loc.dealRec.VATTable,loc.data.vcode)>
										<cfset StructUpdate(loc.dealRec.VATTable,loc.data.vcode,{"rate" = loc.data.vrate, "gross" = loc.vatRec.gross + loc.price, "prop" = 1})>
									</cfif>
									<cfset loc.dealRec.dealQty++>
									<cfset loc.data.style = "red">
									<cfset loc.dealRec.dealQty = int(loc.dealRec.count / 2)>
									<cfset loc.dealRec.remQty = loc.dealRec.count mod 2>
									<cfset loc.dealRec.dealTotal = (loc.dealRec.dealQty * loc.price) + (loc.dealRec.remQty * loc.price * 1)>
								</cfif>
							</cfif>
						</cfloop>
						<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
						<cfset loc.dealRec.savingGross = loc.dealRec.retail - loc.dealRec.totalCharge>
					</cfcase>

					<cfcase value="only">
						<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
							<cfset loc.count++>
							<cfset loc.price = ListFirst(loc.priceKey," ")>
							<cfset loc.prodID = ListLast(loc.priceKey," ")>
							<cfset loc.data = StructFind(session.basket.shopItems,loc.prodID)>
							<cfset loc.data.discount = 0>
							<cfif loc.dealData.edEnds gt Now()>
								<cfif loc.count MOD loc.dealData.edQty eq 0>
									<cfif NOT StructKeyExists(loc.dealRec.VATTable,loc.data.vcode)>
										<cfset StructInsert(loc.dealRec.VATTable,loc.data.vcode,{"rate" = loc.data.vrate, "gross" = loc.price * 1, "prop" = 1})>
									<cfelse>
										<cfset loc.vatRec = StructFind(loc.dealRec.VATTable,loc.data.vcode)>
										<cfset StructUpdate(loc.dealRec.VATTable,loc.data.vcode,{"rate" = loc.data.vrate, "gross" = loc.vatRec.gross + loc.price, "prop" = 1})>
									</cfif>
									<cfset loc.dealRec.dealQty++>
									<cfset loc.data.style = "red">
									<cfset loc.dealRec.dealTotal = loc.dealRec.dealQty * loc.dealData.edAmount>
								</cfif>
							</cfif>
						</cfloop>
						<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
						<cfset loc.dealRec.savingGross = loc.dealRec.retail - loc.dealRec.totalCharge>
					</cfcase>

					<cfcase value="b1g1hp">
						<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
							<cfset loc.count++>
							<cfset loc.price = ListFirst(loc.priceKey," ")>
							<cfset loc.prodID = ListLast(loc.priceKey," ")>
							<cfset loc.data = StructFind(session.basket.shopItems,loc.prodID)>
							<cfset loc.data.discount = 0>
							<cfif loc.dealData.edEnds gt Now()>
								<cfif loc.count MOD loc.dealData.edQty eq 0>
									<cfif NOT StructKeyExists(loc.dealRec.VATTable,loc.data.vcode)>
										<cfset StructInsert(loc.dealRec.VATTable,loc.data.vcode,{"rate" = loc.data.vrate, "gross" = loc.price * 1, "prop" = 1})>
									<cfelse>
										<cfset loc.vatRec = StructFind(loc.dealRec.VATTable,loc.data.vcode)>
										<cfset StructUpdate(loc.dealRec.VATTable,loc.data.vcode,{"rate" = loc.data.vrate, "gross" = loc.vatRec.gross + loc.price, "prop" = 1})>
									</cfif>
									<cfset loc.dealRec.dealQty++>
									<cfset loc.data.style = "red">
									<cfset loc.dealRec.dealQty = int(loc.dealRec.count / 2)>
									<cfset loc.dealRec.remQty = loc.dealRec.count mod 2>
									<cfset loc.dealRec.dealTotal = (loc.dealRec.dealQty * loc.price * 1.5) + (loc.dealRec.remQty * loc.price)>
								</cfif>
							</cfif>
						</cfloop>
						<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
						<cfset loc.dealRec.savingGross = loc.dealRec.retail - loc.dealRec.totalCharge>
					</cfcase>
				</cfswitch>

				<cfif loc.dealRec.dealTotal eq 0 OR loc.dealRec.remQty neq 0> <!--- did not make the deal, see if staff disc applies --->
					<cfif session.till.info.staff AND loc.data.discountable>	<!--- staff sale and is a discountable item --->
						<cfloop from="#loc.dealRec.lastQual+1#" to="#ArrayLen(loc.dealRec.prices)#" index="loc.i">
							<cfset loc.priceKey = loc.dealRec.prices[loc.i]>
							<cfset loc.price = ListFirst(loc.priceKey," ")>
							<cfset loc.prodID = ListLast(loc.priceKey," ")>
							<cfset loc.data = StructFind(session.basket.shopItems,loc.prodID)>
							<cfset loc.data.discount = round(loc.price * 100 * session.till.prefs.discount) / 100 * loc.rec.regMode>
							<cfset loc.vatRate = 1 + (val(loc.data.vrate) / 100)>
							<cfset loc.data.totalGross = loc.data.retail + loc.data.discount>	<!--- recalculate VAT on discounted amount --->
							<cfset loc.data.totalNet = Round(loc.data.totalGross / loc.vatRate * 100) / 100>
							<!---<cfset loc.data.totalNet = loc.data.totalGross / loc.vatRate>--->
							<cfset loc.data.totalVAT = loc.data.totalGross - loc.data.totalNet>
						</cfloop>
					</cfif>
				</cfif>

				<cfset loc.dealRec.savingGross = loc.dealRec.savingGross * loc.rec.regMode>
				<cfset loc.dealRec.savingNet = 0>
				<cfset loc.dealRec.savingVAT = 0>
				<cfloop collection="#loc.dealRec.VATTable#" item="loc.vatKey">
					<cfset loc.vatItem = StructFind(loc.dealRec.VATTable,loc.vatKey)>
					<cfset loc.vatItem.saveGross = loc.dealRec.savingGross * loc.vatItem.prop>
					<cfset loc.vatItem.saveNet = loc.vatItem.saveGross / (1 + (loc.vatItem.rate / 100))>
					<cfset loc.vatItem.saveVAT = loc.vatItem.saveGross - loc.vatItem.saveNet>
					<cfset loc.dealRec.savingNet += (loc.dealRec.savingGross * loc.vatItem.prop) / (1 + (loc.vatItem.rate / 100))>
				</cfloop>
				<cfset loc.dealRec.savingVAT += loc.dealRec.savingGross - loc.dealRec.savingNet>
			</cfloop>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="CheckDeals" access="public" returntype="void" hint="check basket for qualifying deals.">
		<cfset var loc = {}>
		<cftry>
			<cfset session.basket.deals = {}>
			<cfloop collection="#session.basket.shopItems#" item="loc.key">
				<cfset loc.item = StructFind(session.basket.shopItems,loc.key)>
				<!---<cfset loc.vatRate = 1 + (val(loc.item.vrate) / 100)>	WHY IS THIS REPEATED?
				<cfset loc.item.totalGross = loc.item.retail>
				<cfset loc.item.totalNet = Round(loc.item.totalGross / loc.vatRate * 100) / 100>
				<!---<cfset loc.item.totalNet = loc.item.totalGross / loc.vatRate>--->
				<cfset loc.item.totalVAT = loc.item.totalGross - loc.item.totalNet>--->
				<cfif loc.item.dealID gt 0>
					<cfset loc.deal = StructFind(session.dealdata,loc.item.dealID)>
					<cfif StructKeyExists(session.basket.deals,loc.item.dealID)>
						<cfset loc.dealRec = StructFind(session.basket.deals,loc.item.dealID)>
					<cfelse>
						<cfset loc.dealRec = {}>
						<cfset loc.dealRec.prices = []>
						<cfset loc.dealRec.count = 0>
						<cfset loc.dealRec.retail = 0>
						<cfset loc.dealRec.dealTitle = loc.deal.edTitle>
						<cfset StructInsert(session.basket.deals,loc.item.dealID,loc.dealRec)>
					</cfif>
					<cfset loc.dealRec.count += loc.item.qty>
					<cfloop from="1" to="#loc.item.qty#" index="loc.i">
						<cfset ArrayAppend(loc.dealRec.prices,"#NumberFormat(loc.item.unitPrice,'000.00')# #loc.key#")>
						<cfset loc.dealRec.retail += loc.item.unitPrice>
					</cfloop>
				<cfelseif session.till.info.staff AND loc.item.discountable>	<!--- staff sale, is a discountable item and not on a deal --->
					<cfset loc.item.discount = round(-loc.item.retail * 100 * session.till.prefs.discount) / 100>
					<cfset loc.vatRate = 1 + (val(loc.item.vrate) / 100)>
					<cfset loc.item.totalGross = loc.item.retail + loc.item.discount>	<!--- recalculate VAT on discounted amount --->
					<cfset loc.item.totalNet = Round(loc.item.totalGross / loc.vatRate * 100) / 100>
					<!---<cfset loc.item.totalNet = loc.item.totalGross / loc.vatRate>--->
					<cfset loc.item.totalVAT = loc.item.totalGross - loc.item.totalNet>
				</cfif>
			</cfloop>
			<cfset ProcessDeals()>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="CheckDeals" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="UpdateBasket" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cftry>
			<cfset var loc = {}>
			<cfset loc.insertItem = false>
			<cfset loc.tranType = -1>
			<cfset loc.section = StructFind(session.basket,"#args.form.itemClass#ITEMS")>
			<cfset loc.sectionArray = StructFind(session.basket,args.form.itemClass)>
			<cfset session.till.isTranOpen = true>

			<cfif StructKeyExists(loc.section,args.data.itemID)>
				<cfset loc.rec = StructFind(loc.section,args.data.itemID)>
			<cfelse>
				<cfset loc.insertItem = true>
				<cfset loc.rec = {}>
				<cfset loc.rec.itemID = args.data.itemID>
				<cfset loc.rec.title = args.data.title>
				<cfset loc.rec.vrate = args.form.vrate>
				<cfset loc.rec.type = args.form.itemClass>
				<cfset loc.rec.vcode = args.data.vcode>
				<cfset loc.rec.qty = 0>
			</cfif>
			<cfset loc.rec.regMode = (2 * int(session.basket.info.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
			<cfset loc.vatRate = 1 + (val(loc.rec.vrate) / 100)>
			<cfset loc.rec.discountable = StructKeyExists(args.form,"discountable")>
			<cfset loc.rec.cashonly = args.form.cashonly>
			<cfset loc.rec.cash = args.data.cash>
			<cfset loc.rec.credit = args.data.credit>
			<cfset loc.rec.unitPrice = loc.rec.cash + loc.rec.credit>
			<cfset loc.rec.qty += args.form.qty>		<!--- accumulate qty with any previous value. can be +/- --->
			<cfset loc.rec.discount = 0>	<!--- reset any previously assigned discount for this product --->
			<cfif loc.rec.qty lte 0>
				<cfset StructDelete(loc.section,args.data.itemID,false)>
				<cfset ArrayDelete(loc.sectionArray,args.data.itemID)>
			<cfelse>
				<cfset loc.rec.retail = loc.rec.qty * loc.rec.unitPrice>
				<cfset loc.rec.totalGross = loc.rec.retail>
				<cfset loc.rec.dealID = 0>	<!--- clear any current deal --->
				<cfif StructKeyExists(session.dealIDs,args.form.prodID)>	<!--- product deals only --->
					<cfset loc.rec.dealID = StructFind(session.dealIDs,args.form.prodID)>
				</cfif>

				<cfset loc.rec.totalNet = Round(loc.rec.totalGross / loc.vatRate * 100) / 100>
				<!---<cfset loc.rec.totalNet = loc.rec.totalGross / loc.vatRate>--->
				<cfset loc.rec.totalVAT = loc.rec.totalGross - loc.rec.totalNet>

				<cfset loc.rec.retail = loc.rec.retail * loc.rec.regMode * loc.tranType>
				<cfset loc.rec.totalGross = loc.rec.totalGross * loc.rec.regMode * loc.tranType>
				<cfset loc.rec.totalNet = loc.rec.totalNet * loc.rec.regMode * loc.tranType>
				<cfset loc.rec.totalVAT = loc.rec.totalVAT * loc.rec.regMode * loc.tranType>
			</cfif>
			<cfif loc.insertItem>	<!--- if item not in struct --->
				<cfset StructInsert(loc.section,args.data.itemID,loc.rec)>
				<cfset ArrayAppend(loc.sectionArray,args.data.itemID)>
			<cfelseif loc.rec.qty gt 0>
				<cfset StructUpdate(loc.section,args.data.itemID,loc.rec)>
			</cfif>
			<cfset StructUpdate(session.basket,args.form.itemClass,loc.sectionArray)>
			<cfset CheckDeals()>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="CalcValues" access="public" returntype="void" hint="calculate transaction values.">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.tranType = -1>
		<cfset loc.regMode = (2 * int(session.basket.info.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
		<cfset loc.vatrate = 1 + (val(args.vrate) / 100)>

		<cfset args.regMode = loc.regMode>
		<cfset args.unitPrice = args.cash + args.credit>
		<cfset args.retail = args.qty * args.unitPrice>
		<cfset args.totalGross = args.retail>
		<cfset args.totalNet = Round(args.totalGross / loc.vatRate * 100) / 100>
		<!---<cfset args.totalNet = args.totalGross / loc.vatrate>--->
		<cfset args.totalVAT = args.totalGross - args.totalNet>
		<cfset args.retail = args.retail * loc.regMode * loc.tranType>
		<cfset args.totalGross = args.totalGross * loc.regMode * loc.tranType>
		<cfset args.totalNet = args.totalNet * loc.regMode * loc.tranType>
		<cfset args.totalVAT = args.totalVAT * loc.regMode * loc.tranType>

		<cfset session.basket.info.itemcount += args.qty>
	</cffunction>

	<cffunction name="AddItem" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>

		<cftry>
			<cfset loc.result.err = "">
			<cfset session.till.isTranOpen = true>
			<cfif val(args.form.prodSign) eq 0>
				<cfset session.basket.info.errMsg = "Invalid product information supplied to AddItem function.">
				<cfdump var="#args#" label="Invalid AddItem" expand="yes" format="html"
					output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
				<cfreturn loc.result>
			</cfif>
			<cfif val(args.form.prodID) gt 0>
				<cfset args.form.pubID = 1>
				<cfset args.data.itemID = args.form.prodID>
				<cfset args.data.title = args.form.prodTitle>
			<cfelseif val(args.form.pubID) gt 0>
				<cfset args.form.prodID = 1>
				<cfset args.data.itemID = args.form.pubID>
				<cfset args.data.title = args.form.pubTitle>
			<cfelseif Left(args.form.itemClass,5) eq "prod-">	<!--- not used anymore --->
				<cfset args.data.itemID = val(mid(args.form.itemClass,6,10))>
				<cfset args.data.title = args.form.prodTitle>
				<cfset args.form.itemClass = "SALE">
				<cfset args.form.pubID = 1>
			<cfelse>
				<cfset args.data.itemID = 1>
			</cfif>

			<cfset loc.regMode = (2 * int(session.basket.info.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
			<cfset loc.tranType = -1>
			<!--- sanitise input fields --->
			<cfset args.data.class = "item">
			<cfset args.data.discount = 0>
			<cfset args.data.qty = val(args.form.qty)>
			<cfset args.data.cash = abs(val(args.form.cash)) * args.form.prodSign>
			<cfset args.data.credit = abs(val(args.form.credit)) * args.form.prodSign>
			<cfset args.data.itemClass = args.form.itemClass>
			<cfset args.data.vrate = val(args.form.vrate)>
			<cfset args.data.vcode = StructFind(session.vat,DecimalFormat(args.form.vrate))>
			<cfset session.basket.info.errMsg = "">

			<cfswitch expression="#args.form.itemClass#">
				<cfcase value="PAYPOINT">
					<cfif ArrayLen(session.basket.supplier) gt 0> <!--- already have supplier transaction in basket --->
						<cfset session.basket.info.errMsg = "Cannot add a paypoint item during a supplier transaction.">
					<cfelse>
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfif args.data.cash neq 0>
							<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
							<cfset args.data.gross = args.data.cash>
							<cfset args.data.class = "item">
							<cfset args.data.discount = 0>
							<cfset args.data.account = 2>
							<cfset args.data.vat = 0>
							<cfset args.data.type = args.form.itemClass>
							<cfset CalcValues(args.data)>
							<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.paypoint,args.data)></cfif>
							<!---<cfset CalcTotals()>--->
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="SRV">
					<cfif ArrayLen(session.basket.supplier) gt 0> <!--- already have supplier transaction in basket --->
						<cfset session.basket.info.errMsg = "Cannot add a paypoint item during a supplier transaction.">
					<cfelse>
						<cfset args.data.credit = args.data.cash + args.data.credit>
						<cfif args.data.credit neq 0 AND session.basket.info.service eq 0>	<!--- only add once--->
							<cfset args.data.cash = 0>	<!--- force empty - only use credit figure --->
							<cfset args.data.gross = args.data.credit>	<!--- calc gross transaction value --->
							<cfset args.data.qty = 1>
							<cfset args.data.class = "item">
							<cfset args.data.discount = 0>
							<cfset args.data.account = 2>
							<cfset args.data.vat = 0>
							<cfset args.data.type = args.form.itemClass>
							<cfset CalcValues(args.data)>
							<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.srv,args.data)></cfif>
							<cfset session.basket.info.service = args.data.credit>	<!--- remember if service charge added --->
							<!---<cfset CalcTotals()>--->
						<cfelse>
							<cfset session.basket.info.errMsg = "Service charge is already in the basket.">
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="LOTTERY">
					<cfif ArrayLen(session.basket.supplier) gt 0> <!--- already have supplier transaction in basket --->
						<cfset session.basket.info.errMsg = "Cannot pay a prize during a supplier transaction.">
					<cfelse>
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfif args.data.cash neq 0>
							<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
							<cfset args.data.gross = args.data.cash>	<!--- calc gross transaction value --->
							<cfset args.data.class = "item">
							<cfset args.form.discount = 0>
							<cfset args.data.account = 2>
							<cfset args.form.vat = 0>
							<cfset args.data.type = args.form.itemClass>
							<cfset CalcValues(args.data)>
							<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.lottery,args.data)></cfif>
							<!---<cfset CalcTotals()>--->
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="NEWS">
					<cfif ArrayLen(session.basket.supplier) gt 0> <!--- already have supplier transaction in basket --->
						<cfset session.basket.info.errMsg = "Cannot pay a news account during a supplier transaction.">
					<cfelse>
						<cfif args.data.credit + args.data.cash neq 0>
							<cfset args.data.gross = args.data.credit + args.data.cash>	<!--- calc gross transaction value --->
							<cfset args.data.class = "item">
							<cfset args.data.discount = 0>
							<cfset args.data.account = 2>
							<cfset args.data.vat = 0>
							<cfset args.data.type = args.form.itemClass>
							<cfset CalcValues(args.data)>
							<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.news,args.data)></cfif>
							<!---<cfset CalcTotals()>--->
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="PRIZE|VCHN|CPN" delimiters="|">
					<cfif ArrayLen(session.basket.supplier) gt 0> <!--- already have supplier transaction in basket --->
						<cfset session.basket.info.errMsg = "Invalid transaction during a supplier transaction.">
					<cfelse>
						<!--- pass onto payment routine --->
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfif args.data.cash neq 0>
							<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
							<cfset args.form.btnSend = args.form.itemClass>
							<cfset AddPayment(args)>
						<cfelse>
							<cfset session.basket.info.errMsg = "Please enter the prize value.">
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="SUPPLIER">
					<cfif ArrayLen(session.basket.shop) gt 0> <!--- already have sales transaction in basket --->
						<cfset session.basket.info.errMsg = "Cannot pay supplier during a sales transaction.">
					<cfelse>
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfif args.data.cash neq 0>
							<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
							<cfset args.data.gross = args.data.cash>	<!--- calc gross transaction value --->
							<cfset args.data.class = "item">
							<cfset args.data.discount = 0>
							<cfset args.data.account = 2>
							<cfset args.data.vat = 0>
							<cfset args.data.type = args.form.itemClass>
							<cfset session.basket.info.type = "PURCH">	<!--- set receipt title --->
							<cfset session.basket.info.bod = "Supplier">
							<!---<cfset session.basket.total.supplies += args.data.cash>	<!--- accumulate supplier total --->
							<cfset session.basket.header.supplies += args.data.cash>
							<cfset session.basket.header.balance -= args.data.cash>--->
							<cfset CalcValues(args.data)>
							<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.supplier,args.data)></cfif>
							<!---<cfset CalcTotals()>--->
						</cfif>
					</cfif>
				</cfcase>
				<cfdefaultcase>
					<cfif ListFind(session.till.prefs.catlist,args.form.itemClass,",")>
						<cfif ArrayLen(session.basket.supplier) gt 0>
							<cfset session.basket.info.errMsg = "Cannot start a sales transaction during a supplier transaction.">
						<cfelse>
							<cfif args.data.credit + args.data.cash neq 0>
								<cfif StructKeyExists(args.form,"sign")>
									<cfset args.data.cash = args.data.cash * args.form.sign>
									<cfset args.data.credit = args.data.credit * args.form.sign>
								</cfif>
								<cfset CalcValues(args.data)>
								<cfset UpdateBasket(args)>
								<!---<cfset CalcTotals()>--->
							<cfelse>
								<cfset session.basket.info.errMsg = "No value was passed to AddItem function.">
							</cfif>
						</cfif>
					</cfif>
				</cfdefaultcase>
			</cfswitch>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="RemovePayment" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset session.basket.header.cashtaken -= ( val(args.form.cash) + val(args.form.credit) )>
		<cfset session.basket.header.balance += ( val(args.form.cash) + val(args.form.credit) )>
		<cfset ArrayDeleteAt(session.basket.payments, val(args.form.arrIndex))>
		<cfset CalcTotals()>
	</cffunction>

	<cffunction name="AddPayment" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cftry>
			<cfset session.till.isTranOpen = true>
			<cfset loc.regMode = (2 * int(session.basket.info.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
			<cfset loc.tranType = 1>
			<cfset args.data.cash = abs(val(args.form.cash)) * loc.tranType * loc.regMode> <!--- all form values are +ve numbers --->
			<cfset args.data.credit = abs(val(args.form.credit)) * loc.tranType * loc.regMode>	<!--- apply mode & type to set sign correctly --->
			<cfset args.data.account = args.form.account>
			<cfset args.data.itemID = 1>
			<cfset args.data.qty = 1>
			<cfset session.basket.info.errMsg = "">

			<!--- count items in all departments --->
			<cfset loc.basketItems = 0>
			<cfloop array="#session.till.catKeys#" index="loc.key">
				<cfset loc.dept = StructFind(session.basket,loc.key)>
				<cfset loc.basketItems += ArrayLen(loc.dept)>
			</cfloop>

			<!--- difference between cash sales and cash received... --->
			<cfset loc.cashBalance = session.basket.header.bCash + session.basket.header.cashTaken + session.basket.header.cashback + session.basket.header.Prize + session.basket.header.cpn>

			<!--- payment methods --->
			<cfswitch expression="#args.form.btnSend#">
				<cfcase value="Cash">
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelse>
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfif args.data.cash is 0>
							<cfset args.data.cash = session.basket.total.balance>
						</cfif>
						<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "CASHINDW">
						<cfset args.data.title = "Cash Payment">
						<cfset args.data.account = 2>
						<cfset args.data.prodID = 2>
						<cfset ArrayAppend(session.basket.payments,args.data)>
					</cfif>
				</cfcase>

				<cfcase value="Card">
					<cfif args.data.cash + args.data.credit is 0>
						<cfset args.data.credit = session.basket.total.balance>
						<cfset args.data.cash = 0>
					</cfif>
					<cfset loc.cashBalance += args.data.cash>
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.supplier) gt 0>
						<cfset session.basket.info.errMsg = "Cannot accept a card payment during a supplier transaction.">
					<cfelseif session.basket.info.mode eq "reg" AND loc.cashBalance lt 0>
						<cfset session.basket.info.errMsg = "Some items in the basket must be paid by cash or cashback. (#loc.cashBalance#)">
					<cfelseif session.basket.info.mode eq "rfd" AND loc.cashBalance gt 0>
						<cfset session.basket.info.errMsg = "Some items in the basket must be refunded by cash.">
					<cfelseif session.basket.info.mode eq "reg" AND args.data.credit gt session.basket.total.balance>
						<cfset session.basket.info.errMsg = "Card sale amount is too high. #args.data.credit# : #session.basket.total.balance#">
					<cfelseif session.basket.info.mode eq "rfd" AND args.data.credit lt session.basket.total.balance>
						<cfset session.basket.info.errMsg = "Card sale amount is too high. #args.data.credit# : #session.basket.total.balance#">
					<cfelseif args.data.cash neq 0 AND args.data.credit eq 0>
						<cfset session.basket.info.errMsg = "Please enter the sale amount from the Paypoint receipt.">
					<cfelseif session.basket.info.service eq 0 AND abs(args.data.credit) lt session.till.prefs.mincard AND abs(args.data.credit) neq session.till.prefs.service>
						<cfset session.basket.info.errMsg = "Minimum sale amount allowed on card is &pound;#session.till.prefs.mincard#.">
					<cfelse>
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "CARDINDW">
						<cfset args.data.title = "Card Payment">
						<cfset args.data.account = 2>
						<cfset args.data.prodID = 2>
						<cfset ArrayAppend(session.basket.payments,args.data)>
					</cfif>
				</cfcase>
				<cfcase value="Cheque">
					<cfif args.data.cash + args.data.credit is 0>
						<cfset args.data.credit = session.basket.total.balance>
						<cfset args.data.cash = 0>
					<cfelseif args.data.cash gt 0>
						<cfset args.data.credit = args.data.cash>
						<cfset args.data.cash = 0>
					</cfif>
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put a news account item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.supplier) gt 0>
						<cfset session.basket.info.errMsg = "Cannot accept a cheque during a supplier transaction.">
					<cfelseif abs(session.basket.total.news) neq abs(args.data.credit)>
						<cfset session.basket.info.errMsg = "Cheque amount must equal the News Account Payment.">
					<cfelse>
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "CHQINDW">
						<cfset args.data.title = "Cheque Payment">
						<cfset args.data.account = 2>
						<cfset args.data.prodID = 2>
						<cfset ArrayAppend(session.basket.payments,args.data)>
					</cfif>
				</cfcase>
				<cfcase value="Account">
					<cfif args.data.cash + args.data.credit is 0>
						<cfset args.data.credit = session.basket.total.balance>
						<cfset args.data.cash = 0>
					</cfif>
					<cfset loc.cashBalance += args.data.cash>
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.supplier) gt 0>
						<cfset session.basket.info.errMsg = "Cannot pay on account during a supplier transaction.">
<!---					<cfelseif session.basket.info.mode eq "reg" AND loc.cashBalance lt 0>
						<cfset session.basket.info.errMsg = "Some items in the basket must be paid by cash or cashback. (#loc.cashBalance#)">
--->
					<cfelseif val(args.data.account) is 0>
						<cfset session.basket.info.errMsg = "Please select an account to assign this transaction.">
					<cfelse>
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "ACCINDW">
						<cfset args.data.title = "Payment on Account">
						<cfset ArrayAppend(session.basket.payments,args.data)>
					</cfif>
				</cfcase>
				<cfcase value="VCHN">
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put a news item in the basket before accepting voucher.">
					<cfelse>
						<cfif args.data.cash + args.data.credit is 0>
							<cfset args.data.credit = session.basket.total.balance>
						</cfif>
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "VCHN">
						<cfset args.data.account = 2>
						<cfset args.data.prodID = 2>
						<cfset ArrayAppend(session.basket.payments,args.data)>
					</cfif>
				</cfcase>
				<cfcase value="CPN">
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put a Paypoint item in the basket before accepting coupon.">
					<cfelse>
						<cfif args.data.cash + args.data.credit is 0>
							<cfset args.data.credit = session.basket.total.balance>
						</cfif>
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "CPN">
						<cfset args.data.account = 2>
						<cfset args.data.prodID = 2>
						<cfset ArrayAppend(session.basket.payments,args.data)>
					</cfif>
				</cfcase>
				<cfcase value="PRIZE">
					<cfif args.data.cash + args.data.credit is 0>
						<cfset args.data.cash = session.basket.total.balance>
					</cfif>
					<cfset args.data.class = "pay">
					<cfset args.data.itemClass = "PRIZE">
					<cfset args.data.account = 2>
					<cfset args.data.prodID = 2>
					<cfset ArrayAppend(session.basket.payments,args.data)>
				</cfcase>
			</cfswitch>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="AddPayment" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="StructToDataAttributes" access="public" returntype="string">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = "">

		<cfloop collection="#args#" item="loc.key">
			<cfset loc.item = StructFind(args, loc.key)>
			<cfif IsValid("string", loc.item) OR IsValid("boolean", loc.item) OR IsValid("float", loc.item)>
				<cfset loc.result = loc.result & " data-#LCase(loc.key)#='#loc.item#'">
			</cfif>
		</cfloop>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="ShowBasket" access="public" returntype="void">
		<cfargument name="type" type="string" required="no" default="html">
		<cfset var loc = BuildBasket()>
		<cfset loc.thisBasket = (arguments.type eq "html") ? session.basket : session.till.prevtran>

		<cftry>
			<cfoutput>
				<cfif arguments.type eq "js">
					request += builder.createAlignmentElement({position: 'center'});
					request += builder.createTextElement(styles.heading("Shortlanesend Store\n\n"));

					request += builder.createAlignmentElement({position: 'left'});
					request += builder.createTextElement(styles.normal(align.lr("Tel: #application.company.telephone#", "VAT: #application.company.vat_number#")));

					request += builder.createTextElement({data: '\n'});

					<cfif loc.thisBasket.info.mode eq "rfd">
						request += builder.createAlignmentElement({position: 'center'});
						request += builder.createTextElement(styles.bold("Refund\n"));
					</cfif>

					request += builder.createAlignmentElement({position: 'left'});
					request += builder.createTextElement(styles.normal(align.lr("Served By: #session.user.firstName#", ("Ref: 123456 (TODO)"))));

					request += builder.createTextElement({data: '\n\n'});
				</cfif>

				<cfif arguments.type eq "html"><table class="eposBasketTable" border="0" width="100%">
					<tr class="ebt_headers">
						<th align="left">Description</th>
						<th align="center">Qty</th>
						<th align="right">Price</th>
						<th align="right">Total</th>
						<th>VC</th>
					</tr><cfelse>
						request += builder.createAlignmentElement({position: 'left'});
						request += builder.createTextElement(styles.bold(align.rlr("QTY", "DESCRIPTION", "AMOUNT")));
						request += builder.createTextElement({data: '\n'});
					</cfif>
					<cfloop array="#session.till.catKeys#" index="loc.key">
						<cfset loc.section = StructFind(loc.thisBasket,loc.key)>
						<cfloop array="#loc.section#" index="loc.item">
							<cfset loc.style = "">
							<cfif IsStruct(loc.item)>
								<cfset loc.data = loc.item>
							<cfelse>
								<cfset loc.sectionData = StructFind(loc.thisBasket,"#loc.key#Items")>
								<cfset loc.data = StructFind(loc.sectionData,loc.item)>
							</cfif>
							<cfif arguments.type eq "html">
								<tr class="basket_item" #StructToDataAttributes(loc.data)#>
									<td align="left"><span class="#loc.style#">#loc.data.title#</span></td>
									<td align="center">#loc.data.qty#</td>
									<td align="right">#DecimalFormat(loc.data.unitPrice)#</td>
									<td align="right">#DecimalFormat(-loc.data.retail)#</td>
									<td align="center">#loc.data.vcode#</td>
								</tr>
							<cfelse>
								title = "#loc.data.title#";
								lenspace = loc.paperCharWidth - (10 + #Len(loc.data.retail)#);
								titlearr = title.split(" ");
								curlen = 0;
								title1 = "";
								title2 = "";

								for (var n = 0; n < titlearr.length; n++) {
									var str = titlearr[n];
									curlen += str.length;
									if (curlen < lenspace) {
										title1 = title1 + (str + " ");
									} else {
										title2 = title2 + (str + " ");
									}
								}

								if (title1.length > 0) {
									request += builder.createTextElement(styles.normal(align.rlr("#loc.data.qty#", title1, "#DecimalFormat(-loc.data.retail)#")));
									request += builder.createTextElement({data: '\n'});
								}

								if (title2.length > 0) {
									request += builder.createTextElement(styles.normal(align.rlr("-", title2, "-")));
									request += builder.createTextElement({data: '\n'});
								}
							</cfif>
						</cfloop>
					</cfloop>

					<cfif arguments.type eq "html">
						<tr class="ebt_headers">
							<th align="left">Total</th>
							<th align="center"></th>
							<th align="right"></th>
							<th align="right">#DecimalFormat(loc.totalRetail)#</th>
							<th></th>
						</tr>
					<cfelse>
						request += builder.createRuledLineElement({thickness: 'medium', width: 832});
						request += builder.createAlignmentElement({position: 'left'});
						request += builder.createTextElement(styles.bold(align.lr("TOTAL DUE", "#DecimalFormat(loc.thisBasket.info.totalDue)#")));
						request += builder.createTextElement({data: '\n'});
					</cfif>
					<cfif StructKeyExists(loc.thisBasket,"deals")>
						<cfif loc.qualifyingDeals gt 0>
							<cfif arguments.type eq "html">
								<tr>
									<td colspan="4">&nbsp;</td>
								</tr>
								<tr class="ebt_headers">
									<th align="left">Multibuy Discounts</th>
									<th align="center">Items</th>
									<th></th>
									<th align="right">Saving</th>
									<th></th>
								</tr>
							</cfif>
						</cfif>
						<cfloop collection="#loc.thisBasket.deals#" item="loc.key">
							<cfset loc.data = StructFind(loc.thisBasket.deals,loc.key)>
							<cfif loc.data.dealQty neq 0>
								<cfif arguments.type eq "html">
									<tr class="basket_item">
										<td align="left">#loc.data.dealTitle#</td>
										<td align="center">#loc.data.count#</td>
										<td></td>
										<td align="right">#DecimalFormat(-loc.data.savingGross)#</td>
										<td></td>
									</tr>
								<cfelse>
									request += builder.createAlignmentElement({position: 'left'});
									request += builder.createTextElement(styles.normal(align.lr("#REReplace(loc.data.dealTitle, '[\W\D\S]', '')#", "#DecimalFormat(loc.data.savingGross)#")));
									request += builder.createTextElement({data: '\n'});
								</cfif>
							</cfif>
						</cfloop>
						<cfif loc.thisBasket.total.discstaff neq 0>
							<cfif arguments.type eq "html">
								<tr class="basket_item">
									<td align="left">Staff Discount</td>
									<td align="center"></td>
									<td></td>
									<td align="right">#DecimalFormat(loc.thisBasket.total.discstaff)#</td>
									<td></td>
								</tr>
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.bold(align.lr("STAFF DISCOUNT", "#DecimalFormat(loc.thisBasket.total.discstaff)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfif>
						<cfif arguments.type eq "html">
							<tr>
								<td colspan="4">&nbsp;</td>
							</tr>
							<tr class="ebt_headers">
								<th align="left">Total Due</th>
								<th align="center"></th>
								<th align="right"></th>
								<th align="right">#DecimalFormat(loc.thisBasket.total.balance)#</th>
								<th align="right"></th>
							</tr>
						<cfelse>
							/*request += builder.createAlignmentElement({position: 'left'});
							request += builder.createTextElement(styles.bold(align.lr("TOTAL DUE", "#DecimalFormat(loc.thisBasket.total.balance)#")));
							request += builder.createTextElement({data: '\n'});*/
						</cfif>
					</cfif>
					<cfset loc.payCount = 0>
					<cfloop array="#loc.thisBasket.payments#" index="loc.item">
						<cfset loc.payCount++>

						<cfswitch expression="#loc.item.itemClass#">
							<cfcase value="CASHINDW">
								<cfif arguments.type eq "html">
									<tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
										<td colspan="3">Cash Payment</td><td align="right">#DecimalFormat(-(loc.item.cash + loc.item.credit))#</td>
									</tr>
								<cfelse>
									request += builder.createAlignmentElement({position: 'left'});
									request += builder.createTextElement(styles.bold(align.lr("CASH PAYMENT", "#DecimalFormat((loc.item.cash + loc.item.credit))#")));
									request += builder.createTextElement({data: '\n'});
								</cfif>
							</cfcase>
							<cfcase value="CARDINDW">
								<cfif arguments.type eq "html">
									<tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
										<td colspan="3">Card Payment</td><td align="right">#DecimalFormat(-loc.item.credit)#</td>
									</tr>
								<cfelse>
									request += builder.createAlignmentElement({position: 'left'});
									request += builder.createTextElement(styles.bold(align.lr("CARD PAYMENT", "#DecimalFormat(loc.item.credit)#")));
									request += builder.createTextElement({data: '\n'});
								</cfif>
								<cfif loc.item.cash neq 0>
									<cfif arguments.type eq "html">
										<tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
											<td colspan="3">Cashback</td><td align="right">#DecimalFormat(-loc.item.cash)#</td>
										</tr>
									<cfelse>
										request += builder.createAlignmentElement({position: 'left'});
										request += builder.createTextElement(styles.bold(align.lr("CASHBACK", "#DecimalFormat(loc.item.cash)#")));
										request += builder.createTextElement({data: '\n'});
									</cfif>
								</cfif>
							</cfcase>
							<cfcase value="CHQINDW">
								<cfif arguments.type eq "html">
									<tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
										<td colspan="3">Cheque Payment</td><td align="right">#DecimalFormat(-loc.item.cash - loc.item.credit)#</td>
									</tr>
								<cfelse>
									request += builder.createAlignmentElement({position: 'left'});
									request += builder.createTextElement(styles.bold(align.lr("CHEQUE PAYMENT", "#DecimalFormat(loc.item.cash - loc.item.credit)#")));
									request += builder.createTextElement({data: '\n'});
								</cfif>
							</cfcase>
							<cfcase value="ACCINDW">
								<cfif arguments.type eq "html">
									<tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
										<td colspan="3">Paid on Account</td><td align="right">#DecimalFormat(-loc.item.cash - loc.item.credit)#</td>
									</tr>
								<cfelse>
									request += builder.createAlignmentElement({position: 'left'});
									request += builder.createTextElement(styles.bold(align.lr("PAID ON ACCOUNT", "#DecimalFormat(loc.item.cash - loc.item.credit)#")));
									request += builder.createTextElement({data: '\n'});
								</cfif>
							</cfcase>
							<cfdefaultcase>
								<cfset loc.payValue = StructFind(loc.thisBasket.total,loc.item.itemClass)>
								<cfif arguments.type eq "html">
									<tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
										<td colspan="3">#loc.item.title#</td><td align="right">#DecimalFormat(-(loc.item.cash + loc.item.credit))#</td>
									</tr>
								<cfelse>
									request += builder.createAlignmentElement({position: 'left'});
									request += builder.createTextElement(styles.bold(align.lr("#UCase(loc.item.title)#", "#DecimalFormat((loc.item.cash + loc.item.credit))#")));
									request += builder.createTextElement({data: '\n'});
								</cfif>
							</cfdefaultcase>
						</cfswitch>
					</cfloop>
					<cfif loc.thisBasket.info.itemcount gt 0>
						<cfif arguments.type eq "html"><tr>
							<td colspan="5">&nbsp;</td>
						</tr></cfif>
						<cfif loc.thisBasket.info.mode eq "reg">
							<cfif loc.thisBasket.total.balance lte 0>
								<cfif arguments.type eq "html">
									<tr class="ebt_headers">
										<th align="left">Change</th>
										<th align="center"></th>
										<th align="right"></th>
										<th align="right">#DecimalFormat(-loc.thisBasket.info.change)#</th>
										<th align="right"></th>
									</tr>
								<cfelse>
									request += builder.createAlignmentElement({position: 'left'});
									request += builder.createTextElement(styles.bold(align.lr("CHANGE DUE", "#DecimalFormat(-loc.thisBasket.info.change)#")));
									request += builder.createTextElement({data: '\n'});
								</cfif>
								<cfif arguments.type eq "html">
									<cfset CloseTransaction()>
								</cfif>
							<cfelse>
								<cfif arguments.type eq "html">
									<tr class="ebt_headers">
										<th align="left">Balance Due from Customer</th>
										<th align="center"></th>
										<th align="right"></th>
										<th align="right">#DecimalFormat(loc.thisBasket.total.balance)#</th>
										<th align="right"></th>
									</tr>
								<cfelse>
									request += builder.createAlignmentElement({position: 'left'});
									request += builder.createTextElement(styles.bold(align.lr("BALANCE DUE FROM CUSTOMER", "#DecimalFormat(loc.thisBasket.total.balance)#")));
									request += builder.createTextElement({data: '\n'});
								</cfif>
							</cfif>
						<cfelse>
							<cfif loc.thisBasket.total.balance lt 0>
								<cfif arguments.type eq "html">
									<tr class="ebt_headers">
										<th align="left">Balance Due to Customer</th>
										<th align="center"></th>
										<th align="right"></th>
										<th align="right">#DecimalFormat(loc.thisBasket.total.balance)#</th>
										<th align="right"></th>
									</tr>
								<cfelse>
									request += builder.createAlignmentElement({position: 'left'});
									request += builder.createTextElement(styles.bold(align.lr("BALANCE DUE TO CUSTOMER", "#DecimalFormat(loc.thisBasket.total.balance)#")));
									request += builder.createTextElement({data: '\n'});
								</cfif>
							<cfelse>
								<cfif arguments.type eq "html">
									<tr class="ebt_headers">
										<th align="left">Balance Due from Customer</th>
										<th align="center"></th>
										<th align="right"></th>
										<th align="right">#DecimalFormat(loc.thisBasket.total.balance)#</th>
										<th align="right"></th>
									</tr>
								<cfelse>
									request += builder.createAlignmentElement({position: 'left'});
									request += builder.createTextElement(styles.bold(align.lr("BALANCE DUE FROM CUSTOMER", "#DecimalFormat(loc.thisBasket.total.balance)#")));
									request += builder.createTextElement({data: '\n'});
								</cfif>
								<cfif arguments.type eq "html">
									<cfset CloseTransaction()>
								</cfif>
							</cfif>
						</cfif>
						<cfif loc.qualifyingDeals gt 0>
							<cfif arguments.type eq "html">
								<tr>
									<td colspan="5">&nbsp;</td>
								</tr>
								<tr class="ebt_headers">
									<th align="left">Multibuy Discount Savings</th>
									<th align="center"></th>
									<th></th>
									<th align="right">#DecimalFormat(loc.thisBasket.total.discount)#</th>
									<th></th>
								</tr>
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.bold(align.lr("MULTIBUY DISCOUNT SAVINGS", "#DecimalFormat(loc.thisBasket.total.discount)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfif>
					</cfif>
				<cfif arguments.type eq "html">
					</table>
				<cfelse>
					var barcode = "012345678901";
					request += builder.createAlignmentElement({position: 'center'});
					request += builder.createTextElement({data: '\n'});
					request += builder.createTextElement(styles.normal("Thank you for shopping at Shortlanesend Store\n\n"));
					request += builder.createBarcodeElement({symbology:'JAN13', width:'width3', height:80, hri:false, data:barcode});
				</cfif>
			</cfoutput>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="BuildBasket" access="public" returntype="struct">
		<cfset var loc = {}>

		<cftry>
			<cfset session.basket.vatAnalysis = {}>
			<cfoutput>
				<cfset loc.basketCount = 0>
				<cfset loc.totalRetail = 0>
				<cfset loc.qualifyingDeals = 0>
				<cfset session.basket.header.bCash = 0>
				<cfset session.basket.header.bCredit = 0>
				<cfset session.basket.header.balance = 0>
				<cfset session.basket.header.cashtaken = 0>
				<cfset session.basket.header.cardsales = 0>
				<cfset session.basket.header.chqsales = 0>
				<cfset session.basket.header.cashback = 0>
				<cfset session.basket.header.discdeal = 0>
				<cfset session.basket.header.discstaff = 0>
				<cfset session.basket.total.balance = 0>
				<cfset session.basket.total.discount = 0>
				<cfset session.basket.total.discstaff = 0>
				<cfset session.basket.info.totaldue = 0>
				<cfset session.basket.info.change = 0>
				<cfloop array="#session.till.catKeys#" index="loc.key">
					<cfset loc.section = StructFind(session.basket,loc.key)>
					<cfset StructUpdate(session.basket.total,loc.key,0)>
					<cfloop array="#loc.section#" index="loc.item">
						<cfset loc.style = "">
						<cfif IsStruct(loc.item)>
							<cfset loc.data = loc.item>
						<cfelse>
							<cfset loc.sectionData = StructFind(session.basket,"#loc.key#Items")>
							<cfset loc.data = StructFind(loc.sectionData,loc.item)>
						</cfif>
						<cfset loc.totalRetail -= loc.data.retail>
						<cfset session.basket.total.balance -= (loc.data.retail + loc.data.discount)>
						<cfset loc.cashtotal = loc.data.cash * loc.data.qty * loc.data.regMode>
						<cfset loc.credittotal = loc.data.credit * loc.data.qty * loc.data.regMode>
						<cfset session.basket.header.bCash -= loc.cashtotal>
						<cfset session.basket.header.bCredit -= loc.credittotal>
						<cfset session.basket.header.balance += (loc.cashtotal + loc.credittotal - loc.data.discount)>

						<cfset loc.total = StructFind(session.basket.total,loc.data.type)>
						<cfset StructUpdate(session.basket.total,loc.data.type,loc.total + loc.data.totalGross - loc.data.discount)>
						<cfset session.basket.total.discstaff += loc.data.discount>
						<cfset session.basket.header.discstaff += loc.data.discount>
						<cfif StructKeyExists(loc.data,"dealID")>
							<cfif loc.data.dealID neq 0><cfset loc.style = "dealItem"></cfif>
						</cfif>

						<cfif loc.data.vcode gt 0>
							<cfif NOT StructKeyExists(session.basket.vatAnalysis,loc.data.vcode)>
								<cfset StructInsert(session.basket.vatAnalysis,loc.data.vcode,{
									"vrate"=loc.data.vrate,"net"=loc.data.totalNet,"VAT"=loc.data.totalVat,"gross"=loc.data.totalGross,"items"=1})>
							<cfelse>
								<cfset loc.vatAnalysis = StructFind(session.basket.vatAnalysis,loc.data.vcode)>
								<cfset loc.vatAnalysis.net += loc.data.totalNet>
								<cfset loc.vatAnalysis.vat += loc.data.totalVat>
								<cfset loc.vatAnalysis.gross += loc.data.totalGross>
								<cfset loc.vatAnalysis.items++>
								<cfset StructUpdate(session.basket.vatAnalysis,loc.data.vcode,loc.vatAnalysis)>
							</cfif>
						</cfif>
					</cfloop>
				</cfloop>

				<cfif StructKeyExists(session.basket,"deals")>
					<cfset loc.qualifyingDeals = 0>
					<cfloop collection="#session.basket.deals#" item="loc.dealKey">
						<cfset loc.dealRec = StructFind(session.basket.deals,loc.dealKey)>
						<cfset loc.qualifyingDeals += loc.dealRec.dealQty>
						<cfloop collection="#loc.dealRec.VATTable#" item="loc.vatKey">
							<!--- apply discount VAT analysis to main VAT --->
							<cfset loc.vatItem = StructFind(loc.dealRec.VATTable,loc.vatKey)>
							<cfset loc.vatAnalysis = StructFind(session.basket.vatAnalysis,loc.vatKey)>
							<cfset loc.vatAnalysis.gross += loc.vatItem.saveGross>
							<cfset loc.vatAnalysis.net += loc.vatItem.saveNet>
							<cfset loc.vatAnalysis.vat += loc.vatItem.saveVAT>
							<cfset StructUpdate(session.basket.vatAnalysis,loc.vatKey,loc.vatAnalysis)>
						</cfloop>
					</cfloop>
				</cfif>
				<cfif StructKeyExists(session.basket,"deals")>
					<cfloop collection="#session.basket.deals#" item="loc.key">
						<cfset loc.data = StructFind(session.basket.deals,loc.key)>
						<cfif loc.data.dealQty neq 0>
							<cfset session.basket.total.balance -= loc.data.savingGross>
							<cfset session.basket.total.discount += loc.data.savingGross>
							<cfset session.basket.header.balance -= loc.data.savingGross>
							<cfset session.basket.header.discdeal += loc.data.savingGross>
						</cfif>
					</cfloop>
				</cfif>
				<cfset session.basket.info.totaldue = session.basket.total.balance>
				<cfset loc.payCount = 0>
				<cfloop list="#session.till.prefs.payList#" delimiters="," index="loc.pay">
					<cfset StructUpdate(session.basket.total,loc.pay,0)>
				</cfloop>
				<cfloop array="#session.basket.payments#" index="loc.item">
					<cfset loc.payCount++>

					<cfswitch expression="#loc.item.itemClass#">
						<cfcase value="CASHINDW">
							<cfset session.basket.total.cashINDW += (loc.item.cash + loc.item.credit)>
							<cfset session.basket.header.cashtaken += loc.item.cash + loc.item.credit>
							<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
						</cfcase>
						<cfcase value="CARDINDW">
							<cfset session.basket.total.cardINDW += (loc.item.cash + loc.item.credit)>
							<cfset session.basket.header.cardsales += loc.item.credit>
							<cfset session.basket.header.cashback += loc.item.cash>
							<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
						</cfcase>
						<cfcase value="CHQINDW">
							<cfset session.basket.total.chqINDW += (loc.item.cash + loc.item.credit)>
							<cfset session.basket.header.chqsales += (loc.item.cash + loc.item.credit)>
							<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
						</cfcase>
						<cfcase value="ACCINDW">
							<cfset session.basket.total.accINDW += (loc.item.cash + loc.item.credit)>
							<cfset session.basket.header.accsales += (loc.item.cash + loc.item.credit)>
							<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
						</cfcase>
						<cfdefaultcase>
							<cfset loc.payValue = StructFind(session.basket.total,loc.item.itemClass)>
							<cfset StructUpdate(session.basket.total,loc.item.itemClass,loc.payValue + (loc.item.cash + loc.item.credit))>
								<!--- TODO may fail if key not found --->
							<cfset StructUpdate(session.basket.header,loc.item.itemClass,loc.payValue + (loc.item.cash + loc.item.credit))>
							<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
						</cfdefaultcase>
					</cfswitch>
					<cfset session.basket.total.balance -= (loc.item.cash + loc.item.credit)>
				</cfloop>
				<cfif session.basket.info.itemcount gt 0>
					<cfif session.basket.info.mode eq "reg">
						<cfif session.basket.total.balance lte 0>
							<cfset session.basket.info.change = session.basket.total.balance>
							<cfset session.basket.total.cashINDW += session.basket.info.change>
							<cfset session.basket.header.cashtaken += session.basket.info.change>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
							<cfset CloseTransaction()>
						</cfif>
					<cfelse>
						<cfif session.basket.total.balance lt 0>
						<cfelse>
							<cfset session.basket.info.change = session.basket.total.balance>
							<cfset session.basket.total.cashINDW += session.basket.info.change>
							<cfset session.basket.header.cashtaken += session.basket.info.change>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
							<cfset CloseTransaction()>
						</cfif>
					</cfif>
				</cfif>
			</cfoutput>

			<cfreturn loc>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

<!--- DATABASE ROUTINES --->

	<cffunction name="WriteTotal" access="public" returntype="struct">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="numeric" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cftry>
			<cfquery name="loc.QFindKey" datasource="#GetDataSource()#">
				SELECT *
				FROM tblEPOS_Totals
				WHERE totDate='#session.till.prefs.reportDate#'
				AND totAcc='#key#'
				LIMIT 1;
			</cfquery>
			<cfif loc.QFindKey.recordcount eq 1>
				<cfquery name="loc.QUpdate" datasource="#GetDataSource()#" result="loc.QUpdateResult">
					UPDATE tblEPOS_Totals
					SET totValue = #value#
					WHERE totDate='#session.till.prefs.reportDate#'
					AND totAcc='#key#'
				</cfquery>
			<cfelse>
				<cfquery name="loc.QInsert" datasource="#GetDataSource()#" result="loc.QInsertResult">
					INSERT INTO tblEPOS_Totals (
						totDate,
						totAcc,
						totValue
					) VALUES (
						'#session.till.prefs.reportDate#',
						'#key#',
						#value#
					)
				</cfquery>
			</cfif>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
				output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="SaveTillTotals" access="public" returntype="void">
		<cfset var loc = {}>
		<cfset loc.keys = ListSort(StructKeyList(session.till.total,","),"text","ASC",",")>
		<cfloop list="#loc.keys#" index="loc.fld">
			<cfif session.till.total[loc.fld] neq 0>
				<cfset WriteTotal(loc.fld,session.till.total[loc.fld])>
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="CalcTotals" access="public" returntype="void" hint="calculate till totals.">
		<cfdump var="#session.basket.header#" label="header" expand="no">
		<cfset session.basket.total.cashINDW = session.basket.header.cashtaken + session.basket.info.change>
		<cfset session.basket.header.cashtaken += session.basket.header.balance>
		<cfset session.basket.header.balance = 0>
		<!---<cfset session.basket.info.change = 0>--->
	</cffunction>

	<cffunction name="CloseTransaction" access="public" returntype="void">
		<cfset var loc = {}>

		<cfoutput>
		<cfloop collection="#session.basket.header#" item="loc.key">
			<cfset loc.basketvalue = StructFind(session.basket.header,loc.key)><!--- #loc.key# #loc.basketvalue# --->
			<cfif StructKeyExists(session.till.header,loc.key)>
				<cfset loc.tillvalue = StructFind(session.till.header,loc.key)><!--- #loc.key# #loc.tillvalue#<br>--->
				<cfset StructUpdate(session.till.header,loc.key,loc.tillvalue + loc.basketvalue)>
			<cfelse>
				<cfset StructInsert(session.till.header,loc.key,loc.basketvalue)>
			</cfif>
		</cfloop>
		<cfloop collection="#session.basket.total#" item="loc.key">
			<cfset loc.basketvalue = StructFind(session.basket.total,loc.key)><!--- #loc.key# #loc.basketvalue# --->
			<cfif StructKeyExists(session.till.total,loc.key)>
				<cfset loc.tillvalue = StructFind(session.till.total,loc.key)><!--- #loc.key# #loc.tillvalue#<br>--->
				<cfset StructUpdate(session.till.total,loc.key,loc.tillvalue + loc.basketvalue)>
			<cfelse>
				<cfset StructInsert(session.till.total,loc.key,loc.basketvalue)>
			</cfif>
		</cfloop>
		</cfoutput>
		<!---Transaction in progress flag--->
		<cfset session.till.isTranOpen = false>
		<cfset session.till.prevtran = session.basket>
		<cfset WriteTransaction()>
		<cfset ClearBasket()>
		<cfset SaveTillTotals()>
	</cffunction>

	<cffunction name="WriteTransaction" access="public" returntype="struct">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.itemStr = "">
<!---
		<tr>
			<td colspan="5"><cfdump var="#session.basket#" label="WriteTransaction" expand="no"></td>
		</tr>
--->
		<cfif session.user.ID gt 0>
			<cfoutput>
				<cfquery name="loc.QInsertHeader" datasource="#GetDataSource()#" result="loc.QInsertHeaderResult">
					INSERT INTO tblEPOS_Header (
						ehEmployee,
						ehNet,
						<!---ehVAT,--->
						ehMode
						<!---ehType--->
	
					) VALUES (
						#session.user.ID#,	<!--- TODO check user ID --->
						#session.basket.header.bCash + session.basket.header.bCredit#,
						<!---#args.header.aVat#,--->
						'#session.basket.info.mode#'
						<!---'#args.type#'--->
					)
				</cfquery>
				<cfset loc.ID = loc.QInsertHeaderResult.generatedkey>
				<cfset session.basket.tranID = loc.ID>
				<!---<table>--->
				<cfloop list="#session.till.prefs.catlist#" index="loc.class">
					<cfif StructKeyExists(session.basket,loc.class)>
						<cfset loc.section = StructFind(session.basket,loc.class)>
						<cfloop array="#loc.section#" index="loc.item">
							<cfif IsStruct(loc.item)>
								<cfif loc.item.cash neq 0><cfset loc.method = 'cash'>
									<cfelse><cfset loc.method = 'credit'></cfif>
								<cfset loc.net = Round(loc.item.totalNet * 100) / 100>
								<cfset loc.vat = loc.item.totalGross - loc.net>
								<cfset loc.itemStr = "#loc.itemStr#,(#loc.ID#,#loc.item.itemID#,#loc.item.account#,'#loc.item.class#','#loc.item.type#'
									,'#loc.method#',#loc.item.qty#,#loc.net#,#loc.vat#)">
								<!---<tr>
									<td>#loc.ID#</td>
									<td>#loc.item.itemID#</td>
									<td>#loc.item.class#</td>
									<td>#loc.item.type#</td>
									<td>#loc.method#</td>
									<td>#loc.item.qty#</td>
									<td align="right">#loc.net#</td>
									<td align="right">#loc.vat#</td>
								</tr>--->
							<cfelse>
								<cfset loc.sectionData = StructFind(session.basket,"#loc.class#Items")>
								<cfset loc.data = StructFind(loc.sectionData,loc.item)>
								<cfif loc.data.cash neq 0><cfset loc.method = 'cash'>
									<cfelse><cfset loc.method = 'credit'></cfif>
								<cfset loc.net = Round(loc.data.totalNet * 100) / 100>
								<cfset loc.vat = loc.data.totalGross - loc.net>
								<cfset loc.itemStr = "#loc.itemStr#,(#loc.ID#,#loc.data.itemID#,2,'SALE','#loc.data.type#'
									,'#loc.method#',#loc.data.qty#,#loc.net#,#loc.vat#)">
								<!---<tr>
									<td>#loc.ID#</td>
									<td>#loc.data.itemID#</td>
									<td>'SALE'</td>
									<td>#loc.data.type#</td>
									<td>#loc.method#</td>
									<td>#loc.data.qty#</td>
									<td align="right">#loc.net#</td>
									<td align="right">#loc.vat#</td>
								</tr>--->
							</cfif>
						</cfloop>
					</cfif>
				</cfloop>
				<cfloop collection="#session.basket.deals#" item="loc.item">
					<cfset loc.data = StructFind(session.basket.deals,loc.item)>
					<cfset loc.net = Round(loc.data.savingNet * 100) / 100>
					<cfset loc.vat = loc.data.savingGross - loc.net>
					<cfset loc.itemStr = "#loc.itemStr#,(#loc.ID#,#loc.item#,2,'DISC','DEAL','credit',#loc.data.dealQty#,#loc.net#,#loc.vat#)">
					<!---<tr>
						<td>#loc.ID#</td>
						<td>#loc.item#</td>
						<td>'DISC'</td>
						<td>'DEAL'</td>
						<td>'credit'</td>
						<td>#loc.data.dealQty#</td>
						<td align="right">#loc.net#</td>
						<td align="right">#loc.vat#</td>
					</tr>--->
				</cfloop>
				<cfloop array="#session.basket.payments#" index="loc.item">
					<cfif loc.item.credit neq 0><cfset loc.method = 'credit'>
						<cfelse><cfset loc.method = 'cash'></cfif>
					<cfset loc.itemStr = "#loc.itemStr#,(#loc.ID#,#loc.item.itemID#,#loc.item.account#,'#loc.item.class#','#loc.item.itemClass#','#loc.method#',#loc.item.qty#,#loc.item.cash + loc.item.credit#,0)">
					<!---<tr>
						<td>#loc.ID#</td>
						<td>#loc.item.itemID#</td>
						<td>#loc.item.class#</td>
						<td>#loc.item.itemClass#</td>
						<td>#loc.method#</td>
						<td>#loc.item.qty#</td>
						<td align="right">#loc.item.cash + loc.item.credit#</td>
						<td align="right">0</td>
					</tr>--->
				</cfloop>
				<cfif session.basket.info.change neq 0>
					<cfset loc.itemStr = "#loc.itemStr#,(#loc.ID#,#loc.item.itemID#,2,'#loc.item.class#','CASHINDW','cash',#loc.item.qty#,#session.basket.info.change#,0)">
					<!---<tr>
						<td>#loc.ID#</td>
						<td>#loc.item.itemID#</td>
						<td>#loc.item.class#</td>
						<td>'CASHINDW'</td>
						<td>'cash'</td>
						<td>#loc.item.qty#</td>
						<td align="right">#session.basket.info.change#</td>
						<td align="right">0</td>
					</tr>--->
				</cfif>
				<!---</table>--->
				<cfset loc.itemStr = RemoveChars(loc.itemStr,1,1)>	<!--- delete leading comma --->
				<!---#loc.itemStr#--->
				<cfquery name="loc.QInsertItem" datasource="#GetDataSource()#">
					INSERT INTO tblEPOS_Items (
						eiParent,
						eiProdID,
						eiAccID,
						eiClass,
						eiType,
						eiPayType,
						eiQty,
						eiNet,
						eiVAT
					) VALUES
					#PreserveSingleQuotes(loc.itemStr)#
				</cfquery>

				<cfset loc.total.net = 0>
				<cfset loc.total.vat = 0>
				<cfset loc.total.gross = 0>
				<cfloop collection="#session.basket.vatAnalysis#" item="loc.key">
					<cfset loc.line = StructFind(session.basket.vatAnalysis,loc.key)>
					<cfset loc.total.net += loc.line.net>
					<cfset loc.total.vat += loc.line.vat>
					<cfset loc.total.gross += loc.line.gross>
				</cfloop>
				<cfquery name="loc.QUpdateHeader" datasource="#GetDataSource()#">
					UPDATE tblEPOS_Header
					SET ehNet = #loc.total.net#,
						ehVAT = #loc.total.vat#
					WHERE ehID=#loc.ID#
				</cfquery>
			</cfoutput>
		<cfelse>
			<cfset session.basket.info.errMsg = "Till operator not logged in">
		</cfif>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="WriteTransactionX" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.count = 0>
		<cfset loc.result.str = "">

		<cftry>
			<cfquery name="loc.QInsertHeader" datasource="#GetDataSource()#" result="loc.QInsertHeaderResult">
				INSERT INTO tblEPOS_Header (
					ehEmployee,
					ehNet,
					ehVAT,
					ehMode,
					ehType

				) VALUES (
					#session.user.ID#,	<!--- TODO check user ID --->
					#args.header.bCash + args.header.bCredit#,
					#args.header.aVat#,
					'#args.mode#',
					'#args.type#'
				)
			</cfquery>
			<cfset loc.ID = loc.QInsertHeaderResult.generatedkey>
			<cfset session.basket.tranID = loc.ID>
			<cfset loc.discTotal = 0>
			<table>
			<cfloop array="#args.products#" index="loc.prod">
				<cfset loc.item = StructFind(args.shopItems,loc.prod)>
				<cfset loc.count++>
				<cfif loc.item.cash neq 0>
					<cfset loc.item.payType = 'cash'>
				<cfelse>
					<cfset loc.item.payType = 'credit'>
				</cfif>
				<cfset loc.result.str = "#loc.result.str#,(#loc.ID#,'#loc.item.class#','#loc.item.type#','#loc.item.payType#'
					,#loc.item.prodID#,#loc.item.qty#,#loc.item.totalNet#,#loc.item.totalVAT#)">
				<cfset loc.discTotal += loc.item.dealTotal + loc.item.discount>
			</cfloop>
			<cfloop list="suppliers|media|news|prizes|vouchers|coupons" delimiters="|" index="loc.arr">
				<cfset loc.section = StructFind(args,loc.arr)>
				<cfloop array="#loc.section#" index="loc.item">
					<cfset loc.count++>
					<cfif loc.item.cash neq 0>
						<cfset loc.item.payType = 'cash'>
					<cfelse>
						<cfset loc.item.payType = 'credit'>
					</cfif>
					<cfset loc.result.str = "#loc.result.str#,(#loc.ID#,'#loc.item.class#','#loc.item.type#','#loc.item.payType#'
						,#loc.item.prodID#,#loc.item.qty#,#loc.item.cash + loc.item.credit#,#loc.item.VAT#)">
					<tr>
						<td>#loc.ID#</td>
						<td>#loc.item.class#</td>
						<td>#loc.item.type#</td>
						<td>#loc.item.payType#</td>
						<td>#loc.item.prodID#</td>
						<td>#loc.item.qty#</td>
						<td>#loc.item.cash + loc.item.credit#</td>
						<td>#loc.item.VAT#</td>
					</tr>
				</cfloop>
			</cfloop>
			</table>
			<cfset loc.result.str = RemoveChars(loc.result.str,1,1)>	<!--- delete leading comma --->
			<cfquery name="loc.QInserItem" datasource="#GetDataSource()#">
				INSERT INTO tblEPOS_Items (
					eiParent,
					eiClass,
					eiType,
					eiPayType,
					eiProdID,
                    eiQty,
					eiNet,
					eiVAT
				) VALUES
				#PreserveSingleQuotes(loc.result.str)#
			</cfquery>

			<cfset loc.pays = {}>
			<cfset loc.pays.cash = 0>
			<cfset loc.pays.card = 0>
			<cfset loc.pays.cardcb = 0>
			<cfset loc.pays.chq = 0>
			<cfset loc.pays.acc = 0>
			<cfset loc.accountID = 2>
			<cfoutput>
				<cfloop array="#args.payments#" index="loc.item">
					<cfset loc.count++>
					<cfset loc.value = StructFind(loc.pays,loc.item.type)>
					<cfif loc.item.cash neq 0>
						<cfset loc.item.payType = 'cash'>
					<cfelse>
						<cfset loc.item.payType = 'credit'>
					</cfif>
					<cfif loc.item.type eq "Card">
						<cfset StructUpdate(loc.pays,loc.item.type,loc.value + loc.item.credit)>
						<cfif loc.item.cash neq 0>
							<cfset loc.value = StructFind(loc.pays,"CARDCB")>
							<cfset StructUpdate(loc.pays,"CARDCB",loc.value + loc.item.cash)>
						</cfif>
					<cfelse>
						<cfset StructUpdate(loc.pays,loc.item.type,loc.value + loc.item.credit + loc.item.cash)>
						<cfif loc.item.account neq 2 AND loc.accountID eq 2><cfset loc.accountID = loc.item.account></cfif>
					</cfif>
				</cfloop>
			</cfoutput>
			<cfif args.header.change neq 0>
				<cfset loc.pays.cash += args.header.change>
			</cfif>

			<cfloop collection="#loc.pays#" item="loc.key">
				<cfset loc.value = StructFind(loc.pays,loc.key)>
				<cfif loc.value neq 0>
					<cfquery name="loc.QInserItem" datasource="#GetDataSource()#">
						INSERT INTO tblEPOS_Items (
							eiParent,
							eiClass,
							eiType,
							eiAccID,
							eiProdID,
							eiNet
						) VALUES (
							#loc.QInsertHeaderResult.generatedkey#,
							'pay',
							'#loc.key#',
							#loc.accountID#,
                            2,
							#loc.value#
						)
					</cfquery>
				</cfif>
			</cfloop>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
			output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="CalcVAT" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfif NOT StructKeyExists(session.basket.vatAnalysis,args.vcode)>
			<cfset StructInsert(session.basket.vatAnalysis,args.vcode,{"vrate"=args.vrate, "net"=args.cash + args.credit, "VAT"=args.vat, "gross"=args.gross})>
		<cfelse>
			<cfset loc.vatAnalysis = StructFind(session.basket.vatAnalysis,args.vcode)>
			<cfset loc.vatAnalysis.net += args.cash+args.credit>
			<cfset loc.vatAnalysis.vat += args.vat>
			<cfset loc.vatAnalysis.gross += args.gross>
			<cfset StructUpdate(session.basket.vatAnalysis,args.vcode,loc.vatAnalysis)>
		</cfif>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="PrintReceipt" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cftry>
			<cfset loc.result = {}>
			<cfset loc.invert = -1>
			<cfset loc.count = 0>
			<cfset loc.itemCount = 0>
			<cfset loc.netTotal = 0>

			<cfoutput>
				<div id="receipt">
					<p>#args.type# <cfif args.mode eq "reg">RECEIPT<cfelse>REFUND</cfif> &nbsp; #args.tranID#</p>
					<table class="tableList" border="1">
						<cfloop array="#args.products#" index="loc.prod">
							<cfset loc.item = StructFind(args.shopItems,loc.prod)>
							<cfset loc.netTotal += loc.item.totalGross>
							<cfset loc.itemCount += loc.item.qty>
							<tr>
								<td>SALE <cfif loc.item.cash neq 0>(cash)</cfif></td>
								<td>#loc.item.prodTitle#</td>
								<td align="right">#loc.item.qty#</td>
								<td align="right">#DecimalFormat(loc.item.retail * loc.invert)#</td>
								<td align="right">#DecimalFormat(loc.item.vrate)#%</td>
							</tr>
							<cfif val(loc.item.dealID) neq 0>
								<cfif val(loc.item.dealQty) neq 0>
									<tr>
										<td></td>
										<td>#loc.item.dealTitle#</td>
										<td align="right">#loc.item.dealQty#</td>
										<td align="right">#DecimalFormat(-loc.item.dealTotal)#</td>
										<td></td>
									</tr>
								</cfif>
							</cfif>
						</cfloop>

						<cfloop list="suppliers|media|news|prizes|vouchers|coupons" delimiters="|" index="loc.arr">
							<cfset loc.section = StructFind(args,loc.arr)>
							<cfloop array="#loc.section#" index="loc.item">
								<cfset loc.count++>
								<tr>
									<td></td>
									<td>#loc.item.type# <cfif loc.item.cash neq 0>(cash)</cfif></td>
									<td>#loc.item.title#</td>
									<td align="right">#DecimalFormat(loc.item.gross * loc.invert)#</td>
									<td>#loc.item.vcode#</td>
								</tr>
							</cfloop>
						</cfloop>
						<tr>
							<td>#loc.itemCount# items</td>
							<td class="bold">Gross Total</td>
							<td></td>
							<td align="right" class="bold">#DecimalFormat(loc.netTotal * loc.invert)#</td>
							<td></td>
						</tr>
						<tr><td colspan="5">&nbsp;</td></tr>
						<cfloop array="#args.payments#" index="loc.item">
							<cfset loc.netTotal += (loc.item.cash + loc.item.credit)>
							<tr>
								<td></td>
								<td colspan="2">#loc.item.title#</td><td align="right">#DecimalFormat((loc.item.cash + loc.item.credit))#</td><td></td>
							</tr>
						</cfloop>
						<cfif args.header.balance gte 0>
							<tr>
								<td></td>
								<td colspan="2" width="220">Change</td><td align="right">#DecimalFormat(args.header.change * loc.invert)#</td><td></td>
							</tr>
						<cfelse>
							<tr>
								<td colspan="2" width="220">Balance Due from #args.info.bod#</td><td align="right">#DecimalFormat(args.header.balance)#</td><td></td>
							</tr>
						</cfif>
						<tr>
							<td colspan="5" align="center">
								VAT SUMMARY
								<table width="80%">
									<tr>
										<td align="right">Rate</td>
										<td align="right">Net</td>
										<td align="right">VAT</td>
										<td align="right">Total</td>
									</tr>
									<cfset loc.linecount = 0>
									<cfset loc.total.net = 0>
									<cfset loc.total.vat = 0>
									<cfset loc.total.gross = 0>
									<cfloop collection="#args.vatAnalysis#" item="loc.key">
										<cfset loc.linecount++>
										<cfset loc.line = StructFind(args.vatAnalysis,loc.key)>
										<cfset loc.total.net += loc.line.net>
										<cfset loc.total.vat += loc.line.vat>
										<cfset loc.total.gross += loc.line.gross>
										<tr>
											<td align="right">#DecimalFormat(loc.line.vrate)#%</td>
											<td align="right">#DecimalFormat(loc.line.net * -1)#</td>
											<td align="right">#DecimalFormat(loc.line.vat * -1)#</td>
											<td align="right">#DecimalFormat(loc.line.gross * -1)#</td>
										</tr>
									</cfloop>
									<cfif loc.linecount gt 1>
										<tr>
											<td align="right">Total</td>
											<td align="right">#DecimalFormat(loc.total.net * -1)#</td>
											<td align="right">#DecimalFormat(loc.total.vat * -1)#</td>
											<td align="right">#DecimalFormat(loc.total.gross * -1)#</td>
										</tr>
									</cfif>
								</table>
								VAT No.: #session.till.prefs.vatno#
							</td>
						</tr>
					</table>
				</div>
				<div style="clear:both"></div>
			</cfoutput>
		<cfcatch type="any">
			<p>An error occurred printing the receipt.</p>
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
				output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cfscript>
		function bold(str) {
			return "#Chr(27)##Chr(14)##str##Chr(27)##Chr(20)#";
		};

		function rightAlign(str) {
			var spaces = ceiling(32 - len(str));
			var spacesStr = left("                                      ", abs(spaces));
			return "#spacesStr##str#";
		};

		function centerAlign(str) {
			var spaces = ceiling((32 - len(str)) / 2);
			var spacesStr = left("                                      ", abs(spaces));
			return "#spacesStr##str#";
		};

		function centerAlignBold(str) {
			var spaces = ceiling((16 - len(str)) / 2);
			var spacesStr = left("                                      ", abs(spaces));
			return "#Chr(27)##Chr(14)##spacesStr##str##Chr(27)##Chr(20)#";
		};

		function alignLeftRight(str1, str2) {
			var spaces = ceiling(31 - (len(str1) + len(str2)));
			var spacesStr = left("                                      ", abs(spaces));
			return "#str1##spacesStr##str2#";
		};

		function alignRightLeftRight(str1, str2, str3) {
			if (len(str1) lt 3 && str1 neq "-") {
				var pad = 3 - len(str1);
				var padSpaces = left("          ", abs(pad));
				str1 = "#padSpaces##str1#";
			}

			var spaces = ceiling(31 - (5 + len(str2) + len(str3)));
			var spacesStr = left("                                      ", abs(spaces));

			if (str1 eq "-") {
				str1 = "   ";
			}

			if (str3 eq "-") {
				str3 = "  ";
			}

			return "#str1#  #str2##spacesStr##str3#";
		};
	</cfscript>

	<cffunction name="PrintASCIIReceipt" access="public" returntype="any">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cftry>
			<cfset loc.contentResult = "">
			<cfset loc.result = {}>
			<cfset loc.invert = -1>
			<cfset loc.count = 0>
			<cfset loc.itemCount = 0>
			<cfset loc.netTotal = 0>
			<cfset loc.dateNow = LSDateFormat(Now(), "dd/mm/yyyy")>
			<cfset loc.timeNow = LSTimeFormat(Now(), "HH:mm")>

			<cfsavecontent variable="loc.contentResult">
				<cfoutput>
					<!---Code Page = West Europe--->
					<!---GBP Sign = 163--->
					#Chr(27)##Chr(112)#011<!---OPEN TILL DRAWER--->
					#Chr(27)##Chr(64)#
					#Chr(27)##Chr(50)#
					#Chr(27)#6
					#Chr(10)##Chr(10)#
					#centerAlignBold("Shortlanesend")#
					#Chr(10)#
					#centerAlignBold("Store")#
					#Chr(10)##Chr(10)#
					#centerAlign(application.company.telephone)#
					#Chr(10)#
					#centerAlign("VAT No. #application.company.vat_number#")#
					#Chr(10)##Chr(10)#
					<cfif session.basket.info.mode eq "rfd">
						Refund
						#Chr(10)##Chr(10)#
					</cfif>
					#alignLeftRight("Served By: #session.user.firstName# #Left(session.user.lastName, 1)#", "Ref: #args.tranID#")#
					#alignLeftRight("#loc.dateNow#", "#loc.timeNow#")#
					#Chr(10)##Chr(10)#
					#alignRightLeftRight("QTY", "DESCRIPTION", "AMOUNT")#

					<cfloop array="#args.products#" index="loc.prod">
						<cfset loc.item = StructFind(args.shopItems,loc.prod)>
						<cfset loc.netTotal += loc.item.totalGross>
						<cfset loc.itemCount += loc.item.qty>
						<cfset loc.lineTotal = loc.item.retail * loc.invert>

						<cfset loc.item.lenSpace = 32 - (10 + len(DecimalFormat(loc.lineTotal)))>
						<cfset loc.item.titleArr = ListToArray(loc.item.prodTitle, " ")>
						<cfset loc.curLen = 0>
						<cfset loc.item.title1 = "">
						<cfset loc.item.title2 = "">

						<cfloop array="#loc.item.titleArr#" index="loc.i">
							<cfset loc.curLen += len(loc.i)>
							<cfif loc.curLen lt loc.item.lenSpace>
								<cfset loc.item.title1 = loc.item.title1 & "#loc.i# ">
							<cfelse>
								<cfset loc.item.title2 = loc.item.title2 & "#loc.i# ">
							</cfif>
						</cfloop>

						<cfif len(loc.item.title1)>
							#alignRightLeftRight("#loc.item.qty#", "#REReplaceNoCase(loc.item.title1, '£', '#Chr(163)#')#", "#DecimalFormat(loc.lineTotal)#")#
						</cfif>
						<cfif len(loc.item.title2)>
							#alignRightLeftRight("-", "#REReplaceNoCase(loc.item.title2, '£', '#Chr(163)#')#", "-")#
						</cfif>

						<cfif val(loc.item.dealID) neq 0>
							<cfif val(loc.item.dealQty) neq 0>
								#alignRightLeftRight("#loc.item.dealQty#", "#REReplaceNoCase(loc.item.dealTitle, '£', '#Chr(163)#')#", "#DecimalFormat(-loc.item.dealTotal)#")#
							</cfif>
						</cfif>
					</cfloop>

					<cfloop list="suppliers|media|news|prizes|vouchers|coupons" delimiters="|" index="loc.arr">
						<cfset loc.section = StructFind(args,loc.arr)>
						<cfloop array="#loc.section#" index="loc.item">
							<cfset loc.count++>
							#alignRightLeftRight("#loc.item.qty#", "#REReplaceNoCase(loc.item.title, '£', '#Chr(163)#')#", "#DecimalFormat(loc.item.gross * loc.invert)#")#
						</cfloop>
					</cfloop>

					#alignLeftRight("Gross Total", "#Chr(163)##DecimalFormat(loc.netTotal * loc.invert)#")#
					<cfloop array="#args.payments#" index="loc.item">
						<cfset loc.netTotal += (loc.item.cash + loc.item.credit)>
						<cfif (val(loc.item.cash) + val(loc.item.credit)) gt 0>
							#alignLeftRight("#loc.item.title#", "#Chr(163)##DecimalFormat((loc.item.cash + loc.item.credit))#")#
						<cfelse>
							<cfset args.header.balance = 0>
							<cfset args.header.change = (val(loc.item.cash) + val(loc.item.credit))>
						</cfif>
					</cfloop>
					<cfif args.header.balance gte 0>
						#alignLeftRight("Change Due", "#Chr(163)##DecimalFormat(args.header.change * loc.invert)#")#
					<cfelse>
						#alignLeftRight("Balance Due from #args.info.bod#", "#Chr(163)##DecimalFormat(args.header.balance)#")#
					</cfif>
				</cfoutput>
			</cfsavecontent>

			<cfcatch type="any">
				<p>An error occurred printing the receipt.</p>
				<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
					output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
			</cfcatch>
		</cftry>

		<cfreturn loc.contentResult>
	</cffunction>

	<cffunction name="ShowBasketReceipt" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cftry>
			<cfset loc.result = {}>
			<cfset loc.invert = -1>
			<cfset loc.count = 0>
			<cfset loc.itemCount = 0>
			<cfset loc.netTotal = 0>

			<cfoutput>
				<table class="eposBasketTable" border="0" width="100%">
					<tr class="ebt_headers">
						<td align="left">Description</td>
						<td align="right">Qty</td>
						<td align="right">Total</td>
					</tr>
					<cfloop array="#args.shop#" index="loc.prod">
						<cfset loc.item = StructFind(args.shopItems,loc.prod)>
						<cfset loc.netTotal += loc.item.totalGross>
						<cfset loc.itemCount += loc.item.qty>
						<tr class="ebr_item">
							<td align="left">#loc.item.prodTitle#</td>
							<td align="right">#loc.item.qty#</td>
							<td align="right">#DecimalFormat(loc.item.retail * loc.invert)#</td>
						</tr>
						<cfif val(loc.item.dealID) neq 0>
							<cfif val(loc.item.dealQty) neq 0>
								<tr class="ebr_deal">
									<td align="left">#loc.item.dealTitle#</td>
									<td align="right">#loc.item.dealQty#</td>
									<td align="right">#DecimalFormat(-loc.item.dealTotal)#</td>
								</tr>
							</cfif>
						</cfif>
					</cfloop>

					<cfloop list="suppliers|media|news|prizes|vouchers|coupons" delimiters="|" index="loc.arr">
						<cfset loc.section = StructFind(args,loc.arr)>
						<cfloop array="#loc.section#" index="loc.item">
							<cfset loc.count++>
							<tr>
								<td align="left">#loc.item.title#</td>
								<td align="right">#loc.item.qty#</td>
								<td align="right">#DecimalFormat(loc.item.gross * loc.invert)#</td>
							</tr>
						</cfloop>
					</cfloop>
				</table>
				<div class="ebt_totals_w2">
					<table class="ebr_receipt_payments" width="100%" border="0">
						<tr class="etw2_gross">
							<td align="left">Gross Total</td>
							<td align="right">#loc.itemCount# items</td>
							<td align="right">#DecimalFormat(loc.netTotal * loc.invert)#</td>
						</tr>
						<cfloop array="#args.payments#" index="loc.item">
							<cfset loc.netTotal += (loc.item.cash + loc.item.credit)>
							<cfif (val(loc.item.cash) + val(loc.item.credit)) gt 0>
								<tr class="etw2_payitem">
									<td align="left" colspan="2">#loc.item.title#</td>
									<td align="right">#DecimalFormat((loc.item.cash + loc.item.credit))#</td>
								</tr>
							<cfelse>
								<cfset args.header.balance = 0>
								<cfset args.header.change = (val(loc.item.cash) + val(loc.item.credit))>
							</cfif>
						</cfloop>
						<cfif args.header.balance gte 0>
							<tr class="etw2_changedue h_green">
								<td align="left" colspan="2">Change Due</td>
								<td align="right">#DecimalFormat(args.header.change * loc.invert)#</td>
							</tr>
						<cfelse>
							<tr class="etw2_balancedue h_red">
								<td align="left" colspan="2">Balance Due from #args.info.bod#</td>
								<td align="right">#DecimalFormat(args.header.balance)#</td>
							</tr>
						</cfif>
					</table>
				</div>
			</cfoutput>
		<cfcatch type="any">
			<p>An error occurred showing the receipt.</p>
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
				output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="VATSummary" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>

		<cftry>
			<cfoutput>
			<table class="eposBasketTable" border="0" width="100%">
				<tr>
					<td colspan="5" align="center">
						VAT SUMMARY
						<table width="80%">
							<tr>
								<th align="right">Rate</th>
								<th align="right">Net</th>
								<th align="right">VAT</th>
								<th align="right">Total</th>
							</tr>
							<cfset loc.linecount = 0>
							<cfset loc.total.net = 0>
							<cfset loc.total.vat = 0>
							<cfset loc.total.gross = 0>
							<cfloop collection="#args#" item="loc.key">
								<cfset loc.linecount++>
								<cfset loc.line = StructFind(args,loc.key)>
								<cfset loc.total.net += loc.line.net>
								<cfset loc.total.vat += loc.line.vat>
								<cfset loc.total.gross += loc.line.gross>
								<tr>
									<td align="right">#DecimalFormat(loc.line.vrate)#%</td>
									<td align="right">#DecimalFormat(loc.line.net * -1)#</td>
									<td align="right">#DecimalFormat(loc.line.vat * -1)#</td>
									<td align="right">#DecimalFormat(loc.line.gross * -1)#</td>
								</tr>
							</cfloop>
							<cfif loc.linecount gt 1>
								<tr>
									<td align="right">Total</td>
									<td align="right">#DecimalFormat(loc.total.net * -1)#</td>
									<td align="right">#DecimalFormat(loc.total.vat * -1)#</td>
									<td align="right">#DecimalFormat(loc.total.gross * -1)#</td>
								</tr>
							</cfif>
							<cfset loc.diff = session.basket.info.totaldue + loc.total.gross>
							<cfif abs(loc.diff) gt 0.01>
								<tr>
									<td colspan="4" align="center"><b class="mismatch">WARNING - MISMATCH #loc.diff#</b></td>
								</tr>
							</cfif>
						</table>
						VAT No.: #session.till.prefs.vatno#
					</td>
				</tr>
			</table>
			</cfoutput>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="GetAccounts" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>

		<cftry>
			<cfquery name="loc.result.Accounts" datasource="#GetDataSource()#">
				SELECT eaID,eaTitle
				FROM tblEPOS_Account
			</cfquery>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
			output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="GetDates" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.result.recs =[]>
		<cfset loc.today = false>
		<cftry>
			<cfquery name="loc.QDates" datasource="#GetDataSource()#">
				SELECT DATE(totDate) AS dateOnly
				FROM tblEPOS_Totals
				WHERE 1
				GROUP BY dateOnly
				ORDER BY dateOnly DESC
			</cfquery>
			<cfloop query="loc.QDates">
				<cfset loc.today = loc.today OR (LSDateFormat(dateOnly,"yyyy-mm-dd") eq LSDateFormat(Now(),"yyyy-mm-dd"))>
				<cfset ArrayAppend(loc.result.recs,{"value"=LSDateFormat(dateOnly,"yyyy-mm-dd"),"title"=LSDateFormat(dateOnly,"dd-mmm-yyyy")})>
			</cfloop>
			<cfif NOT loc.today>
				<cfset ArrayPrepend(loc.result.recs,{"value"=LSDateFormat(Now(),"yyyy-mm-dd"),"title"=LSDateFormat(Now(),"dd-mmm-yyyy")})>
			</cfif>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
			output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="LoadTillTotals" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>

		<cftry>
			<cfset ZTill(args.form.reportDate)>
			<cfquery name="loc.QTotals" datasource="#GetDataSource()#" result="loc.QQueryResult">
				SELECT *
				FROM tblEPOS_Totals
				WHERE totDate='#session.till.prefs.reportDate#'
			</cfquery>
			<cfloop query="loc.QTotals">
				<cfset StructInsert(session.till.total,totAcc,totValue,true)>
			</cfloop>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
				output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="LoadDeals" access="public" returntype="void" hint="Load deal info.">
		<cfargument name="args" type="struct" required="no" default="{}">
		<cftry>
		<cfset loc = {}>
		<cfquery name="loc.QActiveDeals" datasource="#GetDataSource()#">
			SELECT *
			FROM tblEPOS_Deals
			WHERE edStatus = 'active'
			AND edEnds > #Now()#
		</cfquery>
		<cfset session.deals = loc.QActiveDeals>
		<cfset session.dealdata = {}>
		<cfloop query="loc.QActiveDeals">
			<cfset StructInsert(session.dealdata,edID,{
				"edType" = edType,
				"edDealType" = edDealType,
				"edTitle" = edTitle,
				"edQty" = edQty,
				"edAmount" = edAmount,
				"edStarts" = LSDateFormat(edStarts,'yyyy-mm-dd'),
				"edEnds" = LSDateFormat(edEnds,'yyyy-mm-dd')
			})>
		</cfloop>
		<cfquery name="loc.QualifyingProducts" datasource="#GetDataSource()#">
			SELECT ediProduct,ediParent
			FROM tblEPOS_DealItems
			INNER JOIN tblEPOS_Deals ON ediParent = edID
			WHERE edStatus = 'active'
			AND edStarts <= #Now()#		<!--- TODO check time issues --->
			AND edEnds > #Now()#
		</cfquery>
		<cfset session.dealIDs = {}>
		<cfloop query="loc.QualifyingProducts">
			<cfif StructKeyExists(session.dealIDs,ediProduct)>
				<cfset loc.item = StructFind(session.dealIDs,ediProduct)>
			<cfelse>
				<cfset StructInsert(session.dealIDs,ediProduct,ediParent)>
			</cfif>
		</cfloop>
		<cfset session.qualys = loc.QualifyingProducts>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
				output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="LoadVAT" access="public" returntype="void">
		<cftry>
			<cfset var loc = {}>
			<cfquery name="loc.QVAT" datasource="#GetDataSource()#">
				SELECT vatCode,vatRate,vatTitle
				FROM tblVATRates
				WHERE vatCode>0
			</cfquery>
			<cfset session.VAT = {}>
			<cfloop query="loc.QVAT">
				<cfset StructInsert(session.VAT,vatRate,vatCode)>
			</cfloop>
		<cfcatch type="any">
			<cfdump var="#loc.QVAT#" label="LoadVAT" expand="yes" format="html"
				output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="LoadCatKeys" access="public" returntype="void">
		<cfset var loc = {}>

		<cftry>
			<cfquery name="loc.QEPOSCatKeys" datasource="#GetDataSource()#">
				SELECT DISTINCT epcKey,epcType FROM tblEPOSCats
			</cfquery>
			<cfset session.till.prefs.catList = "">
			<cfset session.till.prefs.payList = "">
			<cfset StructInsert(session.till,"CATKEYS",[],true)>
			<cfloop query="loc.QEPOSCatKeys">
				<cfif epcType eq 'OUT'>
					<cfset session.till.prefs.catList = ListAppend(session.till.prefs.catList,epcKey,",")>
					<cfset ArrayAppend(session.till.catKeys,epcKey)>
				<cfif NOT StructKeyExists(session.basket,epcKey)>
					<cfset StructInsert(session.basket,epcKey,[])>
				</cfif>
				<cfelse>
					<cfset session.till.prefs.payList = ListAppend(session.till.prefs.payList,epcKey,",")>
				</cfif>
				<cfif NOT StructKeyExists(session.basket.total,epcKey)>
					<cfset StructInsert(session.basket.total,epcKey,0)>
				</cfif>
			</cfloop>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>
</cfcomponent>