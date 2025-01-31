<!---28/04/2024--->
<cfcomponent displayname="EPOS15" hint="version 15. EPOS Till Functions">

	<cfset this.closeTranNow = false>

	<cffunction name="GetDataSource" access="public" returntype="string">
		<cfreturn application.site.datasource1>
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

	<cffunction name="ZTill" access="public" returntype="void" hint="initialise till at start of day.">
		<cfargument name="loadDate" type="date" required="yes">
		<cfset StructDelete(session,"till",false)>
		<cfset session.till = {}>

		<cfset session.till.isTranOpen = false>	<!---Transaction in progress flag--->

		<cfset session.till.total = {}>
		<cfset session.till.header = {}>
		<cfset session.till.info = {}>
		<cfset session.till.prevtran = {}>
		<cfset session.till.catKeys = []>
		<cfset session.till.total.float = -application.site.initialFloat>
		<cfset session.till.total.cashINDW = application.site.initialFloat>
		<cfset session.till.prefs.mincard = 0.00>
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
		<cftry>
			<cflock scope="session" timeout="60" type="exclusive" throwontimeout="yes">
				<cfif StructKeyExists(session,"basket")>
					<cfset StructDelete(session,"basket",false)>
				</cfif>
				<cfset session.basket = {}>
				<cfset session.basket.deals = {}>
				<cfset session.basket.header = {}>
				<cfset session.basket.total = {}>
				<cfset session.basket.info = {}>
				<cfset session.basket.shopItems = {}>
				<cfset session.basket.mediaItems = {}>
				<cfset session.basket.magsItems = {}>
				<cfset session.basket.voucherItems = {}>
				<cfset session.basket.trans = []>
				<cfset session.basket.tranID = 0>
				<cfset session.basket.lastItemAdded = {}>
				<cfset LoadCatKeys()>
		
				<cfset session.basket.info.mode = "reg">
				<cfset session.basket.info.type = "SALE">
				<cfset session.basket.info.bod = "Customer">
				<cfset session.basket.info.ageCheck = false>
				<cfset session.basket.info.checkout = false>
				<cfset session.basket.info.service = 0>
				<cfset session.basket.info.errMsg = "">
				<cfset session.basket.info.itemcount = 0>
				<cfset session.basket.info.totaldue = 0>
				<cfset session.basket.info.canClose = false>
				<cfset session.basket.info.busy = false>
				<cfset session.basket.info.showTotal = false>
				<cfset session.till.info.staff = false>
		
				<cfset session.basket.payments = []>
				<cfset session.basket.news = []>
				<cfset session.basket.bunnery = []>
				<cfset session.basket.lottery = []>
				<cfset session.basket.scratchcard = []>
				<cfset session.basket.lprize = []>
				<cfset session.basket.sprize = []>
				<cfset session.basket.voucher = []>
				<cfset session.basket.vatAnalysis = {}>
		
				<cfset session.basket.header.bCash = 0>
				<cfset session.basket.header.bCredit = 0>
				<cfset session.basket.header.LPrize = 0>
				<cfset session.basket.header.SPrize = 0>
				<cfset session.basket.header.voucher = 0>
				<cfset session.basket.header.cpn = 0>
				<cfset session.basket.header.hsv = 0>
		
				<cfset session.basket.header.cashtaken = 0>
				<cfset session.basket.header.cardsales = 0>
				<cfset session.basket.header.chqsales = 0>
				<cfset session.basket.header.accsales = 0>
				<cfset session.basket.header.BANKXFR = 0>
				<cfset session.basket.header.BANKXFRsales = 0>
				<cfset session.basket.header.ONLINE = 0>
				<cfset session.basket.header.ONLINEsales = 0>
				<cfset session.basket.header.WASTE = 0>
				<cfset session.basket.header.discdeal = 0>
				<cfset session.basket.header.discstaff = 0>
				<cfset session.basket.header.cashback = 0>
				<cfset session.basket.header.balance = 0>
		
				<cfset session.basket.total.chqINDW = 0>
				<cfset session.basket.total.accINDW = 0>
				<cfset session.basket.total.BANKXFR = 0>
				<cfset session.basket.total.ONLINE = 0>
				<cfset session.basket.total.WASTE = 0>
				<cfset session.basket.total.balance = 0>
				<cfset session.basket.total.discount = 0>
				<cfset session.basket.total.discstaff = 0>
				<cfset this.closeTranNow = false>
			</cflock>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="ClearBasket" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="ProcessDeals" access="public" returntype="void">
		<cfset var loc = {}>
		<cftry>
			<cfset loc.tranType = -1>
			<cfset loc.rec.regMode = (2 * int(session.basket.info.mode neq "rfd")) - 1>	<!--- modes: reg = 1 waste = 1 refund = -1 --->
			<cfset session.basket.trans = []>
			<cfset loc.today = CreateDate(year(now()),month(now()),day(now()))>
			<cfloop collection="#session.basket.deals#" item="loc.dealKey">
				<cfset loc.dealData = StructFind(session.dealData,loc.dealKey)>
				<cfset loc.dealRec = StructFind(session.basket.deals,loc.dealKey)>
				<cfif ArrayLen(loc.dealRec.prices)><cfset ArraySort(loc.dealRec.prices,"text","ASC")></cfif>	<!--- use DESC to optimise for customer --->
				<cfset loc.dealRec.VATTable = {}>
				<cfset loc.dealRec.dealQty = 0>
				<cfset loc.dealRec.netTotal = 0>
				<cfset loc.dealRec.dealTotal = 0>
				<cfset loc.dealRec.groupRetail = 0>
				<cfset loc.dealRec.savingGross = 0>
				<cfset loc.dealRec.lastQual = 0>
				<cfset loc.dealRec.remQty = 0>
				<cfset loc.count = 0>
				<cfset loc.start = 1>
				<cfif loc.dealData.edEnds gte loc.today>
					<cfswitch expression="#loc.dealData.edDealType#">

						<cfcase value="nodeal">
							<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
								<cfset loc.count++>
								<cfset loc.itemDiscount = 0>
								<cfset loc.prodID = ListLast(loc.priceKey," ")>
								<cfset loc.data = StructFind(session.basket.shopItems,loc.prodID)>
								<cfset loc.data.discount = 0>
								<cfset loc.dealRec.lastQual = loc.count>
								<cfset loc.dealRec.dealQty++>
								<cfif session.till.info.staff AND loc.data.discountable>	<!--- staff sale and is a discountable item --->
									<cfset loc.itemDiscount = int(loc.data.unitPrice * 100 * session.till.prefs.discount) / 100>
									<cfset loc.data.discount = loc.itemDiscount * loc.data.qty * loc.rec.regMode>
								</cfif>
								<cfset loc.tran = {}>
								<cfset loc.tran.prop = 1>
								<cfset loc.tran.cashonly = loc.data.cash neq 0>
								<cfset loc.tran.prodID = loc.prodID>
								<cfset loc.tran.itemClass = loc.data.itemClass>
								<cfset loc.tran.unitTrade = loc.data.unitTrade>
								<cfset loc.tran.price = loc.data.unitPrice>
								<cfset loc.tran.vrate = loc.data.vrate>
								<cfset loc.tran.vcode = loc.data.vcode>
								<cfset loc.tran.discount = loc.data.discount>
								<cfset loc.tran.gross = loc.tran.price - loc.itemDiscount>
								<cfif loc.tran.vrate neq 0>
									<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
									<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
								<cfelse>
									<cfset loc.tran.net = loc.tran.gross>
									<cfset loc.tran.vat = 0>								
								</cfif>
								<cfset loc.tran.qty = 1 * loc.rec.regMode> 

								<cfset loc.tran.gross = loc.tran.gross * loc.tranType * loc.rec.regMode>
								<cfset loc.tran.net = loc.tran.net * loc.tranType * loc.rec.regMode>
								<cfset loc.tran.vat = loc.tran.vat * loc.tranType * loc.rec.regMode>

								<cfset ArrayAppend(session.basket.trans,loc.tran)>
							</cfloop>
						</cfcase>

						<cfcase value="anyfor|twofor" delimiters="|">
							<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
								<cfset loc.count++>
								<cfset loc.price = ListFirst(loc.priceKey," ")>
								<cfset loc.prodID = ListLast(loc.priceKey," ")>
								<cfset loc.dealRec.groupRetail += loc.price>
								<cfset loc.dealRec.remQty = loc.count MOD loc.dealData.edQty>

								<cfif loc.dealRec.remQty eq 0>
									<cfset loc.totalGross = 0>
									<cfset loc.dealRec.lastQual = loc.count>
									<cfset loc.dealRec.dealQty++>
									<cfset loc.dealRec.dealTotal = loc.dealRec.dealQty * loc.dealData.edAmount>
									<cfset loc.totProp = 0>
									<cfloop from="#loc.start#" to="#loc.count#" index="loc.i">
										<cfset loc.tran = {}>
										<cfset loc.tran.prodID = ListLast(loc.dealRec.prices[loc.i]," ")>
										<cfset loc.data = StructFind(session.basket.shopItems,loc.tran.prodID)>
										<cfset loc.data.discount = 0>
										<cfset loc.data.style = "red">

										<cfset loc.tran.cashonly = loc.data.cash neq 0>
										<cfset loc.tran.vrate = loc.data.vrate>
										<cfset loc.tran.vcode = loc.data.vcode>
										<cfset loc.tran.itemClass = loc.data.itemClass>
										<cfset loc.tran.unitTrade = loc.data.unitTrade>
										<cfset loc.tran.price = loc.data.unitprice>
										<!---<cfset loc.tran.prop = Round((loc.tran.price / loc.dealRec.groupRetail) * 100) / 100>--->
										<cfset loc.tran.prop = int((loc.tran.price / loc.dealRec.groupRetail) * 1000) / 1000>
										<cfif loc.i gte loc.count>
											<cfset loc.tran.prop = 1 - loc.totProp> <!--- make total of proportions add up to 1.00 --->
											<cfset loc.tran.gross = loc.dealData.edAmount - loc.totalGross>
										<cfelse>
											<cfset loc.tran.gross = Round(loc.dealData.edAmount * loc.tran.prop * 100) / 100>										
										</cfif>
										<cfset loc.totalGross += loc.tran.gross>
										<cfset loc.totProp += loc.tran.prop>
										<cfif loc.tran.vrate neq 0>
											<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
											<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
										<cfelse>
											<cfset loc.tran.net = loc.tran.gross>
											<cfset loc.tran.vat = 0>								
										</cfif>

										<cfset loc.tran.qty = 1 * loc.rec.regMode>

										<cfset loc.tran.gross = loc.tran.gross * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.net = loc.tran.net * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.vat = loc.tran.vat * loc.tranType * loc.rec.regMode>

										<cfset ArrayAppend(session.basket.trans,loc.tran)>
									</cfloop>
									<cfset loc.dealRec.groupRetail = 0>
									<cfset loc.start = loc.count + 1>
								</cfif>								
							</cfloop>
							<cfif loc.dealRec.lastQual lt loc.count>
								<cfloop from="#loc.dealRec.lastQual + 1#" to="#loc.count#" index="loc.i">
									<cfset loc.tran = {}>
									<cfset loc.itemDiscount = 0>
									<cfset loc.tran.prodID = ListLast(loc.dealRec.prices[loc.i]," ")>
									<cfset loc.data = StructFind(session.basket.shopItems,loc.tran.prodID)>
									<cfset loc.data.discount = 0>
									<cfset loc.data.style = "red">

									<cfset loc.tran.price = ListFirst(loc.dealRec.prices[loc.i]," ") * 1>
									<cfset loc.tran.cashonly = loc.data.cash neq 0>
									<cfif session.till.info.staff AND loc.data.discountable>	<!--- staff sale and is a discountable item --->
										<cfset loc.itemDiscount = int(loc.data.unitPrice * 100 * session.till.prefs.discount) / 100>
										<cfset loc.data.discount = loc.itemDiscount * (loc.data.qty - loc.dealRec.lastQual) * loc.rec.regMode>
									</cfif>

									<cfset loc.tran.prop = 1>
									<cfset loc.tran.vrate = loc.data.vrate>
									<cfset loc.tran.vcode = loc.data.vcode>
									<cfset loc.tran.itemClass = loc.data.itemClass>
									<cfset loc.tran.unitTrade = loc.data.unitTrade>
									<cfset loc.tran.price = loc.data.unitPrice>
									<cfif loc.itemDiscount neq 0>
										<cfset loc.tran.gross = int((loc.tran.price - loc.itemDiscount) * 100) / 100>
									<cfelse><cfset loc.tran.gross = loc.tran.price></cfif>
									<cfif loc.tran.vrate neq 0>
										<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
										<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
									<cfelse>
										<cfset loc.tran.net = loc.tran.gross>
										<cfset loc.tran.vat = 0>								
									</cfif>

									<cfset loc.tran.qty = 1 * loc.rec.regMode>
									
									<cfset loc.tran.gross = loc.tran.gross * loc.tranType * loc.rec.regMode>
									<cfset loc.tran.net = loc.tran.net * loc.tranType * loc.rec.regMode>
									<cfset loc.tran.vat = loc.tran.vat * loc.tranType * loc.rec.regMode>

									<cfset ArrayAppend(session.basket.trans,loc.tran)>
								</cfloop>
							</cfif>
							<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
							<cfset loc.dealRec.savingGross = loc.dealRec.retail - loc.dealRec.totalCharge>
							<cfset loc.dealRec.totalCharge = loc.dealRec.totalCharge * loc.rec.regMode>
							<cfset loc.dealRec.savingGross = loc.dealRec.savingGross * loc.rec.regMode>
						</cfcase>
						
						<cfcase value="only">
							<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
								<cfset loc.count++>
								<cfset loc.price = ListFirst(loc.priceKey," ")>
								<cfset loc.prodID = ListLast(loc.priceKey," ")>
								<cfif loc.dealRec.remQty eq 0>
									<cfset loc.dealRec.lastQual = loc.count>
									<cfset loc.dealRec.dealQty++>
									<cfset loc.dealRec.dealTotal = loc.dealRec.dealQty * loc.dealData.edAmount>
									<cfloop from="#loc.start#" to="#loc.count#" index="loc.i">
										<cfset loc.tran = {}>
										<cfset loc.tran.prodID = ListLast(loc.dealRec.prices[loc.i]," ")>
										<cfset loc.data = StructFind(session.basket.shopItems,loc.tran.prodID)>
										<cfset loc.tran.cashonly = loc.data.cash neq 0>
										<cfset loc.tran.price = loc.data.unitPrice>
										<cfset loc.data.discount = 0>
										<cfset loc.data.style = "red">
										<cfset loc.tran.vrate = loc.data.vrate>
										<cfset loc.tran.vcode = loc.data.vcode>
										<cfset loc.tran.itemClass = loc.data.itemClass>
										<cfset loc.tran.unitTrade = loc.data.unitTrade>
										<cfset loc.tran.prop = 1>
										<cfset loc.tran.gross = Round(loc.dealData.edAmount * 100) / 100>
										<cfif loc.tran.vrate neq 0>
											<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
											<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
										<cfelse>
											<cfset loc.tran.net = loc.tran.gross>
											<cfset loc.tran.vat = 0>								
										</cfif>
										<cfset loc.tran.qty = 1 * loc.rec.regMode>

										<cfset loc.tran.gross = loc.tran.gross * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.net = loc.tran.net * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.vat = loc.tran.vat * loc.tranType * loc.rec.regMode>
										
										<cfset ArrayAppend(session.basket.trans,loc.tran)>
									</cfloop>
									<cfset loc.dealRec.groupRetail = 0>
									<cfset loc.start = loc.count + 1>
								</cfif>
							</cfloop>
							<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
							<cfset loc.dealRec.savingGross = loc.dealRec.retail - loc.dealRec.totalCharge>
							<cfset loc.dealRec.totalCharge = loc.dealRec.totalCharge * loc.rec.regMode>
							<cfset loc.dealRec.savingGross = loc.dealRec.savingGross * loc.rec.regMode>
						</cfcase>

						<cfcase value="bogof">
							<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
								<cfset loc.count++>
								<cfset loc.price = ListFirst(loc.priceKey," ")>
								<cfset loc.prodID = ListLast(loc.priceKey," ")>
								<cfset loc.dealRec.groupRetail += loc.price>
								<cfset loc.dealRec.remQty = loc.count MOD loc.dealData.edQty>
								<cfif loc.dealRec.remQty eq 0>
									<cfset loc.dealRec.lastQual = loc.count>
									<cfset loc.dealRec.dealQty++>
									<cfset loc.dealRec.dealTotal = loc.dealRec.dealQty * loc.dealData.edAmount>
									<cfloop from="#loc.start#" to="#loc.count#" index="loc.i">
										<cfset loc.tran = {}>
										<cfset loc.tran.prodID = ListLast(loc.dealRec.prices[loc.i]," ")>
										<cfset loc.data = StructFind(session.basket.shopItems,loc.tran.prodID)>
										<cfset loc.tran.cashonly = loc.data.cash neq 0>
										<cfset loc.tran.price = loc.data.unitPrice>
										<cfset loc.data.discount = 0>
										<cfset loc.data.style = "red">
										<cfset loc.tran.vrate = loc.data.vrate>
										<cfset loc.tran.vcode = loc.data.vcode>
										<cfset loc.tran.itemClass = loc.data.itemClass>
										<cfset loc.tran.unitTrade = loc.data.unitTrade>
										<cfset loc.tran.prop = 1>
										<cfset loc.tran.gross = int((loc.data.unitPrice) * 100) / 100>
										<cfif loc.i MOD 2 IS 0>
											<cfset loc.tran.gross = 0>
										</cfif>
										<cfif loc.tran.vrate neq 0>
											<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
											<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
										<cfelse>
											<cfset loc.tran.net = loc.tran.gross>
											<cfset loc.tran.vat = 0>								
										</cfif>
										<cfset loc.tran.qty = 1 * loc.rec.regMode>

										<cfset loc.tran.gross = loc.tran.gross * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.net = loc.tran.net * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.vat = loc.tran.vat * loc.tranType * loc.rec.regMode>

										<cfset ArrayAppend(session.basket.trans,loc.tran)>
									</cfloop>
									<cfset loc.dealRec.groupRetail = 0>
									<cfset loc.start = loc.count + 1>
								</cfif>
							</cfloop>
							<cfif loc.dealRec.lastQual lt loc.count>
								<cfloop from="#loc.dealRec.lastQual + 1#" to="#loc.count#" index="loc.i">
									<cfset loc.tran = {}>
									<cfset loc.itemDiscount = 0>
									<cfset loc.tran.price = ListFirst(loc.dealRec.prices[loc.i]," ") * 1>
									<cfset loc.tran.prodID = ListLast(loc.dealRec.prices[loc.i]," ")>
									<cfset loc.data = StructFind(session.basket.shopItems,loc.tran.prodID)>
									<cfset loc.tran.cashonly = loc.data.cash neq 0>
									<cfset loc.tran.price = loc.data.unitPrice>
									<cfif session.till.info.staff AND loc.data.discountable>	<!--- staff sale and is a discountable item --->
										<cfset loc.itemDiscount = int(loc.data.unitPrice * 100 * session.till.prefs.discount) / 100>
										<cfset loc.data.discount = loc.itemDiscount * (loc.data.qty - loc.dealRec.lastQual) * loc.rec.regMode>
									</cfif>
									<cfset loc.tran.prop = 1>
									<cfset loc.tran.vrate = loc.data.vrate>
									<cfset loc.tran.vcode = loc.data.vcode>
									<cfset loc.tran.itemClass = loc.data.itemClass>
									<cfset loc.tran.unitTrade = loc.data.unitTrade>
									<cfset loc.tran.gross = int((loc.tran.price - loc.itemDiscount) * 100) / 100>
									<cfif loc.tran.vrate neq 0>
										<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
										<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
									<cfelse>
										<cfset loc.tran.net = loc.tran.gross>
										<cfset loc.tran.vat = 0>								
									</cfif>
									<cfset loc.tran.qty = 1 * loc.rec.regMode>

									<cfset loc.tran.gross = loc.tran.gross * loc.tranType * loc.rec.regMode>
									<cfset loc.tran.net = loc.tran.net * loc.tranType * loc.rec.regMode>
									<cfset loc.tran.vat = loc.tran.vat * loc.tranType * loc.rec.regMode>

									<cfset ArrayAppend(session.basket.trans,loc.tran)>
								</cfloop>
							</cfif>
							<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
							<cfset loc.dealRec.savingGross = loc.dealRec.retail - loc.dealRec.totalCharge>
							<cfset loc.dealRec.totalCharge = loc.dealRec.totalCharge * loc.rec.regMode>
							<cfset loc.dealRec.savingGross = loc.dealRec.savingGross * loc.rec.regMode>
						</cfcase>

						<cfcase value="halfprice">
							<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
								<cfset loc.count++>
								<cfset loc.price = ListFirst(loc.priceKey," ")>
								<cfset loc.prodID = ListLast(loc.priceKey," ")>
								<cfif loc.dealRec.remQty eq 0>
									<cfset loc.dealRec.lastQual = loc.count>
									<cfset loc.dealRec.dealQty++>
									<cfset loc.dealRec.dealTotal = loc.dealRec.dealQty * loc.dealData.edAmount>
									<cfloop from="#loc.start#" to="#loc.count#" index="loc.i">
										<cfset loc.tran = {}>
										<cfset loc.tran.prodID = ListLast(loc.dealRec.prices[loc.i]," ")>
										<cfset loc.data = StructFind(session.basket.shopItems,loc.tran.prodID)>
										<cfset loc.tran.cashonly = loc.data.cash neq 0>
										<cfset loc.tran.price = loc.data.unitPrice>
										<cfset loc.data.discount = 0>
										<cfset loc.data.style = "red">
										<cfset loc.tran.vrate = loc.data.vrate>
										<cfset loc.tran.vcode = loc.data.vcode>
										<cfset loc.tran.itemClass = loc.data.itemClass>
										<cfset loc.tran.unitTrade = loc.data.unitTrade>
										<cfset loc.tran.prop = 1>
										<cfset loc.tran.gross = Round(int((loc.data.unitPrice / 2) * 100)) / 100>
										<cfif loc.tran.vrate neq 0>
											<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
											<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
										<cfelse>
											<cfset loc.tran.net = loc.tran.gross>
											<cfset loc.tran.vat = 0>								
										</cfif>
										<cfset loc.tran.qty = 1 * loc.rec.regMode>

										<cfset loc.tran.gross = loc.tran.gross * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.net = loc.tran.net * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.vat = loc.tran.vat * loc.tranType * loc.rec.regMode>

										<cfset ArrayAppend(session.basket.trans,loc.tran)>
									</cfloop>
									<cfset loc.dealRec.groupRetail = 0>
									<cfset loc.start = loc.count + 1>
								</cfif>
							</cfloop>
							<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
							<cfset loc.dealRec.savingGross = loc.dealRec.retail - loc.dealRec.totalCharge>
							<cfset loc.dealRec.totalCharge = loc.dealRec.totalCharge * loc.rec.regMode>
							<cfset loc.dealRec.savingGross = loc.dealRec.savingGross * loc.rec.regMode>
						</cfcase>

						<cfcase value="b1g1hp">
							<cfset loc.disc = 0>
							<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
								<cfset loc.count++>
								<cfset loc.price = ListFirst(loc.priceKey," ")>
								<cfset loc.prodID = ListLast(loc.priceKey," ")>
								<cfset loc.dealRec.remQty = loc.count MOD loc.dealData.edQty>
								<cfif loc.dealRec.remQty eq 0>
									<cfset loc.totalGross = 0>
									<cfset loc.dealRec.lastQual = loc.count>
									<cfset loc.dealRec.dealQty++>
									<cfset loc.dealRec.dealTotal = Round((loc.dealRec.dealQty * loc.price * 0.5) * 100) / 100>
									<cfloop from="#loc.start#" to="#loc.count#" index="loc.i">
										<cfset loc.tran = {}>
										<cfset loc.tran.prodID = ListLast(loc.dealRec.prices[loc.i]," ")>
										<cfset loc.data = StructFind(session.basket.shopItems,loc.tran.prodID)>
										<cfset loc.tran.cashonly = loc.data.cash neq 0>
										<cfset loc.data.discount = 0>
										<cfset loc.data.style = "red">
										<cfset loc.tran.vrate = loc.data.vrate>
										<cfset loc.tran.vcode = loc.data.vcode>
										<cfset loc.tran.itemClass = loc.data.itemClass>
										<cfset loc.tran.unitTrade = loc.data.unitTrade>
										<cfset loc.tran.prop = 1>
										<cfif loc.i MOD 2 eq 0>
											<cfset loc.tran.gross = int((loc.data.unitPrice * 0.5) * 100) / 100>
										<cfelse>
											<cfset loc.tran.gross = int(loc.data.unitPrice * 100) / 100>
										</cfif>
										<cfset loc.disc += loc.data.unitPrice + loc.tran.gross>
										<cfset loc.totalGross -= loc.tran.gross>
										<cfif loc.tran.vrate neq 0>
											<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
											<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
										<cfelse>
											<cfset loc.tran.net = loc.tran.gross>
											<cfset loc.tran.vat = 0>								
										</cfif>
										<cfset loc.tran.qty = 1 * loc.rec.regMode>

										<cfset loc.tran.gross = loc.tran.gross * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.net = loc.tran.net * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.vat = loc.tran.vat * loc.tranType * loc.rec.regMode>

										<cfset ArrayAppend(session.basket.trans,loc.tran)>
									</cfloop>
									<cfset loc.dealRec.groupRetail = 0>
									<cfset loc.start = loc.count + 1>
								</cfif>
							</cfloop>
							<cfif loc.dealRec.lastQual lt loc.count>
								<cfloop from="#loc.dealRec.lastQual + 1#" to="#loc.count#" index="loc.i">
									<cfset loc.tran = {}>
									<cfset loc.itemDiscount = 0>
									<cfset loc.tran.prodID = ListLast(loc.dealRec.prices[loc.i]," ")>
									<cfset loc.data = StructFind(session.basket.shopItems,loc.tran.prodID)>
									<cfif session.till.info.staff AND loc.data.discountable>	<!--- staff sale and is a discountable item --->
										<cfset loc.itemDiscount = int(loc.data.unitPrice * 100 * session.till.prefs.discount) / 100>
										<cfset loc.data.discount = loc.itemDiscount * (loc.data.qty - loc.dealRec.lastQual) * loc.rec.regMode>
									</cfif>

									<cfset loc.tran.cashonly = loc.data.cash neq 0>
									<cfset loc.tran.price = loc.data.unitPrice>
									<cfset loc.tran.prop = 1>
									<cfset loc.tran.vrate = loc.data.vrate>
									<cfset loc.tran.vcode = loc.data.vcode>
									<cfset loc.tran.itemClass = loc.data.itemClass>
									<cfset loc.tran.unitTrade = loc.data.unitTrade>
									<cfset loc.tran.gross = int((loc.tran.price - loc.itemDiscount) * 100) / 100>
									<cfif loc.tran.vrate neq 0>
										<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
										<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
									<cfelse>
										<cfset loc.tran.net = loc.tran.gross>
										<cfset loc.tran.vat = 0>								
									</cfif>
									<cfset loc.tran.qty = 1 * loc.rec.regMode>

									<cfset loc.tran.gross = loc.tran.gross * loc.tranType * loc.rec.regMode>
									<cfset loc.tran.net = loc.tran.net * loc.tranType * loc.rec.regMode>
									<cfset loc.tran.vat = loc.tran.vat * loc.tranType * loc.rec.regMode>

									<cfset ArrayAppend(session.basket.trans,loc.tran)>
								</cfloop>
							</cfif>
							<cfset loc.dealRec.totalCharge = loc.dealRec.Retail - loc.disc>
							<cfset loc.dealRec.totalCharge = loc.dealRec.totalCharge * loc.rec.regMode>
							<cfset loc.dealRec.savingGross = loc.dealRec.savingGross * loc.rec.regMode>
							<cfset loc.dealRec.savingGross = loc.disc>
						</cfcase>

					</cfswitch>
				<cfelse>
					<cfset loc.dealRec.msg = "deal expired">
				</cfif>
			</cfloop>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="ProcessDeals" expand="yes" format="html"
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="CheckDeals" access="public" returntype="void" hint="check basket for qualifying deals.">
		<cfset var loc = {}>
		<cftry>
			<cfset loc.rec.regMode = (2 * int(session.basket.info.mode neq "rfd")) - 1>	<!--- modes: reg = 1 waste = 1 refund = -1 --->
			<cfset session.basket.deals = {}>
			<cfloop collection="#session.basket.shopItems#" item="loc.key">
				<cfset loc.item = StructFind(session.basket.shopItems,loc.key)>
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
			</cfloop>

			<cfset ProcessDeals()>
			
			<cfloop collection="#session.basket.mediaItems#" item="loc.key">
				<cfset loc.media = StructFind(session.basket.mediaItems,loc.key)>
				<cfset loc.tran = {}>
				<cfset loc.tran.cashonly = loc.media.cash neq 0>
				<cfset loc.tran.price = loc.media.unitPrice>
				<cfset loc.tran.pubID = loc.media.itemID>
				<cfset loc.tran.prop = 1>
				<cfset loc.tran.gross = loc.media.totalGross>
				<cfset loc.tran.vrate = loc.media.vrate>
				<cfset loc.tran.vcode = loc.media.vcode>
				<cfset loc.tran.unittrade = loc.media.unittrade>
				<cfset loc.tran.itemClass = loc.media.itemClass>
				<cfif loc.tran.vrate neq 0>
					<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
					<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
				<cfelse>
					<cfset loc.tran.net = loc.tran.gross>
					<cfset loc.tran.vat = 0>								
				</cfif>
				<cfset loc.tran.qty = 1 * loc.rec.regMode>
				<cfset ArrayAppend(session.basket.trans,loc.tran)>
			</cfloop>

			<cfloop collection="#session.basket.magsItems#" item="loc.key">
				<cfset loc.mags = StructFind(session.basket.magsItems,loc.key)>
				<cfset loc.tran = {}>
				<cfset loc.tran.cashonly = loc.mags.cash neq 0>
				<cfset loc.tran.price = loc.mags.unitPrice>
				<cfset loc.tran.prodID = loc.mags.itemID>
				<cfset loc.tran.prop = 1>
				<cfset loc.tran.gross = loc.mags.totalGross>
				<cfset loc.tran.vrate = loc.mags.vrate>
				<cfset loc.tran.vcode = loc.mags.vcode>
				<cfset loc.tran.itemClass = loc.mags.itemClass>
				<cfif loc.tran.vrate neq 0>
					<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
					<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
				<cfelse>
					<cfset loc.tran.net = loc.tran.gross>
					<cfset loc.tran.vat = 0>								
				</cfif>
				<cfset loc.tran.qty = 1 * loc.rec.regMode>
				<cfset ArrayAppend(session.basket.trans,loc.tran)>
			</cfloop>

			<cfloop collection="#session.basket.voucherItems#" item="loc.key">
				<cfset loc.vch = StructFind(session.basket.voucherItems,loc.key)>
				<cfset loc.tran = {}>
				<cfset loc.tran.cashonly = 1>
				<cfset loc.tran.price = loc.vch.unitPrice>
				<cfset loc.tran.prodID = loc.vch.itemID>
				<cfset loc.tran.prop = 1>
				<cfset loc.tran.gross = loc.vch.totalGross>
				<cfset loc.tran.vrate = loc.vch.vrate>
				<cfset loc.tran.vcode = loc.vch.vcode>
				<cfset loc.tran.itemClass = loc.vch.itemClass>
				<cfif loc.tran.vrate neq 0>
					<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
					<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
				<cfelse>
					<cfset loc.tran.net = loc.tran.gross>
					<cfset loc.tran.vat = 0>								
				</cfif>
				<cfset loc.tran.qty = 1 * loc.rec.regMode>
				<cfset ArrayAppend(session.basket.trans,loc.tran)>
			</cfloop>

			<cfloop array="#session.till.catKeys#" index="loc.key">
				<cfset loc.section = StructFind(session.basket,loc.key)>
				<cfloop array="#loc.section#" index="loc.item">
					<cfif IsStruct(loc.item)>
						<cfset loc.data = loc.item>
						<cfset loc.tran = {}>
						<cfset loc.tran.supplier = 0>
						<cfset loc.tran.price = loc.data.unitPrice>
						<cfset loc.tran.prodID = loc.data.itemID>
						<cfset loc.tran.cashonly = loc.data.cash neq 0>
						<cfset loc.tran.prop = 1>
						<cfset loc.tran.account = loc.data.account>
						<cfif StructKeyExists(loc.data,"supplier")><cfset loc.tran.supplier = loc.data.supplier></cfif>
						<cfset loc.tran.itemClass = loc.data.itemClass>
						<cfset loc.tran.gross = loc.data.totalGross>
						<cfset loc.tran.vrate = loc.data.vrate>
						<cfset loc.tran.vcode = loc.data.vcode>
						<cfif loc.tran.vrate neq 0>
							<cfset loc.tran.net = int(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
							<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
						<cfelse>
							<cfset loc.tran.net = loc.tran.gross>
							<cfset loc.tran.vat = 0>								
						</cfif>
						<cfset loc.tran.qty = 1 * loc.rec.regMode>
						<cfset ArrayAppend(session.basket.trans,loc.tran)>
					</cfif>
				</cfloop>
			</cfloop>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="CheckDeals" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
			<cfdump var="#loc#" label="CheckDeals" expand="yes" format="html"
				output="#application.site.dir_logs#epos\errdeal-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="UpdateBasket" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cftry>

			<cfset var loc = {}>
			<cfif args.data.prodClass eq "single">
				<cfset loc.itemKey = "#args.data.itemID#-#args.data.unitPrice#">
			<cfelse>
				<cfset loc.itemKey = args.data.itemID>
			</cfif>
			<cfset loc.insertItem = false>
			<cfset loc.tranType = -1>
			<cfset loc.section = StructFind(session.basket,"#args.form.itemClass#ITEMS")>
			<cfset loc.sectionArray = StructFind(session.basket,args.form.itemClass)>
			<!---<cfset session.till.isTranOpen = true>--->

			<cfif StructKeyExists(loc.section,loc.itemKey)>
				<cfset loc.rec = StructFind(loc.section,loc.itemKey)>
			<cfelse>
				<cfset loc.insertItem = true>
				<cfset loc.rec = {}>
				<cfset loc.rec.itemID = args.data.itemID>
				<cfset loc.rec.title = args.data.title>
				<cfset loc.rec.unitsize = args.data.unitsize>
				<cfset loc.rec.unittrade = args.data.unittrade>
				<cfset loc.rec.vrate = args.form.vrate>
				<cfset loc.rec.prodClass = args.data.prodClass>
				<cfset loc.rec.prodSign = args.data.prodSign>
				<cfset loc.rec.vcode = args.data.vcode>
				<cfset loc.rec.itemClass = args.form.itemClass>
				<cfset loc.rec.qty = 0>
			</cfif>

			<cfset loc.rec.regMode = (2 * int(session.basket.info.mode neq "rfd")) - 1>	<!--- modes: reg = 1 waste = 1 refund = -1 --->
			<cfset loc.vatRate = 1 + (val(loc.rec.vrate) / 100)>
			<cfset loc.rec.discountable = StructKeyExists(args.form,"discountable") AND args.form.discountable>
			<cfset loc.rec.cashonly = args.form.cashonly>
			<!---<cfset loc.rec.unitTrade = args.form.unitTrade>--->
			<cfset loc.rec.cash = args.data.cash>
			<cfset loc.rec.credit = args.data.credit>
			<cfset loc.rec.unitPrice = loc.rec.cash + loc.rec.credit>
			<cfif StructKeyExists(args.data,"origprice")><cfset loc.rec.origprice = args.data.origprice></cfif>

			<cfset loc.rec.qty += args.form.qty>		<!--- accumulate qty with any previous value. can be +/- --->
			<cfset loc.rec.discount = 0>	<!--- reset any previously assigned discount amount for this product --->
			<cfif loc.rec.qty lte 0>
				<cfset StructDelete(loc.section,loc.itemKey,false)>
				<cfset ArrayDelete(loc.sectionArray,loc.itemKey)>
			<cfelse>
				<cfset loc.rec.retail = loc.rec.qty * loc.rec.unitPrice>
				<cfset loc.rec.totalGross = loc.rec.retail>
				<cfset loc.rec.dealID = 1>	<!--- reset to no deal --->
				<cfif StructKeyExists(session.dealIDs,args.form.prodID)>	<!--- product deals only --->
					<cfset loc.rec.dealID = StructFind(session.dealIDs,args.form.prodID)>
				</cfif>

				<cfset loc.rec.totalNet = int(loc.rec.totalGross / loc.vatRate * 100) / 100>
				<cfset loc.rec.totalVAT = loc.rec.totalGross - loc.rec.totalNet>

				<cfset loc.rec.retail = loc.rec.retail * loc.rec.regMode * loc.tranType>
				<cfset loc.rec.totalGross = loc.rec.totalGross * loc.rec.regMode * loc.tranType>
				<cfset loc.rec.totalNet = loc.rec.totalNet * loc.rec.regMode * loc.tranType>
				<cfset loc.rec.totalVAT = loc.rec.totalVAT * loc.rec.regMode * loc.tranType>
				<!---<cfset loc.rec.discount = loc.rec.discount * loc.rec.regMode * loc.tranType>--->
			</cfif>
			<cfif loc.insertItem>	<!--- if item not in struct --->
				<cfset StructInsert(loc.section,loc.itemKey,loc.rec)>
				<cfset ArrayAppend(loc.sectionArray,loc.itemKey)>
			<cfelseif loc.rec.qty gt 0>
				<cfset StructUpdate(loc.section,loc.itemKey,loc.rec)>
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
		<cfset loc.vatrate = 1 + (val(args.vrate) / 100)>

		<cfset args.regMode = (2 * int(session.basket.info.mode neq "rfd")) - 1>	<!--- modes: reg = 1 waste = 1 refund = -1 --->
		<cfset args.unitPrice = args.cash + args.credit>
		<cfset args.retail = args.qty * args.unitPrice>
		<cfset args.totalGross = args.retail>
		<cfset args.totalNet = int(args.totalGross / loc.vatRate * 100) / 100>
		<cfset args.totalVAT = args.totalGross - args.totalNet>

		<cfset args.retail = args.retail * args.regMode * loc.tranType>
		<cfset args.totalGross = args.totalGross * args.regMode * loc.tranType>
		<cfset args.totalNet = args.totalNet * args.regMode * loc.tranType>
		<cfset args.totalVAT = args.totalVAT * args.regMode * loc.tranType>
		<cfset session.basket.info.itemcount += args.qty>
	</cffunction>

	<cffunction name="AddItem" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		
		<cflock scope="session" timeout="60" type="exclusive" throwontimeout="yes">
		<!--- Store this item as the last added --->
		<!--- Used in the customer display --->
		<cfset session.basket.lastItemAdded = args>

		<!--- Trim whitespace on class --->
		<cfset args.form.itemClass = trim(args.form.itemClass)>

		<!---
			parameters
			args.form.prodSign
			args.form.prodID
			args.form.pubID
			args.form.prodTitle
			args.form.siUnitSize
			args.form.pubTitle
			args.form.itemClass
			args.form.account
			args.form.qty
			args.form.cash
			args.form.credit
			args.form.vrate
			args.form.addToBasket
			args.form.payID
		--->

		<cfset loc.result = {}>
		<cfset loc.result.err = "">
		<cfif session.basket.info.busy>
			<cfset loc.result.err = "System busy...">
			<cfset session.basket.info.errMsg = loc.result.err>
			<cfreturn loc.result>
			<cfexit>
		</cfif>
		<cfset session.basket.info.busy = false>	<!--- was true --->
		
<!---
<cfdump var="#args#" label="AddItem" expand="yes" format="html" 
	output="#application.site.dir_logs#epos\item-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">

<cfdump var="#session#" label="AddItem" expand="yes" format="html" 
	output="#application.site.dir_logs#epos\slow-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
--->		
		<cftry>
			<cfif session.user.id eq 0>
				<cfset session.basket.info.errMsg = "Session timed out. Please log-in to the till before serving.">
				<cfset loc.result.err = session.basket.info.errMsg>
				<cfset session.basket.info.busy = false>
				<cfreturn loc.result>
			</cfif>
			<cfif session.basket.info.checkout>
				<cfset session.basket.info.errMsg = "Are you sure you want to add more items to this basket?.">
				<cfset loc.result.err = session.basket.info.errMsg>
				<cfset session.basket.info.checkout = false>
				<cfset session.basket.info.busy = false>
				<cfreturn loc.result>
			</cfif>
			<cfif val(args.form.prodSign) eq 0>
				<cfset loc.result.err = "Product sign must be 1 or -1. Check product record.">
				<cfset session.basket.info.errMsg = "Invalid product information supplied to AddItem function.">
				<cfdump var="#args#" label="Invalid AddItem" expand="yes" format="html"
					output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
				<cfset session.basket.info.busy = false>
				<cfreturn loc.result>
			</cfif>
			<cfset session.till.isTranOpen = true>
			<cfset session.basket.info.errMsg = "">
			<!--- convert form vars to data vars --->
			<cfif val(args.form.prodID) gt 0>	<!--- product passed --->
				<cfset args.form.pubID = 1>
				<cfset args.data.itemID = args.form.prodID>
				<cfset args.data.unitsize = args.form.unitSize>
				<cfset args.data.title = args.form.prodTitle>
			<cfelseif val(args.form.pubID) gt 0>	<!--- publication passed --->
				<cfset args.form.prodID = 1>
				<cfset args.data.itemID = args.form.pubID>
				<cfset args.data.title = args.form.pubTitle>
				<cfset args.data.unitsize = ''>
			<cfelse>	<!--- TODO then what? --->
				<cfset args.data.itemID = 1>
			</cfif>
			<!--- sanitise input fields --->
			<cfset args.data.class = "item">	<!--- item = sale, pay = payment --->
			<cfset args.data.itemClass = args.form.itemClass>	<!--- sales centre, e.g. shop,lottery,paystation --->
			<cfset args.data.prodClass = args.form.prodClass>	<!--- single or multiple (see notes) --->
			<cfset args.data.discount = 0>
			<cfset args.data.account = val(args.form.account)>
			<cfset args.data.prodSign = args.form.prodSign>
			<cfset args.data.qty = val(args.form.qty)>
			<cfset args.data.cash = abs(val(args.form.cash)) * args.form.prodSign>
			<cfset args.data.credit = abs(val(args.form.credit)) * args.form.prodSign>
			<cfset args.data.vrate = val(args.form.vrate)>
			<cfset args.data.vcode = StructFind(session.vat,DecimalFormat(args.form.vrate))>

			<cfif StructKeyExists(args.form,"origPrice")><cfset args.data.origPrice = args.form.origPrice></cfif>

			<cfif args.data.itemClass neq "SUPPLIER" AND ArrayLen(session.basket.supplier) gt 0>
				<cfset session.basket.info.errMsg = "Cannot start a sales transaction during a supplier transaction.">
				<cfset loc.result.err = session.basket.info.errMsg>
			<cfelseif args.data.itemClass eq "SUPPLIER" AND ArrayLen(session.basket.shop) gt 0>
				<cfset session.basket.info.errMsg = "Cannot pay a supplier during a sales transaction.">
				<cfset loc.result.err = session.basket.info.errMsg>
			<cfelse>

				<cfswitch expression="#UCASE(args.form.itemClass)#">
					<cfcase value="PAYSTATION">
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfif args.data.cash neq 0>
							<cfif args.form.addToBasket>
								<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
								<cfset args.data.gross = args.data.cash>
								<cfset CalcValues(args.data)>
								<cfset ArrayAppend(session.basket.paystation,args.data)>
							<cfelse>
								<cfset loc.ppcount = 0>
								<cfloop array="#session.basket.paystation#" index="loc.pp">
									<cfset loc.ppcount++>
									<cfif loc.pp.itemID eq args.data.itemID AND loc.pp.unitPrice eq args.data.cash>
										<cfset ArrayDeleteAt(session.basket.paystation,loc.ppcount)>
										<cfbreak>
									</cfif>
								</cfloop>
							</cfif>
							<cfset CheckDeals()>
						<cfelse>
							<cfset session.basket.info.errMsg = "Invalid #args.form.itemClass# amount entered.">
						</cfif>
					</cfcase>
					<cfcase value="SRV">
						<cfset args.data.credit = args.data.cash + args.data.credit>
						<cfif args.form.addToBasket>
							<cfif args.data.credit neq 0 AND session.basket.info.service eq 0>	<!--- only add once--->
								<cfset args.data.cash = 0>	<!--- force empty - only use credit figure --->
								<cfset args.data.gross = args.data.credit>	<!--- calc gross transaction value --->
								<cfset session.basket.info.service = args.data.credit>	<!--- remember if service charge added --->
								<cfset args.data.qty = 1>
								<cfset CalcValues(args.data)>
								<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.srv,args.data)></cfif>
								<cfset CheckDeals()>
							<cfelse>
								<cfset session.basket.info.errMsg = "The service charge has already been added.">
							</cfif>
						<cfelse>
							<cfif ArrayLen(session.basket.srv) eq 1>
								<cfset ArrayDeleteAt(session.basket.srv,1)>
								<cfset session.basket.info.service = 0>	<!--- remove service charge --->
								<cfset CheckDeals()>
							</cfif>
						</cfif>
					</cfcase>
					<cfcase value="LOTTERY">
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfif args.form.addToBasket>
							<cfif args.data.cash neq 0>
								<cfset args.data.class = "lot">
								<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
								<cfset args.data.gross = args.data.cash>	<!--- calc gross transaction value --->
								<cfset CalcValues(args.data)>
								<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.lottery,args.data)></cfif>
								<cfset CheckDeals()>
							<cfelse>
								<cfset session.basket.info.errMsg = "Invalid #args.form.itemClass# amount entered.">
							</cfif>
						<cfelse>
							<cfset loc.itemCount = 0>
							<cfloop array="#session.basket.lottery#" index="loc.lot">
								<cfset loc.itemCount++>
								<cfif loc.lot.itemID eq args.data.itemID AND loc.lot.unitPrice eq args.data.cash>
									<cfset ArrayDeleteAt(session.basket.lottery,loc.itemCount)>
									<cfbreak>
								</cfif>
							</cfloop>
							<cfset CheckDeals()>
						</cfif>
					</cfcase>
					<cfcase value="SCRATCHCARD">
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfif args.form.addToBasket>
							<cfif args.data.cash neq 0>
								<cfset args.data.class = "lot">
								<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
								<cfset args.data.gross = args.data.cash>	<!--- calc gross transaction value --->
								<cfset CalcValues(args.data)>
								<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.scratchcard,args.data)></cfif>
								<cfset CheckDeals()>
							<cfelse>
								<cfset session.basket.info.errMsg = "Invalid #args.form.itemClass# amount entered.">
							</cfif>
						<cfelse>
							<cfset loc.itemCount = 0>
							<cfloop array="#session.basket.scratchcard#" index="loc.lot">
								<cfset loc.itemCount++>
								<cfif loc.lot.itemID eq args.data.itemID AND loc.lot.unitPrice eq args.data.cash>
									<cfset ArrayDeleteAt(session.basket.scratchcard,loc.itemCount)>
									<cfbreak>
								</cfif>
							</cfloop>
							<cfset CheckDeals()>
						</cfif>
					</cfcase>
					<cfcase value="LPRIZE">
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfif args.form.addToBasket>
							<cfif args.data.cash neq 0>
								<cfset args.data.class = "lot">
								<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
								<cfset args.data.gross = args.data.cash>	<!--- calc gross transaction value --->
								<cfset CalcValues(args.data)>
								<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.lprize,args.data)></cfif>
								<cfset CheckDeals()>
							<cfelse>
								<cfset session.basket.info.errMsg = "Invalid #args.form.itemClass# amount entered.">
							</cfif>
						<cfelse>
							<cfset loc.itemCount = 0>
							<cfloop array="#session.basket.lprize#" index="loc.lot">
								<cfset loc.itemCount++>
								<cfif loc.lot.itemID eq args.data.itemID AND loc.lot.unitPrice eq (args.data.cash * args.data.qty)>
									<cfset ArrayDeleteAt(session.basket.lprize,loc.itemCount)>
									<cfbreak>
								</cfif>
							</cfloop>
							<cfset CheckDeals()>
						</cfif>
					</cfcase>
					<cfcase value="SPRIZE">
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfif args.form.addToBasket>
							<cfif args.data.cash neq 0>
								<cfset args.data.class = "lot">
								<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
								<cfset args.data.gross = args.data.cash>	<!--- calc gross transaction value --->
								<cfset CalcValues(args.data)>
								<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.sprize,args.data)></cfif>
								<cfset CheckDeals()>
							<cfelse>
								<cfset session.basket.info.errMsg = "Invalid #args.form.itemClass# amount entered.">
							</cfif>
						<cfelse>
							<cfset loc.itemCount = 0>
							<cfloop array="#session.basket.sprize#" index="loc.lot">
								<cfset loc.itemCount++>
								<cfif loc.lot.itemID eq args.data.itemID AND loc.lot.unitPrice eq (args.data.cash * args.data.qty)>
									<cfset ArrayDeleteAt(session.basket.sprize,loc.itemCount)>
									<cfbreak>
								</cfif>
							</cfloop>
							<cfset CheckDeals()>
						</cfif>
					</cfcase>
					<cfcase value="NEWS">
						<cfif args.form.addToBasket>
							<cfif args.data.credit + args.data.cash neq 0>
								<cfset args.data.gross = args.data.credit + args.data.cash>	<!--- calc gross transaction value --->
								<cfset CalcValues(args.data)>
								<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.news,args.data)></cfif>
								<cfset CheckDeals()>
							<cfelse>
								<cfset session.basket.info.errMsg = "Invalid #args.form.itemClass# amount entered.">
							</cfif>
						<cfelse>
							<cfset loc.itemCount = 0>
							<cfloop array="#session.basket.news#" index="loc.news">
								<cfset loc.itemCount++>
								<cfif loc.news.itemID eq args.data.itemID AND loc.news.unitPrice eq args.data.credit>
									<cfset ArrayDeleteAt(session.basket.news,loc.itemCount)>
									<cfbreak>
								</cfif>
							</cfloop>
							<cfset CheckDeals()>
						</cfif>
					</cfcase>
					<cfcase value="BUNNERY">
						<cfif args.form.addToBasket>
							<cfif args.data.credit + args.data.cash neq 0>
								<cfset args.data.gross = args.data.credit + args.data.cash>	<!--- calc gross transaction value --->
								<cfset CalcValues(args.data)>
								<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.bunnery,args.data)></cfif>
								<cfset CheckDeals()>
							<cfelse>
								<cfset session.basket.info.errMsg = "Invalid #args.form.itemClass# amount entered.">
							</cfif>
						<cfelse>
							<cfset loc.itemCount = 0>
							<cfloop array="#session.basket.bunnery#" index="loc.bunnery">
								<cfset loc.itemCount++>
								<cfif loc.bunnery.itemID eq args.data.itemID AND loc.bunnery.unitPrice eq args.data.credit>
									<cfset ArrayDeleteAt(session.basket.bunnery,loc.itemCount)>
									<cfbreak>
								</cfif>
							</cfloop>
							<cfset CheckDeals()>
						</cfif>
					</cfcase>
					<cfcase value="ACCPAY">
						<cfif args.form.addToBasket>
							<cfset args.data.credit = args.data.cash + args.data.credit>
							<cfif args.data.account lt 2>
								<cfset loc.result.err = "">
								<cfset session.basket.info.errMsg = "Please select which Account to credit.">
							<cfelse>
								<cfif args.data.credit neq 0>
									<cfset args.data.cash = 0>	 <!---force empty - only use credit figure --->
									<cfset CalcValues(args.data)>
									<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.accpay,args.data)></cfif>
									<cfset CheckDeals()>
								<cfelse>
									<cfset session.basket.info.errMsg = "Please enter the amount paid onto account.">
								</cfif>
							</cfif>
						<cfelse>
							<cfset loc.itemCount = 0>
							<cfloop array="#session.basket.accpay#" index="loc.accpay">
								<cfset loc.itemCount++>
								<cfif loc.accpay.itemID eq args.data.itemID AND loc.accpay.unitPrice eq args.data.credit>
									<cfset ArrayDeleteAt(session.basket.accpay,loc.itemCount)>
									<cfbreak>
								</cfif>
							</cfloop>
							<cfset CheckDeals()>
						</cfif>
					</cfcase>
					<cfcase value="VOUCHER">
						<cfif args.form.addToBasket>
							<cfset args.data.gross = args.data.credit + args.data.cash>	<!--- calc gross transaction value --->
							<cfif ArrayLen(session.basket.media) eq 0>
								<cfset session.basket.info.errMsg = "Please put a news item in the basket before accepting a voucher.">
							<cfelseif args.data.gross is 0>
								<cfset session.basket.info.errMsg = "Please enter the voucher value.">
							<cfelseif abs(args.data.gross + session.basket.total.voucher) gt abs(session.basket.total.media)>
								<cfset session.basket.info.errMsg = "Voucher total cannot exceed newspaper total.">
							<cfelse>
								<cfif args.data.gross neq 0>
									<cfset CalcValues(args.data)>
									<cfset ArrayAppend(session.basket.voucher,args.data)>
									<cfset CheckDeals()>
								<cfelse>
									<cfset session.basket.info.errMsg = "Invalid #args.form.itemClass# amount entered.">
								</cfif>
							</cfif>
						<cfelse>
							<cfset loc.itemCount = 0>
							<cfloop array="#session.basket.voucher#" index="loc.voucher">
								<cfset loc.itemCount++>
								<cfif loc.voucher.itemID eq args.data.itemID AND loc.voucher.retail eq args.data.credit>
									<cfset ArrayDeleteAt(session.basket.voucher,loc.itemCount)>
									<cfbreak>
								</cfif>
							</cfloop>
							<cfset CheckDeals()>
						</cfif>
					</cfcase>
					<cfcase value="SUPPLIER">
						<cfif ArrayLen(session.basket.supplier) GT 0>
							<cfset session.basket.info.errMsg = "You can only pay one supplier at a time.">
						<cfelse>
							<cfset args.data.cash = args.data.cash + args.data.credit>
							<cfif args.data.cash neq 0>
								<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
								<cfset args.data.gross = args.data.cash>	<!--- calc gross transaction value --->
								<cfset args.data.supplier = args.data.itemID>
								<cfset session.basket.info.type = "PURCH">	<!--- set receipt title --->
								<cfset session.basket.info.bod = "Supplier">
								<cfset CalcValues(args.data)>
								<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.supplier,args.data)></cfif>
								<cfset CheckDeals()>
							<cfelse>
								<cfset session.basket.info.errMsg = "Invalid #args.form.itemClass# amount entered.">
							</cfif>
						</cfif>
					</cfcase>
					<cfdefaultcase>
						<cfif ListFind(session.till.prefs.catlist,args.form.itemClass,",")>
							<cfif args.data.credit + args.data.cash neq 0>
								<cfif StructKeyExists(args.form,"sign")>
									<cfset args.data.cash = args.data.cash * args.form.sign>
									<cfset args.data.credit = args.data.credit * args.form.sign>
								</cfif>
								<cfif StructKeyExists(args.form,"unitTrade") AND args.form.unitTrade neq 0>
									<cfset args.data.unitTrade = args.form.unitTrade>
								<cfelse><cfset args.data.unitTrade = (args.data.cash + args.data.credit) * 0.75></cfif>
								<cfset CalcValues(args.data)>
								<cfset UpdateBasket(args)>
							<cfelse>
								<cfset session.basket.info.errMsg = "This product has no price, please enter it manually.">
								<cfdump var="#args#" label="AddItem Error" expand="yes" format="html"
									output="#application.site.dir_logs#epos\prod0-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
							</cfif>
						<cfelse>
							<cfset session.basket.info.errMsg = "Unknown product class: '#args.form.itemClass#'.">
						</cfif>
					</cfdefaultcase>
				</cfswitch>
			</cfif>
		<cfcatch type="any">
			<cfset loc.result.err = cfcatch.Message>
			<cfdump var="#cfcatch#" label="" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfset session.basket.info.busy = false>
		</cflock>
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
		<cfset loc.addTran = false>

		<cftry>
			<cfif session.basket.info.busy>
				<cfset loc.result.err = "System busy...">
				<cfreturn loc.result>
				<cfexit>
			</cfif>
			
			<cfset session.basket.info.busy = false>	<!--- was true --->
			<cfset session.till.isTranOpen = true>
			<cfset loc.regMode = (2 * int(session.basket.info.mode neq "rfd")) - 1>	<!--- modes: reg = 1 waste = 1 refund = -1 --->
			<cfset loc.tranType = 1>
			<cfset args.data.cash = abs(val(args.form.cash)) * loc.tranType * loc.regMode> <!--- all form values are +ve numbers --->
			<cfset args.data.credit = abs(val(args.form.credit)) * loc.tranType * loc.regMode>	<!--- apply mode & type to set sign correctly --->
			<cfset args.data.account = args.form.account>
			<cfset args.data.btn = args.form.btnSend>
			<cfset args.data.payID = args.form.payID>
			<cfset args.data.qty = 1>
			<cfset args.data.title = "undefined">
			<cfset session.basket.info.errMsg = "">

			<!--- count items in all departments --->
			<cfset loc.basketItems = 0>
			<cfloop array="#session.till.catKeys#" index="loc.key">
				<cfset loc.dept = StructFind(session.basket,loc.key)>
				<cfset loc.basketItems += ArrayLen(loc.dept)>
			</cfloop>

			<!--- difference between cash sales and cash received... --->
			<cfset loc.cashBalance = session.basket.header.bCash + session.basket.header.cashTaken
				+ session.basket.header.cashback + session.basket.header.LPrize + session.basket.header.SPrize 
				+ session.basket.header.cpn + session.basket.header.hsv>

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
						<cfif session.basket.info.mode eq "reg">
							<cfset this.closeTranNow = args.data.cash gte session.basket.total.balance>
						<cfelseif session.basket.info.mode eq "rfd">
							<cfset this.closeTranNow = args.data.cash lte session.basket.total.balance>
						</cfif>
						<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "CASHINDW">
						<cfset args.data.title = "Cash Payment">
						<cfset args.data.account = 1>
						<cfset args.data.prodID = 1>
						<cfset ArrayAppend(session.basket.payments,args.data)>
						<cfset loc.addTran = true>
					</cfif>
				</cfcase>

				<cfcase value="Card">
					<cfset loc.test = {}>
					<cfset loc.test.balance = session.basket.total.balance>
					<cfset loc.test.credit = args.data.credit>
					<cfset loc.test.pcredit = round(args.data.credit * 100)>
					<cfset loc.test.pbalance = round(session.basket.total.balance * 100)>
					<cfset loc.test.diff = loc.test.pcredit - loc.test.pbalance>

					<cfif args.data.cash + args.data.credit is 0>
						<cfset args.data.credit = session.basket.total.balance>
						<cfset args.data.cash = 0>
					</cfif>
					<cfset loc.cashBalance += args.data.cash>
					<cfset loc.mincard =  session.till.prefs.mincard - abs(args.data.credit)>
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.supplier) gt 0>
						<cfset session.basket.info.errMsg = "Cannot accept a card payment during a supplier transaction.">
					<cfelseif session.basket.info.mode eq "reg" AND session.basket.header.bcash neq 0 AND (session.basket.header.bcredit + session.basket.header.discstaff) gt -session.till.prefs.mincard>
						<cfset session.basket.info.errMsg = "Minimum sale of &pound;#session.till.prefs.mincard# required.<br>(Excludes lottery, stamps & top-ups).">
<!--- ok if spent more than £3
					<cfelseif session.basket.info.mode eq "reg" AND loc.cashBalance lt 0>
						<cfset session.basket.info.errMsg = "Some items in the basket must be paid by cash or cashback. (&pound;#DecimalFormat(-loc.cashBalance)#)">
--->
					<cfelseif session.basket.info.mode eq "rfd" AND loc.cashBalance gt 0>
						<cfset session.basket.info.errMsg = "Some items in the basket must be refunded by cash.">
					<cfelseif session.basket.info.mode eq "reg" AND loc.test.diff gt 0>
						<cfset session.basket.info.errMsg = "Card sale amount is too high. #args.data.credit# : #session.basket.total.balance#">
					<cfelseif session.basket.info.mode eq "rfd" AND loc.test.diff lt 0>
						<cfset session.basket.info.errMsg = "Card refund amount is too high. #args.data.credit# : #session.basket.total.balance#">
					<cfelseif args.data.cash neq 0 AND args.data.credit eq 0>
						<cfset session.basket.info.errMsg = "Please enter the sale amount from the PayStation receipt.">
					<cfelseif session.basket.info.mode eq "reg"
						AND session.basket.info.service eq 0
						AND loc.mincard gt 0.001
						<!---AND abs(args.data.credit) neq session.till.prefs.service--->>
							<cfset session.basket.info.errMsg = "Minimum sale amount allowed on card is &pound;#session.till.prefs.mincard#.">

					<cfelse>
						<cfif loc.regMode eq 1>	<!--- open draw in reg mode --->
							<cfset this.closeTranNow = args.data.credit + args.data.cash gte session.basket.total.balance>
						<cfelse>	<!--- open drawer in refund mode --->
							<cfset this.closeTranNow = args.data.credit + args.data.cash lte session.basket.total.balance>
						</cfif>
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "CARDINDW">
						<cfset args.data.title = "Card Payment">
						<cfset args.data.account = 1>
						<cfset args.data.prodID = 1>
						<cfset ArrayAppend(session.basket.payments,args.data)>
						<cfset loc.addTran = true>
					</cfif>
				</cfcase>

				<cfcase value="CHQS">
					<cfif args.data.cash + args.data.credit is 0>
						<cfset args.data.credit = session.basket.total.balance>
						<cfset args.data.cash = 0>
					<cfelseif args.data.cash neq 0>
						<cfset args.data.credit = args.data.cash>
						<cfset args.data.cash = 0>
					</cfif>
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.news) + ArrayLen(session.basket.accpay) eq 0>
						<cfset session.basket.info.errMsg = "Cheques can only be accepted for News & Customer Account Payments.">
					<cfelse>
						<cfif abs(session.basket.total.news) neq abs(args.data.credit) AND (abs(session.basket.total.accpay) neq abs(args.data.credit))>
							<cfset session.basket.info.errMsg = "Cheque amount must equal the Account Payment.">
						<cfelse>
							<cfset args.data.class = "pay">
							<cfset args.data.itemClass = "CHQINDW">
							<cfset args.data.title = "Cheque Payment">
							<cfset args.data.account = 1>
							<cfset args.data.prodID = 1>
							<cfset ArrayAppend(session.basket.payments,args.data)>
							<cfset loc.addTran = true>
						</cfif>
					</cfif>
				</cfcase>

				<cfcase value="BT">
					<cfif args.data.cash + args.data.credit is 0>
						<cfset args.data.credit = session.basket.total.balance>
						<cfset args.data.cash = 0>
						<cfset this.closeTranNow = true>
					</cfif>
					<cfset loc.cashBalance += args.data.cash>
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.supplier) gt 0>
						<cfset session.basket.info.errMsg = "Cannot pay on account during a supplier transaction.">
					<cfelse>
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "BANKXFR">
						<cfset args.data.title = "Bank Transfer">
						<cfset args.data.account = args.form.payID>
						<cfset args.data.prodID = 1>
						<cfset ArrayAppend(session.basket.payments,args.data)>
						<cfset loc.addTran = true>
					</cfif>
				</cfcase>

				<cfcase value="ONLINE">
					<cfif args.data.cash + args.data.credit is 0>
						<cfset args.data.credit = session.basket.total.balance>
						<cfset args.data.cash = 0>
						<cfset this.closeTranNow = true>
					</cfif>
					<cfset loc.cashBalance += args.data.cash>
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.supplier) gt 0>
						<cfset session.basket.info.errMsg = "Cannot pay on account during a supplier transaction.">
					<cfelse>
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "ONLINE">
						<cfset args.data.title = "Card Online">
						<cfset args.data.account = args.form.payID>
						<cfset args.data.prodID = 1>
						<cfset ArrayAppend(session.basket.payments,args.data)>
						<cfset loc.addTran = true>
					</cfif>
				</cfcase>

				<cfcase value="Account">
					<cfif args.data.cash + args.data.credit is 0>
						<cfset args.data.credit = session.basket.total.balance>
						<cfset args.data.cash = 0>
						<cfset this.closeTranNow = true>
					</cfif>
					<cfset loc.cashBalance += args.data.cash>
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.supplier) gt 0>
						<cfset session.basket.info.errMsg = "Cannot pay on account during a supplier transaction.">
					<cfelseif val(args.data.account) is 0>
						<cfset session.basket.info.errMsg = "Please select an account to assign this transaction.">
					<cfelse>
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "ACCINDW">
						<cfset args.data.title = "Payment on Account">
						<cfset args.data.account = args.form.account>
						<cfset args.data.prodID = 1>
						<cfset ArrayAppend(session.basket.payments,args.data)>
						<cfset loc.addTran = true>
					</cfif>
				</cfcase>

				<cfcase value="WASTE">
					<cfif args.data.cash + args.data.credit is 0>
						<cfset args.data.credit = session.basket.total.balance>
						<cfset args.data.cash = 0>
						<cfset this.closeTranNow = true>
					</cfif>
					<cfset loc.cashBalance += args.data.cash>
					<cfif loc.basketItems eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.supplier) gt 0>
						<cfset session.basket.info.errMsg = "Cannot pay on account during a supplier transaction.">
					<cfelse>
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "WASTE">
						<cfset args.data.title = "Waste Account">
						<cfset args.data.account = args.form.account>
						<cfset args.data.prodID = 1>
						<cfset ArrayAppend(session.basket.payments,args.data)>
						<cfset loc.addTran = true>
					</cfif>
				</cfcase>

				<cfcase value="CPN">
					<cfif ArrayLen(session.basket.paystation) eq 0>
						<cfset session.basket.info.errMsg = "Please put a PayStation item in the basket before accepting a coupon.">
					<cfelse>
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfset args.data.credit = 0>
						
						<cfif session.basket.info.mode eq "reg">
							<cfset loc.diff = args.data.cash - session.basket.info.totaldue>
						<cfelseif session.basket.info.mode eq "rfd">
							<cfset loc.diff = args.data.cash + session.basket.info.totaldue>
						</cfif>

						<cfif args.data.cash is 0>
							<cfset session.basket.info.errMsg = "Please enter the coupon value.">
						<cfelseif loc.diff gt 0.01>
							<cfset session.basket.info.errMsg = "Coupon value cannot exceed basket total.">
						<cfelse>
							<cfset args.data.class = "pay">
							<cfset args.data.itemClass = "CPN">
							<cfset args.data.title = "Coupon Redemption">
							<cfset args.data.account = 1>
							<cfset args.data.prodID = 1>
							<cfset ArrayAppend(session.basket.payments,args.data)>
							<cfset loc.addTran = true>
						</cfif>
					</cfif>
				</cfcase>

				<cfcase value="HSV">
					<cfif 1 eq 2>	<!--- ignore this --->
						<cfset session.basket.info.errMsg = "Please...">
					<cfelse>
						<cfset args.data.cash = args.data.cash + args.data.credit>
						<cfset args.data.credit = 0>
						
						<cfif session.basket.info.mode eq "reg">
							<cfset loc.diff = args.data.cash - session.basket.info.totaldue>
						<cfelseif session.basket.info.mode eq "rfd">
							<cfset loc.diff = args.data.cash + session.basket.info.totaldue>
						</cfif>
						
						<cfif args.data.cash is 0>
							<cfset session.basket.info.errMsg = "Please enter the voucher value.">
						<cfelseif loc.diff gt 0.01>
							<cfset session.basket.info.errMsg = "Voucher value cannot exceed basket total.">
						<cfelse>
							<cfset args.data.class = "pay">
							<cfset args.data.itemClass = "HSV">
							<cfset args.data.title = "Healthy Start">
							<cfset args.data.account = 1>
							<cfset args.data.prodID = 1>
							<cfset ArrayAppend(session.basket.payments,args.data)>
							<cfset loc.addTran = true>
						</cfif>
					</cfif>
				</cfcase>

				<cfdefaultcase>	<!--- unhandled --->
					<cfdump var="#args#" label="unknown case #args.form.btnSend#" expand="yes" format="html"
						output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
				</cfdefaultcase>
			</cfswitch>

			<cfif loc.addTran>
				<cfset loc.tran = {}>
				<cfset loc.tran.prop = 1>
				<cfset loc.tran.payID = val(args.data.payID)>
				<cfset loc.tran.accID = val(args.data.account)>
				<cfset loc.tran.itemClass = args.data.itemClass>
				<cfset loc.tran.itemType = 'pay'>
				<cfset loc.tran.cashonly = args.data.cash neq 0>
				<cfset loc.tran.gross = args.data.cash + args.data.credit>
				<cfset loc.tran.net = args.data.cash + args.data.credit>
				<cfset loc.tran.vat = 0>
				<cfset loc.tran.qty = 1>
				<cfset ArrayAppend(session.basket.trans,loc.tran)>
			</cfif>

			
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="AddPayment" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfset session.basket.info.busy = false>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="StructToDataAttributes" access="public" returntype="string">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = "">

		<cfloop collection="#args#" item="loc.key">
			<cfset loc.item = StructFind(args, loc.key)>
			<cfif IsValid("string", loc.item) OR IsValid("boolean", loc.item) OR IsValid("float", loc.item)>
				<cfset loc.result = loc.result & ' data-#LCase(loc.key)#="#loc.item#"'>
			</cfif>
		</cfloop>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="ShowBasket" access="public" returntype="void">
		<cfargument name="type" type="string" required="no" default="html">
		<cfset var loc = {}>
		<cftry>
			<!---<cfif session.basket.info.busy><cfexit></cfif>--->
			<cfset session.basket.info.busy = false>	<!--- was true --->
			<cfset loc = BuildBasket()>
			<cfset loc.thisBasket = (arguments.type eq "html") ? session.basket : session.till.prevtran>
			<cfset loc.totalRetail = 0>
			<cfset loc.totalCount = 0>
			<cfoutput>
				<cfif arguments.type eq "js">
					request += builder.createAlignmentElement({position: 'center'});
					request += builder.createTextElement(styles.heading("Shortlanesend Store \n"));
					request += builder.createTextElement(styles.normal("#application.company.telephone# \n\n"));

					request += builder.createAlignmentElement({position: 'left'});
					request += builder.createTextElement(styles.normal(align.lr("#LSDateFormat(Now(), 'dd/mm/yyyy')# #LSTimeFormat(Now(), 'HH:MM')#", "VAT: #application.company.vat_number#")));

					request += builder.createTextElement({data: '\n'});

					request += builder.createAlignmentElement({position: 'center'});
<!---				message missing?	
					<cfif loc.thisBasket.info.bod eq "Supplier">
						<cfif loc.thisBasket.info.mode eq "rfd">
							<cfset loc.typeStr = "Supplier Refund\n">
						<cfelse>
							<cfset loc.typeStr = "Supplier Purchase\n">
						</cfif>
					<cfelseif loc.thisBasket.info.mode eq "rfd">
						<cfset loc.typeStr = "Customer Refund\n">
					<cfelse>
						<cfset loc.typeStr = "Sale\n">
					</cfif>
					request += builder.createTextElement(styles.bold(loc.typeStr));
--->					
					
					<cfif loc.thisBasket.info.mode eq "rfd">
						request += builder.createTextElement(styles.bold("Refund\n"));
					<cfelseif loc.thisBasket.info.bod eq "Supplier">
						request += builder.createTextElement(styles.bold("Purchase\n"));
					<cfelse>
						request += builder.createTextElement(styles.bold("Sale\n"));
					</cfif>


					request += builder.createAlignmentElement({position: 'left'});
					request += builder.createTextElement(styles.normal(align.lr("Served by: #session.user.firstName# #left(session.user.lastName, 1)#", ("Ref: #loc.thisBasket.tranID#"))));
					request += builder.createTextElement({data: '\n\n'});
				</cfif>

				<cfif arguments.type eq "html">
					<!--- <table class="eposBasketTable" border="0" width="100%"> --->
					<div class="btr_header">
						<span style="width: 50%;text-align: left;">Description</span>
						<span style="width: 10%;text-align: right;">Qty</span>
						<span style="width: 20%;text-align: right;">Price</span>
						<span style="width: 20%;text-align: right;">Total</span>
					</div>
					<!--- <tr class="ebt_headers">
						<th align="left">Description</th>
						<th align="center">Qty</th>
						<th align="right">Price</th>
						<th align="right">Total</th>
					</tr> --->
				<cfelse>
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

						<cfset loc.totalRetail += -loc.data.retail>
						<cfset loc.totalCount += loc.data.qty>
						<cfif arguments.type eq "html">
							<div class="btr_item material-ripple basket_item" #StructToDataAttributes(loc.data)#>
								<span style="width: 50%;">#loc.data.title# #loc.data.unitsize#</span>
								<span style="width: 10%;text-align: right;">#loc.data.qty#</span>
								<span style="width: 20%;text-align: right;">#DecimalFormat(loc.data.unitPrice)#</span>
								<span style="width: 20%;text-align: right;">#DecimalFormat(-loc.data.retail)#</span>
							</div>
							<!--- <tr class="basket_item" #StructToDataAttributes(loc.data)#>
								<td align="left"><span class="#loc.style#">#loc.data.title#</span></td>
								<td align="center">#loc.data.qty#</td>
								<td align="right">#DecimalFormat(loc.data.unitPrice)#</td>
								<td align="right">#DecimalFormat(-loc.data.retail)#</td>
							</tr> --->
						<cfelse>
							<cfset loc.dealStr = Replace(loc.data.title,"#Chr(163)#","\x9c","all")>
							title = "#loc.dealStr#";
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
								request += builder.createTextElement(styles.normal(align.rlr("#loc.data.qty#", title1, "#chr(156)##DecimalFormat(-loc.data.retail)#")));
								request += builder.createTextElement({data: '\n'});
							}

							if (title2.length > 0) {
								request += builder.createTextElement(styles.normal(align.rlr("-", title2, "-")));
								request += builder.createTextElement({data: '\n'});
							}
						</cfif>
					</cfloop>
				</cfloop>

				<cfif loc.totalRetail neq 0>
					<cfif arguments.type eq "html">
						<!--- <div class="btr_header">
							<span style="width: 50%;">Total</span>
							<span style="width: 10%;text-align: right;">#loc.thisBasket.info.itemCount# items</span>
							<span style="width: 20%;text-align: right;"></span>
							<span style="width: 20%;text-align: right;">#DecimalFormat(loc.totalRetail)#</span>
						</div> --->
						<!--- <tr class="ebt_headers">
							<th align="left">Total</th>
							<th align="center">#loc.thisBasket.info.itemCount# items</th>
							<th align="right"></th>
							<th align="right">#DecimalFormat(loc.totalRetail)#</th>
						</tr> --->
					<cfelse>
						request += builder.createRuledLineElement({thickness: 'medium', width: 832});
						request += builder.createAlignmentElement({position: 'left'});
						request += builder.createTextElement(styles.bold(align.lr("TOTAL (#loc.totalCount# items)", "#chr(156)##DecimalFormat(loc.totalRetail)#")));
						request += builder.createTextElement({data: '\n'});
					</cfif>
				</cfif>
				<!--- <cfif loc.totalRetail neq 0>
					<cfif arguments.type eq "html">
						<div class="btr_header">
							<span style="width: 50%;">Total Due</span>
							<span style="width: 50%;text-align: right;">#DecimalFormat(loc.totalRetail)#</span>
						</div>
					</cfif>
				</cfif> --->
				<cfif StructKeyExists(loc.thisBasket,"deals")>
					<cfif loc.qualifyingDeals gt 0>
						<cfif arguments.type eq "html">
							<!--- <tr>
								<td colspan="4">&nbsp;</td>
							</tr>
							<tr class="ebt_headers">
								<th align="left">Multibuy Discounts</th>
								<th align="center">Items</th>
								<th></th>
								<th align="right">Saving</th>
							</tr> --->
						</cfif>
					</cfif>
					<cfset loc.hasDealHeader = false>
					<cfloop collection="#loc.thisBasket.deals#" item="loc.key">
						<cfset loc.data = StructFind(loc.thisBasket.deals,loc.key)>
						<cfif loc.data.dealQty neq 0 AND loc.key neq 1>	<!--- qualifying deal, hide default deal --->
							<cfif arguments.type eq "html">
								<cfif NOT loc.hasDealHeader>
									<div class="btr_header">
										<span style="width: 100%;">Discounts</span>
									</div>
									<cfset loc.hasDealHeader = true>
								</cfif>

								<div class="btr_item material-ripple basket_item">
									<span style="width: 50%;">#loc.data.dealTitle#</span>
									<span style="width: 10%;text-align: right;">#loc.data.count#</span>
									<span style="width: 20%;text-align: right;">&nbsp;</span>
									<span style="width: 20%;text-align: right;">#DecimalFormat(-loc.data.savingGross)#</span>
								</div>
								<!--- <tr class="basket_item">
									<td align="left">#loc.data.dealTitle#</td>
									<td align="center">#loc.data.count#</td>
									<td></td>
									<td align="right">#DecimalFormat(-loc.data.savingGross)#</td>
								</tr> --->
							<cfelse>
								<cfset loc.dealStr = Replace(loc.data.dealTitle,"#Chr(163)#","\x9c","all")>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.normal(align.lr("#loc.dealStr# Deal", "#chr(156)##DecimalFormat(-loc.data.savingGross)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfif>
					</cfloop>
					<cfif loc.thisBasket.total.discstaff neq 0>
						<cfif arguments.type eq "html">
							<div class="btr_item material-ripple basket_item">
								<span style="width: 50%;">Staff Discount</span>
								<span style="width: 10%;text-align: right;"></span>
								<span style="width: 20%;text-align: right;"></span>
								<span style="width: 20%;text-align: right;">#DecimalFormat(-loc.thisBasket.total.discstaff)#</span>
							</div>
							<!--- <tr class="basket_item">
								<td align="left">Staff Discount</td>
								<td align="center"></td>
								<td></td>
								<td align="right">#DecimalFormat(-loc.thisBasket.total.discstaff)#</td>
							</tr> --->
						<cfelse>
							request += builder.createAlignmentElement({position: 'left'});
							request += builder.createTextElement(styles.bold(align.lr("STAFF DISCOUNT", "#chr(156)##DecimalFormat(-loc.thisBasket.total.discstaff)#")));
							request += builder.createTextElement({data: '\n'});
						</cfif>
					</cfif>
					<cfif loc.thisBasket.info.totalDue neq 0>
						<cfif arguments.type eq "html">
							<!--- <div class="btr_header">
								<span style="width: 50%;">Total Due</span>
								<span style="width: 50%;text-align: right;">#DecimalFormat(loc.thisBasket.total.balance)#</span>
							</div> --->
							<!--- <tr>
								<td colspan="4">&nbsp;</td>
							</tr>
							<tr class="ebt_headers">
								<th align="left">Total Due</th>
								<th align="center"></th>
								<th align="right"></th>
								<th align="right">#DecimalFormat(loc.thisBasket.info.totalDue)#</th>
							</tr> --->
						<cfelse>
							request += builder.createAlignmentElement({position: 'left'});
							request += builder.createTextElement(styles.bold(align.lr("BALANCE DUE", "#chr(156)##DecimalFormat(loc.thisBasket.info.totalDue)#")));
							request += builder.createTextElement({data: '\n'});
						</cfif>
					</cfif>
				</cfif>

				<cfset loc.canClose = false>
				<cfset loc.payCount = 0>

				<cfif NOT ArrayIsEmpty(loc.thisBasket.payments) AND arguments.type eq "html">
					<div class="btr_header">
						<span style="width: 100%;">Payments</span>
					</div>
				</cfif>

				<cfloop array="#loc.thisBasket.payments#" index="loc.item">

					<cfset loc.payCount++>

					<cfswitch expression="#loc.item.itemClass#">
						<cfcase value="CASHINDW">
							<cfif arguments.type eq "html">
								<cfset loc.canClose = true>
								<div class="btr_item material-ripple ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<span style="width: 70%;">Cash Payment</span>
									<span style="width: 30%;text-align: right;">#DecimalFormat(-(loc.item.cash + loc.item.credit))#</span>
								</div>
								<!--- <tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<td colspan="3">Cash Payment</td><td align="right">#DecimalFormat(-(loc.item.cash + loc.item.credit))#</td>
								</tr> --->
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.normal(align.lr("CASH PAYMENT", "#chr(156)##DecimalFormat((loc.item.cash + loc.item.credit))#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfcase>
						<cfcase value="CARDINDW">
							<cfif arguments.type eq "html">
								<cfset loc.canClose = true>
								<div class="btr_item material-ripple ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<span style="width: 70%;">Card Payment</span>
									<span style="width: 30%;text-align: right;">#DecimalFormat(-loc.item.credit)#</span>
								</div>
								<!--- <tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<td colspan="3">Card Payment</td><td align="right">#DecimalFormat(-loc.item.credit)#</td>
								</tr> --->
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.normal(align.lr("CARD PAYMENT", "#chr(156)##DecimalFormat(loc.item.credit)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
							<cfif loc.item.cash neq 0>
								<cfif arguments.type eq "html">
									<div class="btr_item material-ripple ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
										<span style="width: 70%;">Cashback</span>
										<span style="width: 30%;text-align: right;">#DecimalFormat(-loc.item.cash)#</span>
									</div>
									<!--- <tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
										<td colspan="3">Cashback</td><td align="right">#DecimalFormat(-loc.item.cash)#</td>
									</tr> --->
								<cfelse>
									request += builder.createAlignmentElement({position: 'left'});
									request += builder.createTextElement(styles.normal(align.lr("CASHBACK", "#chr(156)##DecimalFormat(loc.item.cash)#")));
									request += builder.createTextElement({data: '\n'});
								</cfif>
							</cfif>

						</cfcase>
						<cfcase value="CHQINDW">
							<cfif arguments.type eq "html">
								<cfset loc.canClose = true>
								<div class="btr_item material-ripple ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<span style="width: 70%;">Cheque Payment</span>
									<span style="width: 30%;text-align: right;">#DecimalFormat(-loc.item.cash - loc.item.credit)#</span>
								</div>
								<!--- <tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<td colspan="3">Cheque Payment</td><td align="right">#DecimalFormat(-loc.item.cash - loc.item.credit)#</td>
								</tr> --->
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.normal(align.lr("CHEQUE PAYMENT", "#chr(156)##DecimalFormat(loc.item.cash - loc.item.credit)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfcase>
						<cfcase value="ACCINDW">
							<cfif arguments.type eq "html">
								<cfset loc.canClose = true>
								<div class="btr_item material-ripple ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<span style="width: 70%;">Paid on Account</span>
									<span style="width: 30%;text-align: right;">#DecimalFormat(-loc.item.cash - loc.item.credit)#</span>
								</div>
								<!--- <tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<td colspan="3">Paid on Account</td><td align="right">#DecimalFormat(-loc.item.cash - loc.item.credit)#</td>
								</tr> --->
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.normal(align.lr("PAID ON ACCOUNT", "#chr(156)#
									#DecimalFormat(loc.item.cash - loc.item.credit)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfcase>
						<cfcase value="BANKXFR">
							<cfif arguments.type eq "html">
								<cfset loc.canClose = true>
								<div class="btr_item material-ripple ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<span style="width: 70%;">Bank Transfer</span>
									<span style="width: 30%;text-align: right;">#DecimalFormat(-loc.item.cash - loc.item.credit)#</span>
								</div>
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.normal(align.lr("Bank Transfer", "#chr(156)#
									#DecimalFormat(loc.item.cash - loc.item.credit)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfcase>
						<cfcase value="ONLINE">
							<cfif arguments.type eq "html">
								<cfset loc.canClose = true>
								<div class="btr_item material-ripple ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<span style="width: 70%;">Card Online</span>
									<span style="width: 30%;text-align: right;">#DecimalFormat(-loc.item.cash - loc.item.credit)#</span>
								</div>
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.normal(align.lr("Card Online", "#chr(156)#
									#DecimalFormat(loc.item.cash - loc.item.credit)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfcase>
						<cfcase value="WASTE">
							<cfif arguments.type eq "html">
								<cfset loc.canClose = true>
								<div class="btr_item material-ripple ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<span style="width: 70%;">Waste Account</span>
									<span style="width: 30%;text-align: right;">#DecimalFormat(-loc.item.cash - loc.item.credit)#</span>
								</div>
								<!--- <tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<td colspan="3">Paid on Account</td><td align="right">#DecimalFormat(-loc.item.cash - loc.item.credit)#</td>
								</tr> --->
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.normal(align.lr("WASTE ACCOUNT", "#chr(156)#
									#DecimalFormat(loc.item.cash - loc.item.credit)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfcase>
						<cfdefaultcase>
							<cfset loc.payValue = StructFind(loc.thisBasket.total,loc.item.itemClass)>
							<cfif arguments.type eq "html">
								<div class="btr_item material-ripple ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<span style="width: 70%;">#loc.item.title#</span>
									<span style="width: 30%;text-align: right;">#DecimalFormat(-(loc.item.cash + loc.item.credit))#</span>
								</div>
								<!--- <tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
									<td colspan="3">#loc.item.title#</td><td align="right">#DecimalFormat(-(loc.item.cash + loc.item.credit))#</td>
								</tr> --->
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.normal(align.lr("#UCase(loc.item.title)#", "#chr(156)#
									#DecimalFormat((loc.item.cash + loc.item.credit))#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfdefaultcase>
					</cfswitch>
				</cfloop>
				<cfif loc.thisBasket.info.itemcount gt 0>
					<cfif arguments.type eq "html">
						<!--- <tr><td colspan="5">&nbsp;</td></tr> --->
					</cfif>
					<cfif loc.thisBasket.info.mode eq "reg">
						<cfif loc.thisBasket.total.balance lte 0.001>	<!--- avoid tiny rounding issues --->
							<cfif arguments.type eq "html">
								<!--- <tr class="ebt_headers balcredit">
									<th align="left">Change</th>
									<th align="center"></th>
									<th align="right"></th>
									<th align="right">#DecimalFormat(-loc.thisBasket.info.change)#</th>
								</tr> --->
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.bold(align.lr("CHANGE DUE", "#chr(156)##DecimalFormat(-loc.thisBasket.info.change)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
							<cfif arguments.type eq "html">
								<cfif loc.thisBasket.info.change neq 0>
									<cfset loc.tran = {}>
									<cfset loc.tran.prop = 1>
									<cfset loc.tran.itemClass = 'CASHINDW'>
									<cfset loc.tran.itemType = 'pay'>
									<cfset loc.tran.payID = 12>
									<cfset loc.tran.accID = 1>
									<cfset loc.tran.cashonly = "YES">
									<cfset loc.tran.gross = loc.thisBasket.info.change>
									<cfset loc.tran.net = loc.thisBasket.info.change>
									<cfset loc.tran.vat = 0>
									<cfset ArrayAppend(session.basket.trans,loc.tran)>
								</cfif>
								<cfif loc.canClose>	<!--- close reg transaction --->
									<cfset CloseTransaction()>
									<cfif arguments.type neq "html">
										request += builder.createPeripheralElement({channel:1, on:200, off:200});
									</cfif>
								</cfif>
							</cfif>
						<cfelseif loc.thisBasket.total.balance gt 0>
							<cfif arguments.type eq "html">
								<!--- <tr class="ebt_headers baldebit">
									<th align="left">Balance Due from Customer</th>
									<th align="center"></th>
									<th align="right"></th>
									<th align="right">#DecimalFormat(loc.thisBasket.total.balance)#</th>
								</tr> --->
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.bold(align.lr("BALANCE DUE FROM CUSTOMER", "#chr(156)#
									#DecimalFormat(loc.thisBasket.total.balance)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfif>
					<cfelse>
						<cfif loc.thisBasket.total.balance lte 0>
							<cfif arguments.type eq "html">
								<!--- <tr class="ebt_headers balcredit">
									<th align="left">Balance Due to Customer</th>
									<th align="center"></th>
									<th align="right"></th>
									<th align="right">#DecimalFormat(loc.thisBasket.total.balance)#</th>
								</tr> --->
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.bold(align.lr("BALANCE DUE TO CUSTOMER", "#chr(156)#
									#DecimalFormat(loc.thisBasket.total.balance)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
							<cfif arguments.type eq "html">
								<cfif loc.thisBasket.info.change neq 0>
									<cfset loc.tran = {}>
									<cfset loc.tran.prop = 1>
									<cfset loc.tran.itemClass = 'CASHINDW'>
									<cfset loc.tran.itemType = 'pay'>
									<cfset loc.tran.payID = 12>
									<cfset loc.tran.accID = 1>
									<cfset loc.tran.cashonly = "YES">
									<cfset loc.tran.gross = loc.thisBasket.info.change>
									<cfset loc.tran.net = loc.thisBasket.info.change>
									<cfset loc.tran.vat = 0>
									<cfset ArrayAppend(session.basket.trans,loc.tran)>
								</cfif>
							</cfif>
						<cfelse>
							<cfif arguments.type eq "html">
								<!--- <tr class="ebt_headers baldebit">
									<th align="left">Balance Due from Customer</th>
									<th align="center"></th>
									<th align="right"></th>
									<th align="right">#DecimalFormat(loc.thisBasket.total.balance)#</th>
								</tr> --->
							<cfelse>
								request += builder.createAlignmentElement({position: 'left'});
								request += builder.createTextElement(styles.bold(align.lr("BALANCE DUE FROM CUSTOMER", "#chr(156)#
									#DecimalFormat(loc.thisBasket.total.balance)#")));
								request += builder.createTextElement({data: '\n'});
							</cfif>
						</cfif>
						<cfif loc.canClose>	<!--- close refund tran --->
							<cfset CloseTransaction()>
							<cfif arguments.type neq "html">
								request += builder.createPeripheralElement({channel:1, on:200, off:200});
							</cfif>
						</cfif>
					</cfif>
					<cfif loc.qualifyingDeals gt 0>
						<cfif arguments.type eq "html">
							<!--- <tr>
								<td colspan="5">&nbsp;</td>
							</tr>
							<tr class="ebt_headers">
								<th align="left">Multibuy Discount Savings</th>
								<th align="center"></th>
								<th></th>
								<th align="right">#DecimalFormat(loc.thisBasket.total.discount)#</th>
							</tr> --->
						<cfelse>
							request += builder.createAlignmentElement({position: 'left'});
							request += builder.createTextElement(styles.bold(align.lr("MULTIBUY DISCOUNT SAVINGS", "#chr(156)#
								#DecimalFormat(loc.thisBasket.total.discount)#")));
							request += builder.createTextElement({data: '\n'});
						</cfif>
					</cfif>
				</cfif>
				<cfif this.closeTranNow>
					<cfset CloseTransaction()>
				</cfif>
				<cfset loc.tranID = (structKeyExists(loc.thisBasket, 'archive')) ? loc.thisBasket.archive.id : -1>
				<cfif arguments.type eq "html">
					<!--- </table> --->
				<cfelse>
					<!--- request += builder.createPeripheralElement({channel:1, on:200, off:200}); --->
					request += builder.createAlignmentElement({position: 'center'});
					request += builder.createTextElement({data: '\n'});
					request += builder.createTextElement(styles.normal("Thank you for shopping at Shortlanesend Store\n\n"));
					<cfif loc.tranID gt -1>
						request += builder.createBarcodeElement({
							symbology: 'JAN13',
							width: 'width3',
							height: 40,
							hri: false,
							data: #new App.EPOSArchive(loc.tranID).barcode()#
						});
					</cfif>
				</cfif>
			</cfoutput>
			
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfset session.basket.info.busy = false>
	</cffunction>

	<cffunction name="BuildBasket" access="public" returntype="struct">
		<cfset var loc = {}>

		<cftry>
			<cflock scope="session" timeout="60" type="exclusive" throwontimeout="yes">	<!--- was 15sec --->
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
					<cfset session.basket.info.canClose = false>
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

							<!---<cfset loc.data.discount = loc.data.discount * loc.data.regMode>--->
							<cfset loc.totalRetail -= loc.data.retail>	<!--- crash --->
							<cfset session.basket.total.balance -= (loc.data.retail + loc.data.discount)>	<!---  + session.basket.total.discstaff --->
							<cfset loc.cashtotal = loc.data.cash * loc.data.qty * loc.data.regMode>
							<cfset loc.credittotal = loc.data.credit * loc.data.qty * loc.data.regMode>
							<cfset session.basket.header.bCash -= loc.cashtotal>
							<cfset session.basket.header.bCredit -= loc.credittotal>
							<cfset session.basket.header.balance += (loc.cashtotal + loc.credittotal - loc.data.discount)>
	
							<cfset loc.total = StructFind(session.basket.total,loc.data.itemClass)>
							<cfset StructUpdate(session.basket.total,loc.data.itemClass,loc.total + loc.data.totalGross)>	<!--- - loc.data.discount TODO staff disc issue --->
							<cfset session.basket.total.discstaff += loc.data.discount>
							<cfset session.basket.header.discstaff += loc.data.discount>
							<cfif StructKeyExists(loc.data,"dealID")>
								<cfif loc.data.dealID neq 0><cfset loc.style = "dealItem"></cfif>
							</cfif>
						</cfloop>
					</cfloop>
	
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
								<cfset session.basket.info.canClose = true>
							</cfcase>
							<cfcase value="CARDINDW">
								<cfset session.basket.total.cardINDW += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.header.cardsales += loc.item.credit>
								<cfset session.basket.header.cashback += loc.item.cash>
								<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
								<cfset session.basket.info.canClose = true>
							</cfcase>
							<cfcase value="CHQINDW">
								<cfset session.basket.total.chqINDW += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.header.chqsales += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
								<cfset session.basket.info.canClose = true>
							</cfcase>
							<cfcase value="ACCINDW">
								<cfset session.basket.total.accINDW += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.header.accsales += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
								<cfset session.basket.info.canClose = true>
							</cfcase>
							<cfcase value="BANKXFR">
								<cfset session.basket.total.BANKXFR += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.header.BANKXFRsales += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
								<cfset session.basket.info.canClose = true>
							</cfcase>
							<cfcase value="ONLINE">
								<cfset session.basket.total.ONLINE += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.header.ONLINEsales += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
								<cfset session.basket.info.canClose = true>
							</cfcase>
							<cfcase value="WASTE">
								<cfset session.basket.total.WASTE += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.header.WASTE += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
								<cfset session.basket.info.canClose = true>
							</cfcase>
							<cfdefaultcase>
								<cfset loc.payValue = StructFind(session.basket.total,loc.item.itemClass)>
								<cfset StructUpdate(session.basket.total,loc.item.itemClass,loc.payValue + (loc.item.cash + loc.item.credit))>
									<!--- TODO will fail if key not found --->
								<cfset StructUpdate(session.basket.header,loc.item.itemClass,loc.payValue + (loc.item.cash + loc.item.credit))>
								<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
							</cfdefaultcase>
						</cfswitch>
						<cfset session.basket.total.balance -= (loc.item.cash + loc.item.credit)>
						<!---<cfset session.basket.info.canClose = ArrayLen(session.basket.payments) gt 0>--->
					</cfloop>
	
					<cfif session.basket.info.itemcount gt 0 AND ArrayLen(session.basket.payments) GT 0>
						<cfif session.basket.info.mode eq "reg">
							<cfif session.basket.total.balance lte 0>
								<cfset session.basket.info.change = session.basket.total.balance>
								<cfset session.basket.total.cashINDW += session.basket.info.change>
								<cfset session.basket.header.cashtaken += session.basket.info.change>
								<cfset session.basket.header.balance = 0>
								<cfset session.basket.total.balance = 0>
							</cfif>
						<cfelse>
							<cfif session.basket.total.balance lt 0>
							<cfelse>
								<cfset session.basket.info.change = session.basket.total.balance>
								<cfset session.basket.total.cashINDW += session.basket.info.change>
								<cfset session.basket.header.cashtaken += session.basket.info.change>
								<cfset session.basket.header.balance = 0>
								<cfset session.basket.total.balance = 0>
							</cfif>
						</cfif>
					</cfif>
				</cfoutput>
			</cflock>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="BuildBasket" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
			<cfdump var="#loc#" label="BuildBasket" expand="yes" format="html"
				output="#application.site.dir_logs#epos\errbuild-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc>
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
			<cfdump var="#cfcatch#" label="WriteTotal" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="SaveTillTotals" access="public" returntype="void">
		<cfset var loc = {}>
		<cfset loc.keys = ListSort(StructKeyList(session.till.total,","),"text","ASC",",")>
		<cfloop list="#loc.keys#" index="loc.fld">
			<!---<cfif session.till.total[loc.fld] neq 0>--->
			<cfset WriteTotal(loc.fld,session.till.total[loc.fld])>
			<!---</cfif>--->
		</cfloop>
	</cffunction>

	<cffunction name="CalcTotals" access="public" returntype="void" hint="calculate till totals.">
		<cfset session.basket.total.cashINDW = session.basket.header.cashtaken + session.basket.info.change>
		<cfset session.basket.header.cashtaken += session.basket.header.balance>
		<cfset session.basket.header.balance = 0>
	</cffunction>

	<cffunction name="CloseTransaction" access="public" returntype="void">
		<cfset var loc = {}>

		<cftry>
			<!--- code --->
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
			<cfset WriteTransaction(session.basket)>
			<cfset session.till.prevtran = session.basket>
			<cfset ClearBasket()>
			<cfset SaveTillTotals()>

			<!--- Create archive record of basket DISABLED --->
			<!--- Used in transaction barcode restoration --->
			<!--- Returns archive ID --->
			<!---<cfset session.till.prevtran.archive = new App.EPOSArchive().save({
				'json' = serializeJSON(session.till.prevtran)
			})>--->
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="CloseTransaction" expand="yes" format="html" 
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="ShowTrans" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cftry>
			<cfset loc.total.retail = 0>
			<cfset loc.total.gross = 0>
			<cfset loc.total.net = 0>
			<cfset loc.total.vat = 0>
			<cfset loc.total.disc = 0>
			<cfset loc.total.cash = 0>
			<table class="tableList">
				<tr>
					<td>title</td>
					<td width="50">ProdID</td>
					<td>CASH</td>
					<td align="right" width="50">retail</td>
					<td align="right" width="50">gross</td>
					<td align="right" width="50">net</td>
					<td align="right" width="50">vat</td>
					<td align="right" width="50">rate</td>
					<td align="right" width="50">disc</td>
				</tr>
				<cfoutput>
				<cfloop array="#args.trans#" index="loc.tran">
					<cfset loc.disc = 0>
					<cfset loc.prodID = 1>
					<cfset loc.pubID = 1>
					<cfset loc.account = 1>
					<cfset loc.payID = 1>
					<cfset loc.retail = 0>
					<cfset loc.total.cash += (loc.tran.gross * loc.tran.cashOnly)>
					<cfswitch expression="#loc.tran.itemClass#">
						<cfcase value="SHOP|MAGS" delimiters="|">
							<cfset loc.prodKey = "#loc.tran.prodID#-#loc.tran.price#">
							<cfif StructKeyExists(args.shopItems,loc.prodKey)>
								<cfset loc.data = StructFind(args.shopItems,loc.prodKey)>
							<cfelse>
								<cfset loc.data = StructFind(args.shopItems,loc.tran.prodID)>
							</cfif>
							<cfset loc.total.retail += loc.data.unitPrice>
							<cfset loc.tran.itemType = "sale">
							<cfset loc.disc = loc.data.unitPrice + loc.tran.gross>
							<cfset loc.retail = loc.data.unitPrice>
							<cfset loc.prodID = loc.tran.prodID>
							<tr>
								<td>#loc.data.title#</td>
								<td align="right">#loc.tran.prodID#</td>
								<td>#loc.tran.cashOnly#</td>
								<td align="right">#loc.data.unitPrice#</td>
								<td align="right">#loc.tran.gross#</td>
								<td align="right">#loc.tran.net#</td>
								<td align="right">#loc.tran.vat#</td>
								<td align="right">#loc.tran.vrate#%</td>
								<td align="right">#loc.disc#</td>
							</tr>
						</cfcase>
						<cfcase value="paystation|NEWS|LOTTERY|SRV|SCRATCHCARD|LPRIZE|SPRIZE" delimiters="|">
							<cfset loc.total.retail -= loc.tran.gross>
							<cfset loc.tran.itemType = "item">
							<cfset loc.prodID = loc.tran.prodID>
							<cfset loc.retail = loc.tran.gross>
							<tr>
								<td>#loc.tran.itemClass#</td>
								<td align="right">#loc.tran.prodID#</td>
								<td>#loc.tran.cashOnly#</td>
								<td align="right">#DecimalFormat(loc.tran.gross)#</td>
								<td align="right">#DecimalFormat(loc.tran.gross)#</td>
								<td align="right">#DecimalFormat(loc.tran.net)#</td>
								<td align="right">#DecimalFormat(loc.tran.vat)#</td>
								<td align="right">#DecimalFormat(loc.tran.vrate)#%</td>
								<td align="right"></td>
							</tr>
						</cfcase>
						<cfcase value="ACCPAY">
							<cfset loc.total.retail += loc.tran.gross>
							<cfset loc.tran.itemType = "item">
							<cfset loc.account = loc.tran.account>
							<cfset loc.retail = loc.tran.gross>
							<tr>
								<td>#loc.tran.itemClass#</td>
								<td>?</td>
								<td>#loc.tran.cashOnly#</td>
								<td align="right">#DecimalFormat(loc.tran.gross)#</td>
								<td align="right">#DecimalFormat(loc.tran.gross)#</td>
								<td align="right">#DecimalFormat(loc.tran.net)#</td>
								<td align="right">#DecimalFormat(loc.tran.vat)#</td>
								<td align="right">#DecimalFormat(loc.tran.vrate)#%</td>
								<td align="right"></td>
							</tr>
						</cfcase>
						<cfcase value="MEDIA">
							<cfset loc.pubKey = "#loc.tran.pubID#-#loc.tran.price#">
							<cfif StructKeyExists(args.mediaItems,loc.pubKey)>
								<cfset loc.data = StructFind(args.mediaItems,loc.pubKey)>
							<cfelse>
								<cfset loc.data = StructFind(args.mediaItems,loc.tran.pubID)>
							</cfif>
							<cfset loc.total.retail += loc.data.unitPrice>
							<cfset loc.disc = loc.data.unitPrice + loc.tran.gross>
							<cfset loc.retail = loc.data.unitPrice>
							<cfset loc.tran.itemType = "sale">
							<cfset loc.pubID = loc.tran.pubID>
							<tr>
								<td>#loc.data.title#</td>
								<td align="right">#loc.tran.pubID#</td>
								<td>#loc.tran.cashOnly#</td>
								<td align="right">#loc.data.unitPrice#</td>
								<td align="right">#DecimalFormat(loc.tran.gross)#</td>
								<td align="right">#DecimalFormat(loc.tran.net)#</td>
								<td align="right">#DecimalFormat(loc.tran.vat)#</td>
								<td align="right">#DecimalFormat(loc.tran.vrate)#%</td>
								<td align="right">#DecimalFormat(loc.disc)#</td>
							</tr>
						</cfcase>
						<cfcase value="CASHINDW|CARDINDW|CHQINDW|CPN|HSV|ACCINDW|WASTE" delimiters="|">
							<cfset loc.tran.itemType = "pay">
							<cfset loc.payID = loc.tran.payID>
							<cfset loc.retail = loc.tran.gross>
							<tr>
								<td>#loc.tran.itemClass#</td>
								<td></td>
								<td>#loc.tran.cashOnly#</td>
								<td></td>
								<td align="right">#DecimalFormat(loc.tran.gross)#</td>
								<td align="right">#DecimalFormat(loc.tran.net)#</td>
								<td align="right">#DecimalFormat(loc.tran.vat)#</td>
								<td align="right"></td>
								<td align="right"></td>
							</tr>
						</cfcase>
					</cfswitch>
					<cfset loc.total.gross -= loc.tran.gross>
					<cfset loc.total.net -= loc.tran.net>
					<cfset loc.total.vat -= loc.tran.vat>
					<cfset loc.total.disc += loc.disc>
				</cfloop>
				<tr>
					<th>Totals</th>
					<th></th>
					<th>#loc.total.cash#</th>
					<th align="right">#loc.total.retail#</th>
					<th align="right">#DecimalFormat(loc.total.gross)#</th>
					<th align="right">#DecimalFormat(loc.total.net)#</th>
					<th align="right">#DecimalFormat(loc.total.vat)#</th>
					<th align="right"></th>
					<th align="right">#DecimalFormat(loc.total.disc)#</th>
				</tr>
				</cfoutput>
			</table>
			<cfcatch type="any">
				<cfdump var="#cfcatch#" label="ShowTrans" expand="yes" format="html"
					output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="WriteTransaction" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">

		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.showInfo = false>
		<cftry>
			<cfif session.user.ID gt 0>
				<cfoutput>
					<cfquery name="loc.QInsertHeader" datasource="#GetDataSource()#" result="loc.QInsertHeaderResult">
						INSERT INTO tblEPOS_Header (
							ehEmployee,
							ehMode,
							ehCashback
						) VALUES (
							#session.user.ID#,
							'#session.basket.info.mode#',
							#session.basket.header.cashback#
						)
					</cfquery>
					<cfset loc.ID = loc.QInsertHeaderResult.generatedkey>
					<cfset session.basket.tranID = loc.ID>
					<cfset loc.total.retail = 0>
					<cfset loc.total.gross = 0>
					<cfset loc.total.net = 0>
					<cfset loc.total.vat = 0>
					<cfset loc.total.disc = 0>
					<cfset loc.itemStr = "">
					<cfif loc.showInfo>
					<table class="tableList" border="1">
						<tr>
							<td>title</td>
							<td width="50">ProdID</td>
							<td align="right" width="50">retail</td>
							<td align="right" width="50">gross</td>
							<td align="right" width="50">trade</td>
							<td align="right" width="50">net</td>
							<td align="right" width="50">vat</td>
							<td align="right" width="50">rate</td>
							<td align="right" width="50">disc</td>
							<td align="right" width="50">wsp</td>
						</tr>
					</cfif>
					<cfloop array="#args.trans#" index="loc.tran">
						<cfset loc.disc = 0>
						<cfset loc.prodID = 1>
						<cfset loc.pubID = 1>
						<cfset loc.payID = 1>
						<cfset loc.account = 1>
						<cfset loc.supplier = 1>
						<cfset loc.retail = 0>
						<cfswitch expression="#loc.tran.itemClass#">
							<cfcase value="SHOP">
								<cfset loc.prodKey = "#loc.tran.prodID#-#loc.tran.price#">
								<cfif StructKeyExists(args.shopItems,loc.prodKey)>
									<cfset loc.data = StructFind(args.shopItems,loc.prodKey)>
								<cfelse>
									<cfset loc.data = StructFind(args.shopItems,loc.tran.prodID)>
								</cfif>
								<cfset loc.total.retail += loc.data.unitPrice>
								<cfset loc.tran.itemType = "sale">
								<cfset loc.disc = loc.data.unitPrice + loc.tran.gross>
								<cfset loc.retail = loc.data.unitPrice>
								<cfset loc.prodID = loc.data.itemID>
								<cfif loc.showInfo>
								<tr>
									<td>#loc.data.title#</td>
									<td>#loc.tran.prodID#</td>
									<td align="right">#loc.data.unitPrice#</td>
									<td align="right">#loc.tran.gross#</td>
									<td align="right">#loc.tran.unittrade#</td>
									<td align="right">#loc.tran.net#</td>
									<td align="right">#loc.tran.vat#</td>
									<td align="right">#loc.tran.vrate#%</td>
									<td align="right">#loc.disc#</td>
									<td align="right">#loc.tran.unitTrade#</td>
								</tr>
								</cfif>
							</cfcase>
							<cfcase value="MAGS">
								<cfset loc.prodID = 6>
								<cfset loc.prodKey = "#loc.tran.prodID#-#loc.tran.price#">
								<cfif StructKeyExists(args.magsItems,loc.prodKey)>
									<cfset loc.data = StructFind(args.magsItems,loc.prodKey)>
								<cfelse>
									<cfset loc.data = StructFind(args.magsItems,loc.tran.prodID)>
								</cfif>
								<cfset loc.total.retail += loc.data.unitPrice>
								<cfset loc.tran.itemType = "sale">
								<cfset loc.disc = loc.data.unitPrice + loc.tran.gross>
								<cfset loc.retail = loc.data.unitPrice>
								<cfset loc.prodID = loc.data.itemID>
								<cfif loc.showInfo>
								<tr>
									<td>#loc.data.title#</td>
									<td>#loc.tran.prodID#</td>
									<td align="right">#loc.data.unitPrice#</td>
									<td align="right">#loc.tran.gross#</td>
									<td align="right">##</td>
									<td align="right">#loc.tran.net#</td>
									<td align="right">#loc.tran.vat#</td>
									<td align="right">#loc.tran.vrate#%</td>
									<td align="right">#loc.disc#</td>
								</tr>
								</cfif>
							</cfcase>
							<cfcase value="PAYSTATION|SRV|LOTTERY|SCRATCHCARD|SPRIZE|LPRIZE|NEWS|VOUCHER|BUNNERY" delimiters="|">
								<cfswitch expression="#loc.tran.itemClass#">
									<cfcase value="VOUCHER">
										<cfset loc.prodID = 9>
									</cfcase>
									<cfcase value="NEWS">
										<cfset loc.prodID = 10>
									</cfcase>
									<cfcase value="PAYSTATION">
										<cfset loc.prodID = 11>
									</cfcase>
									<cfcase value="BUNNERY">
										<cfset loc.prodID = 147772>
									</cfcase>
									<cfdefaultcase>
										<cfset loc.prodID = loc.tran.prodID>
									</cfdefaultcase>
								</cfswitch>
								<cfset loc.total.retail -= loc.tran.gross>
								<cfset loc.tran.itemType = "item">
								<cfset loc.retail = loc.tran.gross>
								<cfif loc.showInfo>
								<tr>
									<td>#loc.tran.itemClass#</td>
									<td>#loc.tran.prodID#</td>
									<td align="right">#DecimalFormat(loc.tran.gross)#</td>
									<td align="right">#DecimalFormat(loc.tran.gross)#</td>
									<td align="right">##</td>
									<td align="right">#DecimalFormat(loc.tran.net)#</td>
									<td align="right">#DecimalFormat(loc.tran.vat)#</td>
									<td align="right">#DecimalFormat(loc.tran.vrate)#%</td>
									<td align="right"></td>
								</tr>
								</cfif>
							</cfcase>
							<cfcase value="ACCPAY">
								<cfset loc.total.retail += loc.tran.gross>
								<cfset loc.tran.itemType = "item">
								<cfset loc.account = loc.tran.account>
								<cfset loc.retail = loc.tran.gross>
								<cfset loc.prodID = 12>
								<cfif loc.showInfo>
								<tr>
									<td>#loc.tran.itemClass#</td>
									<td>?</td>
									<td align="right">#DecimalFormat(loc.tran.gross)#</td>
									<td align="right">#DecimalFormat(loc.tran.gross)#</td>
									<td align="right">#loc.tran.unittrade#</td>
									<td align="right">#DecimalFormat(loc.tran.net)#</td>
									<td align="right">#DecimalFormat(loc.tran.vat)#</td>
									<td align="right">#DecimalFormat(loc.tran.vrate)#%</td>
									<td align="right"></td>
								</tr>
								</cfif>
							</cfcase>
							<cfcase value="MEDIA">
								<cfset loc.prodID = 6>
								<cfset loc.pubKey = "#loc.tran.pubID#-#loc.tran.price#">
								<cfif StructKeyExists(args.mediaItems,loc.pubKey)>
									<cfset loc.data = StructFind(args.mediaItems,loc.pubKey)>
								<cfelse>
									<cfset loc.data = StructFind(args.mediaItems,loc.tran.pubID)>
								</cfif>
								<cfset loc.total.retail += loc.data.unitPrice>
								<cfset loc.disc = loc.data.unitPrice + loc.tran.gross>
								<cfset loc.retail = loc.data.unitPrice>
								<cfset loc.tran.itemType = "sale">
								<cfset loc.pubID = loc.data.itemID>
								<cfif loc.showInfo>
								<tr>
									<td>#loc.data.title#</td>
									<td>#loc.tran.pubID#</td>
									<td align="right">#loc.data.unitPrice#</td>
									<td align="right">#DecimalFormat(loc.tran.gross)#</td>
									<td align="right">#loc.tran.unittrade#</td>
									<td align="right">#DecimalFormat(loc.tran.net)#</td>
									<td align="right">#DecimalFormat(loc.tran.vat)#</td>
									<td align="right">#DecimalFormat(loc.tran.vrate)#%</td>
									<td align="right">#DecimalFormat(loc.disc)#</td>
								</tr>
								</cfif>
							</cfcase>
							<cfcase value="WASTE" delimiters="|">
								<cfset loc.prodID = 13>
								<cfset loc.tran.itemType = "pay">
								<cfset loc.payID = loc.tran.payID>
								<cfset loc.retail = 0>
								<cfset loc.tran.qty = abs(loc.tran.qty)>
								<cfif loc.showInfo>
								<tr>
									<td>#loc.tran.itemClass#</td>
									<td></td>
									<td></td>
									<td align="right">#DecimalFormat(loc.tran.gross)#</td>
									<td align="right"></td>
									<td align="right">#DecimalFormat(loc.tran.net)#</td>
									<td align="right">#DecimalFormat(loc.tran.vat)#</td>
									<td align="right"></td>
									<td align="right"></td>
								</tr>
								</cfif>
							</cfcase>
							<cfcase value="CASHINDW|CARDINDW|CHQINDW|ACCINDW|BANKXFR|ONLINE|CPN|HSV" delimiters="|">
								<cfswitch expression="#loc.tran.itemClass#">
									<cfcase value="CARDINDW">
										<cfset loc.prodID = 2>
									</cfcase>
									<cfcase value="CASHINDW">
										<cfset loc.prodID = 3>
									</cfcase>
									<cfcase value="CHQINDW">
										<cfset loc.prodID = 4>
									</cfcase>
									<cfcase value="ACCINDW">
										<cfset loc.prodID = 7>
									</cfcase>
									<cfcase value="BANKXFR">
										<cfset loc.prodID = 15>
									</cfcase>
									<cfcase value="ONLINE">
										<cfset loc.prodID = 16>
									</cfcase>
									<cfcase value="HSV">
										<cfset loc.prodID = 8>
									</cfcase>
									<cfcase value="CPN">
										<cfset loc.prodID = 17>
									</cfcase>
									<cfdefaultcase>
										<cfset loc.prodID = 1>
									</cfdefaultcase>
								</cfswitch>
								<cfset loc.tran.itemType = "pay">
								<cfset loc.payID = loc.tran.payID>
								<cfset loc.retail = 0>
								<cfif loc.showInfo>
								<tr>
									<td>#loc.tran.itemClass#</td>
									<td></td>
									<td></td>
									<td align="right">#DecimalFormat(loc.tran.gross)#</td>
									<td align="right"></td>
									<td align="right">#DecimalFormat(loc.tran.net)#</td>
									<td align="right">#DecimalFormat(loc.tran.vat)#</td>
									<td align="right"></td>
									<td align="right"></td>
								</tr>
								</cfif>
							</cfcase>
							<cfcase value="SUPPLIER">
								<cfset loc.prodID = 5>
								<cfset loc.supplier = loc.tran.supplier>
								<cfset loc.tran.itemType = "supp">
								<cfset loc.retail = loc.tran.gross>
								<cfif loc.showInfo>
								<tr>
									<td>#loc.tran.itemClass#</td>
									<td>#loc.account#</td>
									<td></td>
									<td align="right">#DecimalFormat(loc.tran.gross)#</td>
									<td align="right">##</td>
									<td align="right">#DecimalFormat(loc.tran.net)#</td>
									<td align="right">#DecimalFormat(loc.tran.vat)#</td>
									<td align="right"></td>
									<td align="right"></td>
								</tr>
								</cfif>
							</cfcase>
							<cfdefaultcase><!--- unhandled --->
								<cfdump var="#loc.tran#" label="unhandled class #loc.tran.itemClass#" expand="yes" format="html"
									output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
							</cfdefaultcase>
						</cfswitch>
						<cfset loc.total.gross -= loc.tran.gross>
						<cfset loc.total.net -= loc.tran.net>
						<cfset loc.total.vat -= loc.tran.vat>
						<cfset loc.total.disc += loc.disc>
						<cfset loc.net = loc.tran.net>
						<cfset loc.vat = loc.tran.vat>
						<cfif StructKeyExists(loc.tran,"unitTrade")>
							<cfset loc.trade = val(loc.tran.unitTrade)>
						<cfelse><cfset loc.trade = 0></cfif>
						<cfif StructKeyExists(loc.tran,"qty")>
							<cfset loc.qty = val(loc.tran.qty)>
						<cfelse><cfset loc.qty = 1></cfif>
						<cfset loc.itemStr = "#loc.itemStr#,(#loc.ID#,'#loc.tran.itemType#','#loc.tran.itemClass#',#loc.prodID#,#loc.pubID#,#loc.payID#,
							#loc.account#,#loc.supplier#,#loc.retail#,#loc.net#,#loc.vat#,#loc.trade#,#loc.qty#)">
					</cfloop>
					<cfif abs(loc.total.gross) gte 0.01>		<!--- dump basket if transaction not balanced --->
						<cfdump var="#session.basket#" label="basket" expand="yes" format="html"
							output="#application.site.dir_logs#epos\bskt-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
					</cfif>
					<cfset loc.itemStr = RemoveChars(loc.itemStr,1,1)>
						<cfif loc.showInfo>
						<tr>
							<td>Totals</td>
							<td></td>
							<td align="right">#loc.total.retail#</td>
							<td align="right">#DecimalFormat(loc.total.gross)#</td>
							<td align="right">##</td>
							<td align="right">#DecimalFormat(loc.total.net)#</td>
							<td align="right">#DecimalFormat(loc.total.vat)#</td>
							<td align="right"></td>
							<td align="right">#DecimalFormat(loc.total.disc)#</td>
						</tr>
						</cfif>
					</table>
				<!---<cfdump var="#loc#" label="loc. WriteTransaction" expand="yes" format="html"
					output="#application.site.dir_logs#epos\write-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">--->
					<cfset loc.fields = "(
							eiParent,
							eiClass,
							eiType,
							eiProdID,
							eiPubID,
							eiPayID,
							eiAccID,
							eiSuppID,
							eiRetail,
							eiNet,
							eiVAT,
							eiTrade,
							eiQty
						)">
					<cfquery name="loc.QInsertItem" datasource="#GetDataSource()#">
						INSERT INTO tblEPOS_Items (
							eiParent,
							eiClass,
							eiType,
							eiProdID,
							eiPubID,
							eiPayID,
							eiAccID,
							eiSuppID,
							eiRetail,
							eiNet,
							eiVAT,
							eiTrade,
							eiQty
						) VALUES
						#PreserveSingleQuotes(loc.itemStr)#
					</cfquery>
					<!--- update header --->
					<cfquery name="loc.QUpdateHeader" datasource="#GetDataSource()#" result="loc.QUpdateResult">
						UPDATE tblEPOS_Header
						SET ehPayAcct = #loc.payID#
						WHERE ehID = #loc.ID#
					</cfquery>
				</cfoutput>
			<cfelse>
				<cfset session.basket.info.errMsg = "Till operator's session timed out.">
			</cfif>

		<cfcatch type="any">
			<cfset session.basket.info.errMsg = "AN ERROR OCCURRED WRITING THE TRAN">
			<cfdump var="#cfcatch#" label="" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
			<cfdump var="#session#" label="session" expand="yes" format="html"
				output="#application.site.dir_logs#epos\bask-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

<!---
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
			<cfdump var="#cfcatch#" label="PrintReceipt" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
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
					output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
			</cfcatch>
		</cftry>

		<cfreturn loc.contentResult>
	</cffunction>
--->
	<cffunction name="VATSummary" access="public" returntype="void">
		<cfargument name="args" type="array" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.VATTable = {}>
		<cftry>
			<cfoutput>
				<cfloop array="#args#" index="loc.i">
					<cfif StructKeyExists(loc.i,"vcode")>
						<cfif NOT StructKeyExists(loc.VATTable,loc.i.vcode)>
							<cfset StructInsert(loc.VATTable,loc.i.vcode,{"rate" = loc.i.vrate, "gross" = loc.i.gross, "net" = loc.i.net, "vat" = loc.i.vat})>
						<cfelse>
							<cfset loc.vatRec = StructFind(loc.VATTable,loc.i.vcode)>
							<cfset StructUpdate(loc.VATTable,loc.i.vcode,{
								rate = loc.i.vrate,
								gross = loc.vatRec.gross + loc.i.gross,
								net = loc.vatRec.net + loc.i.net,
								vat = loc.vatRec.vat + loc.i.vat
							})>
						</cfif>
					</cfif>
				</cfloop>
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
								<cfloop collection="#loc.VATTable#" item="loc.key">
									<cfset loc.linecount++>
									<cfset loc.line = StructFind(loc.VATTable,loc.key)>
									<cfset loc.total.net += loc.line.net>
									<cfset loc.total.vat += loc.line.vat>
									<cfset loc.total.gross += loc.line.gross>
									<tr>
										<td align="right">#DecimalFormat(loc.line.rate)#%</td>
										<td align="right">#DecimalFormat(-loc.line.net)#</td>
										<td align="right">#DecimalFormat(-loc.line.vat)#</td>
										<td align="right">#DecimalFormat(-loc.line.gross)#</td>
									</tr>
								</cfloop>
								<cfif loc.linecount gt 1>
									<tr>
										<td align="right">Total</td>
										<td align="right">#DecimalFormat(-loc.total.net)#</td>
										<td align="right">#DecimalFormat(-loc.total.vat)#</td>
										<td align="right">#DecimalFormat(-loc.total.gross)#</td>
									</tr>
								</cfif>
							</table>
							VAT No.: #session.till.prefs.vatno#
						</td>
					</tr>
				</table>
			</cfoutput>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="VATSummary" expand="yes" format="html"
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="GetAccounts" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>

		<cftry>
			<cfquery name="loc.result.Accounts" datasource="#GetDataSource()#">
				SELECT eaID,eaTitle,eaTillPayment,eaMenu
				FROM tblEPOS_Account
				WHERE eaActive
				ORDER BY eaOrder
			</cfquery>
			<cfset loc.result.btns = []>
			<cfset loc.result.accts = []>
			<cfloop query="loc.result.Accounts">
				<cfif eaMenu eq 'Yes'>
					<cfset ArrayAppend(loc.result.accts,{eaID=eaID,eaTitle=eaTitle})>
				<cfelse>
					<cfset ArrayAppend(loc.result.btns,{eaID=eaID,eaTitle=eaTitle})>
				</cfif>
			</cfloop>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="GetAccounts" expand="yes" format="html"
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
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
		<cfset loc.midnight = LSDateFormat(Now(),"yyyy-mm-dd")>
		<cftry>
			<cfquery name="loc.QDates" datasource="#GetDataSource()#">
				SELECT DISTINCT totDate
				FROM tblEPOS_Totals
				WHERE totDate < '#loc.midnight#'
				ORDER BY totDate DESC
			</cfquery>
			
			<cfloop query="loc.QDates">
				<cfset loc.dateOnly = LSDateFormat(totDate,"yyyy-mm-dd")>
				<cfset ArrayAppend(loc.result.recs,{"value"=loc.dateOnly,"title"=LSDateFormat(loc.dateOnly,"dd-mmm-yyyy")})>
			</cfloop>
			<cfset ArrayPrepend(loc.result.recs,{"value"=LSDateFormat(Now(),"yyyy-mm-dd"),"title"=LSDateFormat(Now(),"dd-mmm-yyyy")})>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="GetDates" expand="yes" format="html"
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
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
			<cfquery name="loc.QTotals" datasource="#GetDataSource()#">
				SELECT *
				FROM tblEPOS_Totals
				WHERE totDate='#session.till.prefs.reportDate#'
			</cfquery>
			<cfloop query="loc.QTotals">
				<cfset StructInsert(session.till.total,totAcc,totValue,true)>
			</cfloop>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="LoadTillTotals" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="LoadEPOSTotals" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfreturn new App.EPOSTotal().getTotals(args.reportDateFrom)>
	</cffunction>

	<cffunction name="LoadDeals" access="public" returntype="void" hint="Load deal info.">
		<cfargument name="args" type="struct" required="no" default="{}">
		<cftry>
			<cfset loc = {}>
			<cfquery name="loc.QActiveDeals" datasource="#GetDataSource()#">
				SELECT tblEPOS_Deals.*, ercTitle
				FROM tblEPOS_Deals
				INNER JOIN tblEPOS_RetailClubs ON edRetailClub = ercID
				WHERE edStatus = 'active'
				AND edStarts <= DATE(#Now()#)
				AND edEnds >= DATE(#Now()#)
				ORDER BY ercTitle,edTitle
			</cfquery>

			<cfset session.deals = loc.QActiveDeals>
			<cfset session.dealdata = {}>
			<cfset session.dealOrder = []>
			<cfloop query="loc.QActiveDeals">
				<cfset StructInsert(session.dealdata,edID,{
					"ercTitle" = ercTitle,
					"edType" = edType,
					"edDealType" = edDealType,
					"edTitle" = edTitle,
					"edQty" = edQty,
					"edAmount" = edAmount,
					"edStarts" = LSDateFormat(edStarts,'yyyy-mm-dd'),
					"edEnds" = LSDateFormat(edEnds,'yyyy-mm-dd')
				})>
				<cfset ArrayAppend(session.dealOrder,edID)>
			</cfloop>
			<cfquery name="loc.QualifyingProducts" datasource="#GetDataSource()#">
				SELECT ediProduct,ediParent
				FROM tblEPOS_DealItems
				INNER JOIN tblEPOS_Deals ON ediParent = edID
				WHERE edStatus = 'active'
				AND edStarts <= DATE(#Now()#)
				AND edEnds >= DATE(#Now()#)
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
			<cfdump var="#cfcatch#" label="LoadDeals" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="LoadVAT" access="public" returntype="void">
		<cfset var loc = {}>
		<cftry>
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
			<cfdump var="#loc#" label="LoadVAT" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="LoadDayHeader" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cftry>
			<cfif IsDate(args.reportDate)>
				<cfquery name="loc.QDayHeader" datasource="#GetDataSource()#">	<!--- get specified day header record --->
					SELECT *
					FROM tblepos_dayheader
					WHERE DATE(dhTimeStamp) = '#args.reportDate#'
				</cfquery>
				<cfif loc.QDayHeader.recordcount is 0>
					<cfquery name="loc.QDayHeader" datasource="#GetDataSource()#">	<!--- get most recent day header record --->
						SELECT *
						FROM tblepos_dayheader
						ORDER BY dhID DESC
						LIMIT 0,1
					</cfquery>
				</cfif>

				<cfreturn QueryToStruct(loc.QDayHeader)>
			<cfelse>
				<cfreturn {}>
			</cfif>
			
		<cfcatch type="any">
			<cfdump var="#loc#" label="LoadDayHeader" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="LoadCatKeys" access="public" returntype="void">
		<cfset var loc = {}>

		<cftry>
			<cfquery name="loc.QEPOSCatKeys" datasource="#GetDataSource()#">
				SELECT DISTINCT epcKey,epcType FROM tblEPOS_Cats
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
			<cfdump var="#cfcatch#" label="LoadCatKeys" expand="yes" format="html"
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="DumpTrans" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.result.msg = "">
		<cfset loc.midnight = DateFormat(DateAdd("d",1,args.reportDateTo),"yyyy-mm-dd")>

		<cftry>
			<cfset loc.dayHeader = LoadDayHeader({"reportDate" = args.reportDateFrom})>
			<cfquery name="loc.QTrans" datasource="#GetDataSource()#" result="loc.QTransResult">
				SELECT tblEPOS_Items.*,ehMode, empFirstName,
				IF (eiType='MEDIA',
					(SELECT pubTitle FROM tblPublication WHERE pubID=eiPubID),
					IF (eiClass='pay',
						(SELECT eaTitle FROM tblEPOS_Account WHERE eaID=eiPayID),
						IF (eiType='SUPPLIER',
							(SELECT accName FROM tblaccount WHERE accID=eiSuppID),
								(SELECT prodTitle FROM tblProducts WHERE prodID=eiProdID)
						)
					)
				) title,
				tblProducts.prodCatID,tblProducts.prodUnitSize, tblproductcats.pcatTitle
				FROM tblEPOS_Items
				INNER JOIN tblEPOS_Header ON ehID = eiParent
				INNER JOIN tblemployee ON empID = ehEmployee
				INNER JOIN tblProducts ON prodID = eiProdID
				INNER JOIN tblproductcats ON prodCatID = pcatID
				WHERE 1
				<cfif StructKeyExists(args,"accountID")>
					AND eiParent IN (#args.aIDs#)
					<cfif len(args.reportDateFrom)>AND ehTimeStamp >= '#DateFormat(args.reportDateFrom,"yyyy-mm-dd")#' </cfif>
					<cfif len(args.reportDateTo)>AND ehTimeStamp <= '#DateFormat(args.reportDateTo,"yyyy-mm-dd")#' </cfif>
				<cfelse>
					<cfif len(args.reportDateFrom)>AND ehTimeStamp >= '#DateFormat(args.reportDateFrom,"yyyy-mm-dd")#' </cfif>
					<cfif len(args.reportDateTo)>AND ehTimeStamp <= '#DateFormat(args.reportDateTo,"yyyy-mm-dd")#' </cfif>
				</cfif>
				ORDER BY eiTimestamp, ehID, eiID
			</cfquery>

			<cfset loc.grandNet = 0>
			<cfset loc.grandVAT = 0>
			<cfset loc.grandCR = 0>
			<cfset loc.grandDR = 0>
			<cfset loc.grandTrade = 0>
			<cfset loc.grandRetail = 0>
			<cfset loc.grandProfit = 0>
			<cfset loc.grandDiscount = 0>
			<cfset loc.tran = 0>
			<cfset loc.showDetail = true <!---!StructKeyExists(args,"accountID")--->>
			<cfoutput>
			<div style="float:left">
			<table class="tableList">
				<tr class="noPrint">
					<th align="left" colspan="13"><input type="text" id="quicksearch" value="" placeholder="Search list" /></th>
					<cfif loc.showDetail><th colspan="6"></th></cfif>
				</tr>
				<tr>
					<th>Tran</th>
					<th>Mode</th>
					<th>ID</th>
					<th>User</th>
					<th width="80">Timestamp</th>
					<th>Class</th>
					<th>Type</th>
					<th>Method</th>
					<th>Qty</th>
					<th width="120">Category</th>
					<th>Description</th>
					<th align="right" width="60">DR</th>
					<th align="right" width="60">CR</th>
					<cfif loc.showDetail>
						<th align="right" width="60">Net</th>
						<th align="right" width="60">VAT</th>
						<th align="right" width="60">Trade<br /><span class="tiny">(net)</span></th>
						<th align="right" width="60">Retail<br /><span class="tiny">(gross)</span></th>
						<th align="right" width="60">Profit</th>
						<th align="right" width="60">Discount</th>
					</cfif>
				</tr>
				<cfset loc.balance = 0>
				<cfset loc.totTrade = 0>
				<cfset loc.totRetail = 0>
				<cfset loc.totProfit = 0>	
				<cfset loc.totDiscount = 0>		
				<cfset loc.shopTotal = 0>	
				<cfset loc.tillTotals = {}>
				<cfset loc.salesTotals = {}>
				<cfset loc.tillTotals.cashINDW = 0>
				<cfloop query="loc.QTrans">
					<cfset loc.mode = (2 * int(session.basket.info.mode neq "rfd")) - 1>	<!--- modes: reg = 1 waste = 1 refund = -1 --->
					<cfif loc.tran gt 0 AND loc.tran neq eiParent>
						<cfif loc.showDetail>
							<cfif abs(loc.balance) gt 0.001>
								<tr class="searchrow" data-title="#title#" data-prodID="#eiProdID#">
									<td colspan="14" class="balError">&nbsp;</td>
									<td align="right" class="balError">#DecimalFormat(loc.balance)#</td>
									<th align="right">#DecimalFormat(loc.totTrade)#</th>
									<th align="right">#DecimalFormat(loc.totRetail)#</th>
									<th align="right">#DecimalFormat(loc.totProfit)#</th>
									<th align="right">#DecimalFormat(loc.totDiscount)#</th>
								</tr>
							<cfelse>
								<tr class="searchrow" data-title="#title#" data-prodID="#eiProdID#">
									<th colspan="15">&nbsp;</th>
									<th align="right">#DecimalFormat(loc.totTrade)#</th>
									<th align="right">#DecimalFormat(loc.totRetail)#</th>
									<th align="right">#DecimalFormat(loc.totProfit)#</th>
									<th align="right">#DecimalFormat(loc.totDiscount)#</th>
								</tr>
							</cfif>
						<cfelse>
							<tr>
								<th colspan="19">&nbsp;</th>
							</tr>
						</cfif>
						<cfset loc.balance = 0>
						<cfset loc.totTrade = 0>
						<cfset loc.totRetail = 0>
						<cfset loc.totProfit = 0>				
						<cfset loc.totDiscount = 0>		
					</cfif>
					<cfset loc.gross = eiNet + eiVAT>
					<cfset loc.grandNet += eiNet>
					<cfset loc.grandVAT += eiVAT>
					<cfif StructKeyExists(loc.tillTotals,eiType)>
						<cfset loc.typeTotal = StructFind(loc.tillTotals,eiType)>
						<cfset loc.typeTotal += loc.gross>
						<cfset StructUpdate(loc.tillTotals,eiType,loc.typeTotal)>
					<cfelse>
						<cfset StructInsert(loc.tillTotals,eiType,loc.gross)>
					</cfif>
					
					<cfset loc.key = Replace("#eiClass#-#pcatTitle#",",","","all")>
					<cfif StructKeyExists(loc.salesTotals,loc.key)>
						<cfset loc.salesTotal = StructFind(loc.salesTotals,loc.key)>
						<cfset loc.salesTotal += loc.gross>
						<cfset StructUpdate(loc.salesTotals,loc.key,loc.salesTotal)>
					<cfelse>
						<cfset StructInsert(loc.salesTotals,loc.key,loc.gross)>
					</cfif>
					
					<cfset loc.profit = 0>
					<cfset loc.trade = 0>
					<cfset loc.retail = 0>						
					<cfset loc.discount = 0>
					<tr class="searchrow" data-title="#pcatTitle# #title#" data-prodID="#eiProdID#">
						<td><a href="reporttransaction.cfm?tranID=#eiParent#" target="tranDetail">#eiParent#</a></td>
						<td>#ehMode#</td>
						<td>#eiID#</td>
						<td>#empFirstName#</td>
						<td nowrap>#LSDateFormat(eiTimestamp,"dd-mmm-yy")# #LSTimeFormat(eiTimestamp)#</td>
						<td>#eiClass#</td>
						<td>#eiType#</td>
						<td>#eiPayType#</td>
						<td align="center">#eiQty#</td>
						<td width="200"><span title="#pcatTitle#">#Left(pcatTitle,20)#</span></td>
						<td>#title# #prodUnitSize#</td>
						<cfif loc.gross gt 0>
							<cfset loc.grandDR += loc.gross>
							<td align="right">#DecimalFormat(loc.gross)#</td>
							<td align="right" class="rhborder"></td>
						<cfelse>
							<cfset loc.grandCR -= loc.gross>
							<td align="right"></td>
							<td align="right" class="rhborder">#DecimalFormat(-loc.gross)#</td>
						</cfif>
						<cfif loc.showDetail>
							<td align="right">#eiNet#</td>
							<td align="right" class="rhborder">#eiVAT#</td>
							
							<cfif eiClass eq 'sale'>
								<cfif eiTrade neq 0>
									<cfset loc.trade = eiTrade * loc.mode>
								<cfelse>
									<cfset loc.trade = eiRetail * 0.75 * loc.mode>
								</cfif>
								<cfset loc.retail = eiRetail * loc.mode>
								<cfset loc.totTrade += loc.trade>
								<cfset loc.totRetail += loc.retail>
								<cfset loc.grandTrade += loc.trade>
								<cfset loc.grandRetail += loc.retail>
								<td align="right"><cfif loc.trade neq 0>#DecimalFormat(loc.trade)#</cfif></td>
								<td align="right"><cfif loc.retail neq 0>#DecimalFormat(loc.retail)#</cfif></td>
								
								<cfif ehMode neq 'rfd'>
									<cfset loc.profit = -(eiNet + loc.trade)>	<!--- positive result --->
									<cfset loc.discount = loc.retail +  eiNet + eiVAT>
								<cfelse>
									<cfset loc.profit = loc.trade - eiNet>	<!--- negative result --->
									<cfset loc.discount = loc.retail -  eiNet - eiVAT>
								</cfif>
								<td align="right">#DecimalFormat(loc.profit)#</td>
								<td align="right" class="rhborder">#DecimalFormat(loc.discount)#</td>
							<cfelse>
								<td colspan="4" class="rhborder"></td>
							</cfif>
						</cfif>
					</tr>
					<cfset loc.tran = eiParent>
					<cfset loc.balance += loc.gross>
					<cfset loc.totProfit += loc.profit>		
					<cfset loc.totDiscount += loc.discount>		
					<cfset loc.grandDiscount += loc.discount>		
					<cfset loc.grandProfit += loc.profit>		
				</cfloop>
				<cfif loc.showDetail>
					<cfif abs(loc.balance) gt 0.001>
						<tr>
							<td colspan="14" class="balError">&nbsp;</td>
							<td align="right" class="balError">#DecimalFormat(loc.balance)#</td>
							<th align="right">#DecimalFormat(loc.totTrade)#</th>
							<th align="right">#DecimalFormat(loc.totRetail)#</th>
							<th align="right">#DecimalFormat(loc.totProfit)#</th>
							<th align="right">#DecimalFormat(loc.totDiscount)#</th>
						</tr>
					<cfelse>
						<tr>
							<th colspan="15">&nbsp;</th>
							<th align="right">#DecimalFormat(loc.totTrade)#</th>
							<th align="right">#DecimalFormat(loc.totRetail)#</th>
							<th align="right">#DecimalFormat(loc.totProfit)#</th>
							<th align="right">#DecimalFormat(loc.totDiscount)#</th>
						</tr>
					</cfif>
				</cfif>
				<tr>
					<td colspan="19" class="rhborder">&nbsp;</td>
				</tr>
				<tr id="pagetotals">
					<th colspan="11">Grand Total</th>
					<th align="right">#DecimalFormat(loc.grandDR)#</th>
					<th align="right">#DecimalFormat(loc.grandCR)#</th>
					<cfif loc.showDetail>
						<th align="right">#DecimalFormat(loc.grandNet)#</th>
						<th align="right">#DecimalFormat(loc.grandVAT)#</th>
						<th align="right">#DecimalFormat(loc.grandTrade)#</th>
						<th align="right">#DecimalFormat(loc.grandRetail)#</th>
						<th align="right">#DecimalFormat(loc.grandProfit)#</th>
						<th align="right">#DecimalFormat(loc.grandDiscount)#</th>
					</cfif>
				</tr>
			</table>
			</div>
			<cfset loc.diff = abs(loc.grandDR - loc.grandCR)>
			<cfif loc.diff gt 0.001 >
				<p>
					Warning, accounts do not balance. The Repair Totals option is unavailable.<br />
					Please correct transaction errors before repairing totals.<br />
					Error total is #loc.diff#.
				 </p>
			<cfelseif NOT StructIsEmpty(loc.dayHeader)>
				<cfquery name="loc.result.QTotals" datasource="#GetDataSource()#">
					SELECT *
					FROM tblEPOS_Totals
					WHERE totDate='#args.reportDateFrom#'
				</cfquery>

				<cfset loc.result.newTotals = {}>
				<cfloop query="loc.result.QTotals">
					<cfif StructKeyExists(loc.tillTotals,totAcc)>
						<cfset loc.totalValue = StructFind(loc.tillTotals,totAcc)>
					<cfelse>
						<cfset loc.totalValue = 0>
					</cfif>
					<cfset StructInsert(loc.result.newTotals,totAcc,{"recID" = totID, "totValue" = loc.totalValue},false)>
					<cfif StructKeyExists(args,"fixTotals")>
						<cfquery name="loc.fixTotal" datasource="#GetDataSource()#">
							UPDATE tblEPOS_Totals
							SET totValue = #loc.totalValue#
							WHERE totID = #loc.result.QTotals.totID#
						</cfquery>
					</cfif>
				</cfloop>
				<cfset loc.tillTotals.discok = (abs(loc.grandDiscount) gt 0.001)>
				<cfset loc.tillTotals.discount = (abs(loc.grandDiscount) gt 0.001) ? loc.grandDiscount : 0>
				<cfset loc.tillTotals.float = -loc.dayHeader.dhFloat>
				<cfset loc.tillTotals.cashINDW += loc.dayHeader.dhFloat>
				<cfif StructKeyExists(args,"fixTotals")>
					<!--- write discount total --->
					<cfset loc.totalRec = StructFind(loc.result.newTotals,"DISCOUNT")>
					<cfquery name="loc.fixTotal" datasource="#GetDataSource()#">
						UPDATE tblEPOS_Totals
						SET totValue = #loc.grandDiscount#
						WHERE totID = #loc.totalRec.recID#
					</cfquery>
					<cfset loc.totalRec = StructFind(loc.result.newTotals,"SHOP")>
					<cfquery name="loc.fixTotal" datasource="#GetDataSource()#">
						UPDATE tblEPOS_Totals
						SET totValue = #loc.totalRec.totValue - loc.grandDiscount#
						WHERE totID = #loc.totalRec.recID#
					</cfquery>
					<cfset loc.totalRec = StructFind(loc.result.newTotals,"FLOAT")>
					<cfquery name="loc.fixTotal" datasource="#GetDataSource()#">
						UPDATE tblEPOS_Totals
						SET totValue = #-loc.dayHeader.dhFloat#
						WHERE totID = #loc.totalRec.recID#
					</cfquery>
					<cfset loc.totalRec = StructFind(loc.result.newTotals,"CASHINDW")>
					<cfquery name="loc.fixTotal" datasource="#GetDataSource()#">
						UPDATE tblEPOS_Totals
						SET totValue = #loc.totalRec.totValue + loc.dayHeader.dhFloat#
						WHERE totID = #loc.totalRec.recID#
					</cfquery>
				</cfif>
				<cfset loc.result.tillTotals = loc.tillTotals>
			<cfelse>
				<cfset loc.result.msg = "Day Header not available. FixTotals option cannot be used.">
			</cfif>
			<cfif StructKeyExists(args,"showAnalysis")>
				<!---<cfdump var="#loc.salesTotals#" label="salesTotals" expand="false">--->
				<div style="float:left">
					<table class="tableList">
						<tr>
							<th>Category</th>
							<th>DR</th>
							<th>CR</th>
						</tr>
						<cfset loc.cr = 0>
						<cfset loc.dr = 0>
						<cfset loc.keys = ListSort(StructKeyList(loc.salesTotals,","),"text","asc")>
						<cfloop list="#loc.keys#" index="saleTotal">
							<cfset loc.item = StructFind(loc.salesTotals,saleTotal)>
							<tr>
								<td>#ListRest(saleTotal,"-")#</td>
								<cfif loc.item gt 0>
									<cfset loc.dr += loc.item>
									<td align="right">#DecimalFormat(loc.item)#</td>
									<td align="right" class="rhborder"></td>
								<cfelse>
									<cfset loc.cr -= loc.item>
									<td align="right"></td>
									<td align="right" class="rhborder">#DecimalFormat(-loc.item)#</td>
								</cfif>
							</tr>
						</cfloop>
							<tr>
								<th>Totals</th>
								<th align="right">#DecimalFormat(loc.dr)#</th>
								<th align="right">#DecimalFormat(loc.cr)#</th>
							</tr>
					</table>
				</div>
			</cfif>
			</cfoutput>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="DumpTrans" expand="yes" format="html"
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc>
	</cffunction>

</cfcomponent>
