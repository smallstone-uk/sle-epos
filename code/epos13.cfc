<cfcomponent displayname="EPOS" hint="version 13. EPOS Till Functions">

	<cffunction name="GetDataSource" access="public" returntype="string">
		<cfreturn application.site.datasource1>
	</cffunction>
	
	<cffunction name="ZTill" access="public" returntype="void" hint="initialise till at start of day.">
		<cfargument name="loadDate" type="date" required="yes">
		<cfset StructDelete(session,"till",false)>
		<cfset session.till = {}>
		
		<!---Transaction in progress flag--->
		<cfset session.till.isTranOpen = true>
		
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
		<cfset session.till.info.staff = false>
		
		 <!--- <cfset session.basket.media = []>
		<cfset session.basket.supplier = []>--->
		<!---<cfset session.basket.prizes = []>--->
		<!---<cfset session.basket.vouchers = []>--->
		<!---<cfset session.basket.coupons = []>--->
		<!---<cfset session.basket.paypoint = []>--->
		<!--- <cfset session.basket.received = 0>	not required ? --->

		<cfset session.basket.payments = []>
		<cfset session.basket.news = []>		
		<cfset session.basket.vatAnalysis = {}>
		
		<cfset session.basket.header.aRetail = 0>
		<cfset session.basket.header.aNet = 0>
		<cfset session.basket.header.aVAT = 0>
		<cfset session.basket.header.aDiscDeal = 0>
		<cfset session.basket.header.aDiscStaff = 0>
		
		<cfset session.basket.header.bCash = 0>
		<cfset session.basket.header.bCredit = 0>
		<cfset session.basket.header.bNews = 0>
		<cfset session.basket.header.bMedia = 0>
		<cfset session.basket.header.bPrize = 0>
		
		<cfset session.basket.header.cAcct = 0>
		<cfset session.basket.header.cVoucher = 0>
		<cfset session.basket.header.cCoupon = 0>
		<cfset session.basket.header.cPaypoint = 0>
		<cfset session.basket.header.cLottery = 0>
		
		<cfset session.basket.header.cashtaken = 0>
		<cfset session.basket.header.cardsales = 0>
		<cfset session.basket.header.chqsales = 0>
		<cfset session.basket.header.discdeal = 0>
		<cfset session.basket.header.discstaff = 0>
		<cfset session.basket.header.supplies = 0>
		<cfset session.basket.header.cashback = 0>
		<cfset session.basket.header.balance = 0>
		<cfset session.basket.header.change = 0>
		
		<cfset session.basket.total.cashback = 0>
		<cfset session.basket.total.chqINDW = 0>
		<cfset session.basket.total.accINDW = 0>
		<cfset session.basket.total.supplies = 0>
		<cfset session.basket.total.balance = 0>
		
		<!---<cfset session.basket.total.cashINDW = 0>
		<cfset session.basket.total.cardINDW = 0>--->
		<!---<cfset session.basket.total.vchINDW = 0>
		<cfset session.basket.total.coupINDW = 0>
		<cfset session.basket.total.shop = 0>
		<cfset session.basket.total.ext = 0>
		<cfset session.basket.total.news = 0>
		<cfset session.basket.total.media = 0>--->
	</cffunction>
	
	<cffunction name="CalcTotalsXX" access="public" returntype="void" hint="calculate till totals.">
		<!---<cfset session.basket.total.cashINDW = session.basket.header.cashtaken + session.basket.header.change>
		<cfset session.basket.total.cardINDW = session.basket.header.cardsales + session.basket.header.cashback>--->
		<cfset session.basket.total.chqINDW = session.basket.header.chqsales>
		<cfset session.basket.total.accINDW = session.basket.header.cAcct>
		<cfset session.basket.total.vchINDW = session.basket.header.cVoucher>
		<cfset session.basket.total.coupINDW = session.basket.header.cCoupon>
	</cffunction>

	<cffunction name="ProcessDeals" access="public" returntype="void">
		<cfset var loc = {}>
		<cfset loc.tranType = -1>
		<cfset loc.rec.regMode = (2 * int(session.basket.info.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
		<cftry>
			<cfloop collection="#session.basket.deals#" item="loc.dealKey">
				<cfset loc.dealData = StructFind(session.dealData,loc.dealKey)>
				<cfset loc.dealRec = StructFind(session.basket.deals,loc.dealKey)>
				<cfset ArraySort(loc.dealRec.prices,"text","ASC")>	<!--- change to DESC to optimise for customer --->
				<cfset loc.dealRec.VATTable = {}>
				<cfset loc.dealRec.dealQty = 0>
				<cfset loc.dealRec.netTotal = 0>
				<cfset loc.dealRec.dealTotal = 0>
				<cfset loc.dealRec.groupRetail = 0>
				<cfset loc.count = 0>
				<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
					<cfset loc.count++>
					<cfset loc.price = ListFirst(loc.priceKey," ")>
					<cfset loc.prodID = ListLast(loc.priceKey," ")>
					<cfset loc.data = StructFind(session.basket.shopItems,loc.prodID)>
					<!---<cfset loc.net = loc.price / (1 + (loc.data.vrate / 100))>
					<cfset loc.dealRec.netTotal += loc.net>--->
					<cfif NOT StructKeyExists(loc.dealRec.VATTable,loc.data.vcode)>
						<cfset StructInsert(loc.dealRec.VATTable,loc.data.vcode,{"rate" = vrate, "gross" = loc.price})>
					<cfelse>
						<cfset loc.vatRec = StructFind(loc.dealRec.VATTable,loc.data.vcode)>
						<cfset StructUpdate(loc.dealRec.VATTable,loc.data.vcode,{"rate" = vrate, "gross" = loc.vatRec.gross + loc.price})>
					</cfif>
					<cfset loc.dealRec.groupRetail += loc.price>
					<cfif loc.dealData.edEnds gt Now()>
						<cfif loc.count MOD loc.dealData.edQty eq 0>
							<cfset loc.dealRec.dealQty++>
							<cfset loc.data.style = "red">
							<cfswitch expression="#loc.dealData.edDealType#">
								<cfcase value="anyfor">
									<cfset loc.dealRec.dealTotal = loc.dealRec.dealQty * loc.dealData.edAmount>
									<!---<cfset loc.dealRec.dealTitle = loc.dealData.edTitle>--->
								</cfcase>
								<cfcase value="twofor">
									<cfset loc.dealRec.dealQty = int(loc.dealRec.itemCount / 2)>
									<cfset loc.dealRec.remQty = loc.dealRec.itemCount mod 2>
									<cfset loc.dealRec.dealTotal = loc.dealRec.dealQty * loc.dealData.edAmount + (loc.dealRec.remQty * loc.price)>
									<!---<cfset loc.data.dealTitle = "#loc.dealData.edTitle# &pound;#DecimalFormat(loc.dealData.edAmount)#">--->
								</cfcase>
								<cfcase value="bogof">
									<cfset loc.dealRec.dealQty = int(loc.dealRec.itemCount / 2)>
									<cfset loc.dealRec.remQty = loc.dealRec.itemCount mod 2>
									<cfset loc.dealRec.dealTotal = (loc.dealRec.dealQty * loc.price) + (loc.dealRec.remQty * loc.price)>
									<!---<cfset loc.data.dealTitle = loc.dealData.edTitle>--->
								</cfcase>
								<cfcase value="only">
									<cfset loc.dealRec.dealTotal = loc.dealRec.dealQty * loc.dealData.edAmount>
								</cfcase>
							</cfswitch>
							<cfset loc.dealRec.groupRetail = 0>
						</cfif>
					</cfif>
				</cfloop>
<!---
					REFERENCE ONLY
							<cfif loc.data.vcode gt 0>
								<cfif NOT StructKeyExists(session.basket.vatAnalysis,loc.data.vcode)>
									<cfset StructInsert(session.basket.vatAnalysis,loc.data.vcode,{
										"vrate"=loc.data.vrate,"net"=loc.data.totalNet,"VAT"=loc.data.totalVat,
											"gross"=loc.data.totalGross,"items"=1})>
								<cfelse>
									<cfset loc.vatAnalysis = StructFind(session.basket.vatAnalysis,loc.data.vcode)>
									<cfset loc.vatAnalysis.net += loc.data.totalNet>
									<cfset loc.vatAnalysis.vat += loc.data.totalVat>
									<cfset loc.vatAnalysis.gross += loc.data.totalGross>
									<cfset loc.vatAnalysis.items++>
									<cfset StructUpdate(session.basket.vatAnalysis,loc.data.vcode,loc.vatAnalysis)>
								</cfif>
							</cfif>				
--->
				<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
				<cfset loc.dealRec.savingGross = loc.dealRec.retail - loc.dealRec.totalCharge>
				
				<cfset loc.dealRec.savingNet = 0>
				<cfset loc.dealRec.savingVAT = 0>
				<cfloop collection="#loc.dealRec.VATTable#" item="loc.vatKey">
					<cfset loc.vatItem = StructFind(loc.dealRec.VATTable,loc.vatKey)>
					<cfset loc.vatItem.prop = loc.vatItem.gross / loc.dealRec.retail>
					<cfset loc.vatItem.saveGross = loc.dealRec.savingGross * loc.vatItem.prop>
					<cfset loc.vatItem.saveNet = loc.vatItem.saveGross / (1 + (loc.vatItem.rate / 100))>
					<cfset loc.vatItem.saveVAT = loc.vatItem.saveGross - loc.vatItem.saveNet>
					<cfset loc.dealRec.savingNet += (loc.dealRec.savingGross * loc.vatItem.prop) / (1 + (loc.vatItem.rate / 100))>
				</cfloop>
				<cfset loc.dealRec.savingVAT += loc.dealRec.savingGross - loc.dealRec.savingNet>
				
				<!---<cfset loc.dealRec.savingGross = loc.dealRec.savingGross * loc.tranType * loc.rec.regMode>
				<cfset loc.dealRec.savingNet = loc.dealRec.savingNet * loc.tranType * loc.rec.regMode>
				<cfset loc.dealRec.savingVAT = loc.dealRec.savingVAT * loc.tranType * loc.rec.regMode>--->
				<!---<cfdump var="#loc#" label="loc #loc.dealKey#" expand="yes">--->			
			</cfloop>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="ProcessDealsxx" access="public" returntype="void">
		<cfset var loc = {}>
		
		<cftry>
			<cfloop collection="#session.basket.deals#" item="loc.dealKey">
				<cfset loc.dealData = StructFind(session.dealData,loc.dealKey)>
				<cfset loc.dealRec = StructFind(session.basket.deals,loc.dealKey)>
				<cfset ArraySort(loc.dealRec.prices,"text","ASC")>	<!--- change to DESC to optimise for customer --->
				<cfset loc.dealRec.retail = 0>
				<cfset loc.dealRec.netTotal = 0>
				<cfset loc.dealRec.dealTotal = 0>
				<cfset loc.dealRec.totalCharge = 0>
				<cfset loc.dealRec.savingGross = 0>
				<cfset loc.dealRec.groupRetail = 0>
				<cfset loc.item.dealQty = 0>
				<cfset loc.dealRec.VAT = {}>
				<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
					<cfset loc.price = ListFirst(loc.priceKey," ")>
					<cfset loc.prodID = ListLast(loc.priceKey," ")>
					<cfset loc.item = StructFind(session.basket.shopItems,loc.prodID)>
					<cfset loc.item.dealTitle = "">
					<cfset loc.item.style = "blue">
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
							<cfset loc.item.dealQty++>
							<cfset loc.item.style = "red">
							<cfswitch expression="#loc.dealData.edDealType#">
								<cfcase value="anyfor">
									<cfset loc.dealRec.dealTotal = loc.item.dealQty * loc.dealData.edAmount>
									<cfset loc.item.dealTitle = "#loc.dealData.edTitle# &pound;#DecimalFormat(loc.dealData.edAmount)#">
								</cfcase>
								<cfcase value="twofor">
									<cfset loc.item.dealQty = int(loc.dealRec.itemCount / 2)>
									<cfset loc.dealRec.remQty = loc.dealRec.itemCount mod 2>
									<cfset loc.dealRec.dealTotal = loc.item.dealQty * loc.dealData.edAmount + (loc.dealRec.remQty * loc.price)>
									<cfset loc.item.dealTitle = "#loc.dealData.edTitle# &pound;#DecimalFormat(loc.dealData.edAmount)#">
								</cfcase>
								<cfcase value="bogof">
									<cfset loc.item.dealQty = int(loc.dealRec.itemCount / 2)>
									<cfset loc.dealRec.remQty = loc.dealRec.itemCount mod 2>
									<cfset loc.dealRec.dealTotal = (loc.item.dealQty * loc.price) + (loc.dealRec.remQty * loc.price)>
									<cfset loc.item.dealTitle = loc.dealData.edTitle>
								</cfcase>
							</cfswitch>
							<cfset loc.dealRec.groupRetail = 0>
						</cfif>
					</cfif>
					<cfset loc.dealRec.totalCharge = loc.dealRec.groupRetail + loc.dealRec.dealTotal>
					<cfset loc.dealRec.savingGross = loc.dealRec.totalCharge - loc.dealRec.retail>
					<cfset loc.dealRec.savingNet = 0>
					<cfset loc.dealRec.savingVAT = 0>
					<cfloop collection="#loc.dealRec.VAT#" item="loc.vatKey">
						<cfset loc.netAmnt = StructFind(loc.dealRec.VAT,loc.vatKey)>
						<cfset loc.prop = loc.netAmnt / loc.dealRec.netTotal>
						<cfset loc.dealRec.savingNet += (loc.dealRec.savingGross * loc.prop) / (1 + (loc.vatKey /100))>
					</cfloop>
					<cfset loc.dealRec.savingVAT += loc.dealRec.savingGross - loc.dealRec.savingNet>
				</cfloop>
				<cfdump var="#loc#" label="loc #loc.dealKey#" expand="yes">			
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
					
				<!---<cfset loc.item.dealQty = 0>--->
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
				</cfif>
			</cfloop>
			<cfset ProcessDeals()>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="CheckDeals" expand="yes" format="html" 
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="CheckDealsXX" access="public" returntype="void" hint="check basket for qualifying deals.">
		<cfset var loc = {}>
		<cfset loc.regMode = (2 * int(session.basket.info.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
		<cfset loc.tranType = -1>
		<cfloop collection="#session.basket.shopItems#" item="loc.key">
			<cfset loc.item = StructFind(session.basket.shopItems,loc.key)>
			<cfset loc.item.dealQty = 0>
			<cfset loc.item.dealTitle = ''>
			<cfset loc.item.dealTotal = 0>
			<cfset loc.item.discount = 0>
			<cfset loc.item.remQty = 0>
			<cfset loc.item.vatRate = 1 + (val(loc.item.vrate) / 100)>
			<cfset loc.item.retail = loc.item.qty * loc.item.unitPrice>
			<cfif loc.item.dealID gt 0>
				<cfset loc.deal = StructFind(session.dealdata,loc.item.dealID)>
				<cfif loc.item.qty gte loc.deal.edQty>
					<cfset loc.item.dealTitle = loc.deal.edTitle>
					<cfset loc.item.dealQty = loc.deal.edQty>
					<cfset loc.item.edAmount = loc.deal.edAmount>
					<cfset loc.item.discountable = false>
					<cfswitch expression="#loc.deal.edDealType#">
						<cfcase value="bogof">
							<cfset loc.item.dealQty = int(loc.item.qty / 2)>
							<cfset loc.item.remQty = loc.item.qty mod 2>
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
				<cfif session.till.info.staff AND loc.item.discountable>	<!--- staff sale and is a discountable item --->
					<cfset loc.item.discount = round(loc.item.retail * 100 * session.till.prefs.discount) / 100>	<!--- item discount in pence --->
					<cfset loc.item.totalGross -= loc.item.discount>
				</cfif>	
			</cfif>
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
		</cfloop>
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
			<cfif loc.rec.qty lte 0>
				<cfset StructDelete(loc.section,args.data.itemID,false)>
				<cfset ArrayDelete(loc.sectionArray,args.data.itemID)>
			<cfelse>
				<cfset loc.rec.retail = loc.rec.qty * loc.rec.unitPrice>
				<cfset loc.rec.totalGross = loc.rec.retail>
		
				<!---<cfset loc.rec.remQty = 0>--->
	
				<cfset loc.rec.dealID = 0>	<!--- clear any current deal --->
				<!---<cfset loc.rec.dealTotal = 0>--->
				<cfif StructKeyExists(session.dealIDs,args.form.prodID)>	<!--- product deals only --->
					<cfset loc.rec.dealID = StructFind(session.dealIDs,args.form.prodID)>
				</cfif>
				
				<cfif loc.rec.dealID eq 0 AND session.till.info.staff AND loc.rec.discountable>	<!--- staff sale and is a discountable item --->
					<cfset loc.rec.discount = round(loc.rec.retail * 100 * session.till.prefs.discount) / 100>	<!--- item discount in pence --->
					<cfset loc.rec.totalGross -= loc.rec.discount>
				</cfif>
				
				<cfset loc.rec.totalNet = loc.rec.totalGross / loc.vatRate>
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
		
		<cfset args.unitPrice = args.cash + args.credit>
		<cfset args.retail = args.qty * args.unitPrice>
		<cfset args.totalGross = args.retail>
		<cfset args.totalNet = args.totalGross / loc.vatrate>
		<cfset args.totalVAT = args.totalGross - args.totalNet>

		<cfset args.retail = args.retail * loc.regMode * loc.tranType>
		<cfset args.totalGross = args.totalGross * loc.regMode * loc.tranType>
		<cfset args.totalNet = args.totalNet * loc.regMode * loc.tranType>
		<cfset args.totalVAT = args.totalVAT * loc.regMode * loc.tranType>
	</cffunction>
	
	<cffunction name="UpdateBasketXX" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.insertItem = false>
		
		<!---Transaction in progress flag--->
		<cfset session.till.isTranOpen = true>

		<cfif StructKeyExists(session.basket.shopItems,args.form.prodID)>
			<cfset loc.rec = StructFind(session.basket.shopItems,args.form.prodID)>
		<cfelse>
			<cfset loc.insertItem = true>
			<cfset loc.rec = {}>
			<cfset loc.rec.prodID = args.form.prodID>
			<cfset loc.rec.prodTitle = args.form.prodTitle>
			<cfset loc.rec.vrate = args.form.vrate>
			<cfset loc.rec.vcode = args.form.vcode>
			<cfset loc.rec.class = args.form.class>
			<cfset loc.rec.type = args.form.itemClass>
			<cfset loc.rec.cashonly = 0>
			<cfset loc.rec.qty = 0>
		</cfif>
		<cfset loc.rec.discountable = StructKeyExists(args.form,"discountable")>
		<cfset loc.rec.cashonly = args.form.cashonly>
		<cfset loc.rec.cash = args.form.cash>
		<cfset loc.rec.credit = args.form.credit>
		<cfset loc.rec.unitPrice = args.form.cash + args.form.credit>	<!--- was above loc.rec.qty--->
		<cfset loc.rec.qty += args.form.qty>		<!--- accumulate qty with any previous value. can be +/- --->
		<cfif loc.rec.qty lte 0>
			<cfset StructDelete(session.basket.shopItems,args.form.prodID,true)>
			<cfset ArrayDelete(session.basket.shop,args.form.prodID)>
			<cfset CheckDeals()>
		<cfelse>
			<cfset loc.rec.remQty = 0>
			<cfif loc.insertItem>	<!--- if item not in struct --->
				<cfset StructInsert(session.basket.shopItems,args.form.prodID,loc.rec)>
				<cfset ArrayAppend(session.basket.shop,args.form.prodID)>
			<cfelse>
				<cfset StructUpdate(session.basket.shopItems,args.form.prodID,loc.rec)>
			</cfif>
	
			<cfset loc.rec.dealID = 0>	<!--- clear any current deal --->
			<cfset loc.rec.dealTotal = 0>
			<cfif StructKeyExists(session.dealIDs,args.form.prodID)>
				<cfset loc.rec.dealID = StructFind(session.dealIDs,args.form.prodID)>
			</cfif>
			<cfset CheckDeals()>
		</cfif>
		
		<cfreturn loc.result>
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
				<cfdump var="#args#" label="AddItem" expand="yes" format="html" 
					output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
				<cfreturn loc.result>
			</cfif>
			<cfif val(args.form.prodID) gt 0>
				<cfset args.form.pubID = 1>
				<cfset args.data.itemID = args.form.prodID>
				<cfset args.data.title = args.form.prodTitle>
				<!---<cfset args.form.itemClass = "SALE">--->
			<cfelseif val(args.form.pubID) gt 0>
				<cfset args.form.prodID = 1>
				<cfset args.data.itemID = args.form.pubID>
				<cfset args.data.title = args.form.pubTitle>
				<!---<cfset args.form.itemClass = "MEDIA">--->	
			<cfelseif Left(args.form.itemClass,5) eq "prod-">	<!--- not used anymore --->
				<cfset args.data.itemID = val(mid(args.form.itemClass,6,10))>
				<cfset args.data.title = args.form.prodTitle>
				<cfset args.form.itemClass = "SALE">
				<cfset args.form.pubID = 1>
			<cfelse>
				<cfset args.data.itemID = 1>
			</cfif>
	
			<cfset loc.regMode = (2 * int(session.basket.info.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
			<!--- <cfset loc.tranType = (2 * int(ListFind("SALE|SALEZ|SALEL|NEWS|SRV|PP",args.form.itemClass,"|") eq 0)) - 1> modes: sales or news = -1 others = 1 --->
			<cfset loc.tranType = -1>
			<!--- sanitise input fields --->
			<cfset args.data.class = "item">
			<cfset args.data.discount = 0>
			<cfset args.data.qty = val(args.form.qty)>
			<cfset args.data.cash = abs(val(args.form.cash)) * args.form.prodSign>
			<cfset args.data.credit = abs(val(args.form.credit)) * args.form.prodSign>
			<cfset args.data.itemClass = args.form.itemClass>
			<!---<cfset args.data.vrate = 1 + (val(args.form.vrate) / 100)>--->
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
							<!---<cfset args.data.gross = args.data.gross * loc.tranType * loc.regMode>--->
							<!---<cfset args.data.cash = args.data.cash * loc.tranType * loc.regMode>---> 		<!--- all form values are +ve numbers --->
							<cfset CalcValues(args.data)>
							<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.paypoint,args.data)></cfif> <!--- add item to payment array --->
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
							<cfset args.data.class = "item">
							<cfset args.data.discount = 0>
							<cfset args.data.account = 2>
							<cfset args.data.vat = 0>
							<cfset args.data.type = args.form.itemClass>
							<!---<cfset args.data.gross = args.data.gross * loc.tranType * loc.regMode>
							<cfset args.data.credit = args.data.credit * loc.tranType * loc.regMode> --->		<!--- all form values are +ve numbers --->
							<cfset CalcValues(args.data)>
							<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.srv,args.data)></cfif> <!--- add item to payment array --->
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
							<!---<cfset args.data.gross = args.data.gross * loc.tranType * loc.regMode>
							<cfset args.data.cash = args.data.cash * loc.tranType * loc.regMode>---> 		<!--- all form values are +ve numbers --->
							<cfset CalcValues(args.data)>
							<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.lottery,args.data)></cfif> <!--- add item to payment array --->
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
							<!---<cfset args.data.gross = args.data.gross * loc.tranType * loc.regMode>
							<cfset args.data.cash = args.data.cash * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
							<cfset args.data.credit = args.data.credit * loc.tranType * loc.regMode>--->	<!--- apply mode & type to set sign correctly --->
							<cfset CalcValues(args.data)>
							<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.news,args.data)></cfif> <!--- add item to product array --->
							<!---<cfset CalcTotals()>--->
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="VCHN">
					<cfif ArrayLen(session.basket.supplier) gt 0> <!--- already have supplier transaction in basket --->
						<cfset session.basket.info.errMsg = "Cannot add a voucher during a supplier transaction.">
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
							<!---<cfset args.data.gross = args.data.gross * loc.tranType * loc.regMode>
							<cfset args.data.cash = args.data.cash * loc.tranType * loc.regMode>---> 		<!--- all form values are +ve numbers --->
							<cfset CalcValues(args.data)>
							<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.vchn,args.data)></cfif> <!--- add item to payment array --->
							<!---<cfset CalcTotals()>--->
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="CPN">
					<cfif ArrayLen(session.basket.supplier) gt 0> <!--- already have supplier transaction in basket --->
						<cfset session.basket.info.errMsg = "Cannot add a coupon during a supplier transaction.">
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
							<!---<cfset args.data.gross = args.data.gross * loc.tranType * loc.regMode>
							<cfset args.data.cash = args.data.cash * loc.tranType * loc.regMode>---> 		<!--- all form values are +ve numbers --->
							<cfset CalcValues(args.data)>
							<cfif args.form.addToBasket><cfset ArrayAppend(session.basket.cpn,args.data)></cfif> <!--- add item to payment array --->
							<!---<cfset CalcTotals()>--->
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
							<!---<cfset args.data.gross = args.data.gross * loc.tranType * loc.regMode>
							<cfset args.data.cash = args.data.cash * loc.tranType * loc.regMode>---> 		<!--- all form values are +ve numbers --->
							
							<cfset session.basket.info.type = "PURCH">	<!--- set receipt title --->
							<cfset session.basket.info.bod = "Supplier">
							<cfset session.basket.total.supplies += args.data.cash>	<!--- accumulate supplier total --->
							<cfset session.basket.header.supplies += args.data.cash>
							<cfset session.basket.header.balance -= args.data.cash>
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
			<cfset session.basket.info.errMsg = "">
			
			<!--- payment methods --->
			<cfswitch expression="#args.form.btnSend#">
				<cfcase value="Cash">
					<cfset args.data.cash = args.data.cash + args.data.credit>
					<cfif args.data.cash neq 0>
						<cfset args.data.credit = 0>	<!--- force empty - only use cash figure --->
						<cfset args.data.class = "pay">
						<cfset args.data.itemClass = "CASHINDW">
						<cfset args.data.title = "Cash Payment">
						<cfset args.data.account = 2>
						<cfset args.data.prodID = 2>
					<cfelseif args.data.cash is 0>
						<cfset args.data.cash = session.basket.total.balance * loc.tranType>
					</cfif>
					<cfset ArrayAppend(session.basket.payments,args.data)>
				</cfcase>
				<cfcase value="Card">
					<cfif args.data.cash + args.data.credit is 0>
						<cfset args.data.credit = session.basket.total.balance * loc.tranType>
					</cfif>
					<cfset args.data.class = "pay">
					<cfset args.data.itemClass = "CARDINDW">
					<cfset args.data.title = "Card Payment">
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

	<cffunction name="AddPaymentxx" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
			<!---Transaction in progress flag--->
			<cfset session.till.isTranOpen = true>
			
			<cfset loc.regMode = (2 * int(session.basket.info.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
			<!--- <cfset loc.tranType = (2 * int(ListFind("SALE|SALEZ|SALEL|NEWS|SRV",args.form.itemClass,"|") eq 0)) - 1> modes: sales or news = -1 others = 1 --->
			<cfset loc.tranType = 1>
			<cfset args.form.cash = abs(val(args.form.cash)) * loc.tranType * loc.regMode> <!--- all form values are +ve numbers --->
			<cfset args.form.credit = abs(val(args.form.credit)) * loc.tranType * loc.regMode>	<!--- apply mode & type to set sign correctly --->
			<cfset session.basket.info.errMsg = "">

			<!--- payment methods --->
			<cfswitch expression="#args.form.btnSend#">
				<cfcase value="Cash">
					<!---<cfif ArrayLen(session.basket.shop) + ArrayLen(session.basket.prizes) + ArrayLen(session.basket.supplier) eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelse>--->
						<cfset args.form.class = "pay">
						<cfset args.form.itemClass = "CASH">
						<cfset args.form.title = "Cash Payment">
						<cfset args.form.account = 2>
						<cfset args.form.prodID = 2>
						<cfset args.form.credit = 0>
						<cfif args.form.cash is 0>
							<cfset args.form.cash = session.basket.header.balance * loc.tranType>
						</cfif>
						<cfif ArrayLen(session.basket.supplier) gt 0>
							<cfset args.form.cash = session.basket.header.balance * loc.tranType>
							<cfset session.basket.header.cashtaken = args.form.cash>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
						<cfelse>
							<cfset session.basket.header.cashtaken += args.form.cash>
							<cfset session.basket.header.balance -= args.form.cash>
						</cfif>
	
						<cfset ArrayAppend(session.basket.payments,args.form)>
						<cfif session.basket.info.mode eq "reg" AND session.basket.header.balance lte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
						<cfelseif session.basket.info.mode eq "rfd" AND session.basket.header.balance gte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
						<cfelse>
							<cfset CalcTotals()>
						</cfif>
					<!---</cfif>--->
				</cfcase>
				<cfcase value="Card">
					<cfset loc.cashBalance = session.basket.header.cashback + session.basket.header.cashTaken + session.basket.header.bCash + 
						session.basket.header.bPrize + session.basket.header.cVoucher + args.form.cash>
					<cfif args.form.cash + args.form.credit is 0>
						<cfset args.form.credit = session.basket.header.balance * loc.tranType>
					</cfif>
						
					<cfif ArrayLen(session.basket.shop) eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.supplier) gt 0>
						<cfset session.basket.info.errMsg = "Cannot accept a card payment during a supplier transaction.">
					<cfelseif session.basket.info.mode eq "reg" AND loc.cashBalance lt 0>
						<cfset session.basket.info.errMsg = "Some items in the basket must be paid by cash or cashback.">
					<cfelseif session.basket.info.mode eq "rfd" AND loc.cashBalance gt 0>
						<cfset session.basket.info.errMsg = "Some items in the basket must be refunded by cash.">
					<cfelseif args.form.credit gt session.basket.header.balance + session.basket.header.bCash>
						<cfset session.basket.info.errMsg = "Card sale amount is too high.">
					<cfelseif args.form.cash neq 0 AND args.form.credit eq 0>
						<cfset session.basket.info.errMsg = "Please enter the sale amount from the Paypoint receipt.">
					<cfelseif session.basket.info.service eq 0 AND abs(args.form.credit) lt session.till.prefs.mincard AND abs(args.form.credit) neq session.till.prefs.service>
						<cfset session.basket.info.errMsg = "Minimum sale amount allowed on card is &pound;#session.till.prefs.mincard#.">
					<cfelse>
						<cfset args.form.class = "pay">
						<cfset args.form.itemClass = "CARD">
						<cfset args.form.title = "Card Payment">
						<cfset args.form.account = 2>
						<cfset session.basket.header.cardsales += args.form.credit>
						<cfset session.basket.header.cashback += args.form.cash>
						<cfset session.basket.header.balance -= (args.form.credit + args.form.cash)>
						<cfset ArrayAppend(session.basket.payments,args.form)>
						<cfif session.basket.info.mode eq "reg" AND session.basket.header.balance lte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
						<cfelseif session.basket.info.mode eq "rfd" AND session.basket.header.balance gte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
						<cfelse>
							<cfset CalcTotals()>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="Cheque">
					<cfif args.form.cash is 0>
						<cfset args.form.cash = session.basket.header.balance * loc.tranType>
					</cfif>
					<cfif ArrayLen(session.basket.supplier) gt 0>
						<cfset session.basket.info.errMsg = "Cannot accept a cheque during a supplier transaction.">
					<cfelseif ArrayLen(session.basket.news) eq 0>
						<cfset session.basket.info.errMsg = "Please put a news account item in the basket before accepting payment.">
					<cfelseif args.form.credit neq 0>
						<cfset session.basket.info.errMsg = "Please enter the cheque amount in the cash field.">
					<cfelseif abs(session.basket.header.bNews) neq abs(args.form.cash)>
						<cfset session.basket.info.errMsg = "Cheque amount must equal the news account balance.">
					<cfelse>
						<cfset args.form.class = "pay">
						<cfset args.form.type = "CHQ">
						<cfset args.form.title = "Cheque Payment">
						<cfset args.form.account = 2>
						<cfset session.basket.header.chqsales += args.form.cash>
						<cfset session.basket.header.balance -= (args.form.credit + args.form.cash)>
						<cfset ArrayAppend(session.basket.payments,args.form)>
						<cfif session.basket.info.mode eq "reg" AND session.basket.header.balance lte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
						<cfelseif session.basket.info.mode eq "rfd" AND session.basket.header.balance gte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
						<cfelse>
							<cfset CalcTotals()>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="Account">
					<cfif ArrayLen(session.basket.shop) eq 0>
						<cfset session.basket.info.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.supplier) gt 0>
						<cfset session.basket.info.errMsg = "Cannot pay on account during a supplier transaction.">
					<cfelseif len(args.form.account) is 0>
						<cfset session.basket.info.errMsg = "Please select an account to assign this transaction.">
					<cfelse>
						<cfset args.form.class = "pay">
						<cfset args.form.cash = session.basket.header.balance * loc.tranType>
						<cfset args.form.credit = 0>
						<cfset args.form.type = "ACC">
						<cfset args.form.title = "Payment on Account">
						<cfset session.basket.header.cAcct += session.basket.header.balance>
						<cfset session.basket.header.balance = 0>
						<cfset session.basket.total.balance = 0>
						<cfset ArrayAppend(session.basket.payments,args.form)>
						<cfset CalcTotals()>
						<cfset CloseTransaction()>
					</cfif>
				</cfcase>
			</cfswitch>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
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
		<cfset var loc = {}>
		<cftry>
			<cfset session.basket.vatAnalysis = {}>
			<cfoutput>
				<table class="eposBasketTable" border="0" width="100%">
					<tr class="ebt_headers">
						<th align="left">Description</th>
						<th align="center">Qty</th>
						<th align="right">Price</th>
						<th align="right">Total</th>
					</tr>
					<cfset loc.basketCount = 0>
					<cfset session.basket.header.balance = 0>
					<cfset session.basket.header.cardsales = 0>
					<cfset session.basket.header.cashback = 0>
					<cfset session.basket.total.balance = 0>
					<cfset session.basket.total.discount = 0>
					<cfloop array="#session.till.catKeys#" index="loc.key">
						<cfset loc.section = StructFind(session.basket,loc.key)>
						<cfset StructUpdate(session.basket.total,loc.key,0)>
						<cfloop array="#loc.section#" index="loc.item">
<!---							<cfif IsStruct(loc.item)>
								<cfset session.basket.total.balance -= loc.item.retail>
								<cfset loc.total = StructFind(session.basket.total,loc.item.type)>
								<cfset StructUpdate(session.basket.total,loc.item.type,loc.total + loc.item.totalGross)>
								<cfset loc.vcode = loc.item.vcode>
								<!---<tr><td colspan="4"><cfdump var="#loc.item#" label="#loc.item.title#" expand="no"></td></tr>--->
								<tr class="basket_item" #StructToDataAttributes(loc.item)#>
									<td align="left">#loc.item.title#</td>
									<td align="center">#loc.item.qty#</td>
									<td align="right">#DecimalFormat(loc.item.unitPrice)#</td>
									<td align="right">#DecimalFormat(-loc.item.retail)#</td>
								
								</tr>
							<cfelse>
								<cfset loc.sectionData = StructFind(session.basket,"#loc.key#Items")>
								<cfset loc.data = StructFind(loc.sectionData,loc.item)>
								<cfset session.basket.total.balance -= loc.data.retail>
								<cfset loc.total = StructFind(session.basket.total,loc.data.type)>
								<cfset StructUpdate(session.basket.total,loc.data.type,loc.total + loc.data.totalGross)>
								<cfset loc.vcode = loc.data.vcode>
								<!---<tr><td colspan="4"><cfdump var="#loc.data#" label="#loc.data.title#" expand="no"></td></tr>--->
								<tr class="basket_item" #StructToDataAttributes(loc.data)#>
									<td align="left">#loc.data.title#</td>
									<td align="center">#loc.data.qty#</td>
									<td align="right">#DecimalFormat(loc.data.unitPrice)#</td>
									<td align="right">#DecimalFormat(-loc.data.retail)#</td>
								</tr>
							</cfif>
--->
							<cfif IsStruct(loc.item)>
								<cfset loc.data = loc.item>
							<cfelse>
								<cfset loc.sectionData = StructFind(session.basket,"#loc.key#Items")>
								<cfset loc.data = StructFind(loc.sectionData,loc.item)>
							</cfif>
							<cfset session.basket.total.balance -= loc.data.retail>
							<cfset loc.total = StructFind(session.basket.total,loc.data.type)>
							<cfset StructUpdate(session.basket.total,loc.data.type,loc.total + loc.data.totalGross)>
							
							<tr class="basket_item" #StructToDataAttributes(loc.data)#>
								<td align="left">#loc.data.title#</td>
								<td align="center">#loc.data.qty#</td>
								<td align="right">#DecimalFormat(loc.data.unitPrice)#</td>
								<td align="right">#DecimalFormat(-loc.data.retail)#</td>
								<td align="center">#loc.data.vcode#</td>
							</tr>

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
						<cfloop collection="#session.basket.deals#" item="loc.dealKey">
							<cfset loc.dealRec = StructFind(session.basket.deals,loc.dealKey)>
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
					
					<tr class="ebt_headers">
						<th align="left">Total</th>
						<th align="center"></th>
						<th align="right"></th>
						<th align="right">#DecimalFormat(session.basket.total.balance)#</th>
					</tr>
					<cfif StructKeyExists(session.basket,"deals")>
						<tr>
							<td colspan="4">&nbsp;</td>
						</tr>
						<tr class="ebt_headers">
							<th align="left">Multibuy Discounts</th>
							<th align="center">Items</th>
							<th></th>
							<th align="right">Saving</th>
						</tr>
						<cfloop collection="#session.basket.deals#" item="loc.key">
							<cfset loc.data = StructFind(session.basket.deals,loc.key)>
							<cfif loc.data.dealQty neq 0>
								<cfset session.basket.total.balance -= loc.data.savingGross>
								<cfset session.basket.total.discount += loc.data.savingGross>
								<tr class="basket_item">
									<td align="left">#loc.data.dealTitle#</td>
									<td align="center">#loc.data.count#</td>
									<td></td>
									<td align="right">#DecimalFormat(-loc.data.savingGross)#</td>
								</tr>
							</cfif>						
						</cfloop>
						<tr>
							<td colspan="4">&nbsp;</td>
						</tr>
						<tr class="ebt_headers">
							<th align="left">Total Due</th>
							<th align="center"></th>
							<th align="right"></th>
							<th align="right">#DecimalFormat(session.basket.total.balance)#</th>
						</tr>
					</cfif>
					<cfset loc.payCount = 0>
					<cfloop list="#session.till.prefs.payList#" delimiters="," index="loc.pay">
						<cfset StructUpdate(session.basket.total,loc.pay,0)>
					</cfloop>
					<cfloop array="#session.basket.payments#" index="loc.item">
						<cfset loc.payCount++>
						<cfif loc.item.itemClass eq "CARDINDW">
							<cfset session.basket.total.cardINDW += (loc.item.cash + loc.item.credit)>
							<cfset session.basket.header.cardsales += loc.item.credit>
							<cfset session.basket.header.cashback += loc.item.cash>
							<cfset session.basket.header.balance -= (loc.item.cash + loc.item.credit)>
							<tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
								<td colspan="3">Card Payment</td><td align="right">#DecimalFormat(-loc.item.credit)#</td>
							</tr>
							<tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
								<td colspan="3">Cashback</td><td align="right">#DecimalFormat(-loc.item.cash)#</td>
							</tr>
						<cfelse>
							<cfset loc.payValue = StructFind(session.basket.total,loc.item.itemClass)>
							<cfset StructUpdate(session.basket.total,loc.item.itemClass,loc.payValue + (loc.item.cash + loc.item.credit))>
							<tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
								<td colspan="3">#loc.item.title#</td><td align="right">#DecimalFormat(-(loc.item.cash + loc.item.credit))#</td>
							</tr>
						</cfif>
						<cfset session.basket.total.balance -= (loc.item.cash + loc.item.credit)>
					</cfloop>
					<tr>
						<td colspan="4">&nbsp;</td>
					</tr>
					<cfif session.basket.total.balance lt 0>
						<cfset session.basket.total.change = session.basket.total.balance>
						<cfset session.basket.total.balance = 0>
						<tr class="ebt_headers">
							<th align="left">Change</th>
							<th align="center"></th>
							<th align="right"></th>
							<th align="right">#DecimalFormat(-session.basket.total.change)#</th>
						</tr>
					<cfelse>
						<tr class="ebt_headers">
							<th align="left">Balance Due</th>
							<th align="center"></th>
							<th align="right"></th>
							<th align="right">#DecimalFormat(session.basket.total.balance)#</th>
						</tr>
					</cfif>
				</table>
			</cfoutput>
			<cfset VATSummary(session.basket.vatAnalysis)>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="" expand="yes" format="html" 
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="ShowBasketXX" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.arrCount = 0>
		<cfset loc.itemCount = 0>
		<cfset loc.discables = 0>
		<cfset loc.total = 0>
		<cfset session.basket.vatAnalysis = {}>

		<cftry>
			<cfoutput>
				<table class="eposBasketTable" border="0" width="100%">
					<tr class="ebt_headers">
						<td align="left">Description</td>
						<td align="right">Qty</td>
						<td align="right">Price</td>
						<td align="right">Total</td>
					</tr>
					<!--- recalculate basket totals --->
					<cfset session.basket.header.aRetail = 0>
					<cfset session.basket.header.aNet = 0>
					<cfset session.basket.header.aVAT = 0>
					<cfset session.basket.header.aDiscDeal = 0>
					<cfset session.basket.header.aDiscStaff = 0>
					
					<cfset session.basket.header.bCash = 0>
					<cfset session.basket.header.bCredit = 0>
					<cfset session.basket.header.bNews = 0>
					<cfset session.basket.header.bPrize = 0>
					<cfset session.basket.header.cVoucher = 0>
					<cfset session.basket.header.cCoupon = 0>
					<cfset session.basket.header.cPaypoint = 0>
					<cfset session.basket.header.cLottery = 0>
					
					<cfset session.basket.header.balance = 0>
					
					<!---<cfset session.basket.total.shop = 0>
					<cfset session.basket.total.ext = 0>
					<cfset session.basket.total.news = 0>--->
					<cfloop array="#session.till.catKeys#" index="loc.cat">
						<cfset StructUpdate(session.basket.total,loc.cat,0)>
					</cfloop>
					<cfloop collection="#session.basket.shopItems#" item="loc.key">
						<cfset loc.arrCount++>
						<cfset loc.item = StructFind(session.basket.shopItems,loc.key)>
						
						<cfset loc.total += (loc.item.retail + loc.item.discount)>
						<cfset loc.itemCount += loc.item.qty>
						<cfset loc.discables += (loc.item.qty * loc.item.discountable)>
						<tr class="basket_item" #StructToDataAttributes(loc.item)#>
							<td align="left">#loc.item.prodTitle#</td>
							<td align="right">#loc.item.qty#</td>
							<td align="right">#DecimalFormat(loc.item.unitPrice)#</td>
							<td align="right">#DecimalFormat(-loc.item.retail)#</td>
						</tr>
						<cfif val(loc.item.dealID) neq 0>
							<cfif val(loc.item.dealQty) neq 0>
								<cfset loc.total += loc.item.dealTotal>
								<tr class="ebt_deal">
									<td>#loc.item.dealTitle#</td>
									<td align="right">#loc.item.dealQty#</td>
									<td></td>
									<td align="right">#DecimalFormat(-loc.item.dealTotal)#</td>
								</tr>
							</cfif>
						</cfif>
						<cfif loc.item.vcode gt 0>
							<cfif NOT StructKeyExists(session.basket.vatAnalysis,loc.item.vcode)>
								<cfset StructInsert(session.basket.vatAnalysis,loc.item.vcode,{
									"vrate"=loc.item.vrate,"net"=loc.item.totalNet,"VAT"=loc.item.totalVat,"gross"=loc.item.totalGross,"items"=1})>
							<cfelse>
								<cfset loc.vatAnalysis = StructFind(session.basket.vatAnalysis,loc.item.vcode)>
								<cfset loc.vatAnalysis.net += loc.item.totalNet>
								<cfset loc.vatAnalysis.vat += loc.item.totalVat>
								<cfset loc.vatAnalysis.gross += loc.item.totalGross>
								<cfset loc.vatAnalysis.items++>
								<cfset StructUpdate(session.basket.vatAnalysis,loc.item.vcode,loc.vatAnalysis)>
							</cfif>
						</cfif>
						
						<!--- new totals --->
						<cfset session.basket.header.aRetail -= loc.item.retail>
						<cfset session.basket.header.aNet += loc.item.totalNet>
						<cfset session.basket.header.aVAT += loc.item.totalVat>
						<cfset session.basket.header.aDiscDeal -= loc.item.dealTotal>
						<cfset session.basket.header.aDiscStaff -= loc.item.discount>
						
						<cfset session.basket.header.bCash += loc.item.cash>
						<cfset session.basket.header.bCredit += loc.item.credit>
						<cfset loc.catValue = StructFind(session.basket.total,loc.item.type)>
						<cfset StructUpdate(session.basket.total,loc.item.type,loc.catValue + loc.item.retail)>
					</cfloop>
					<!---<cfset session.basket.total.shop = loc.total>--->
					<cfloop list="suppliers|media|news|prizes|vouchers|paypoint|coupons" delimiters="|" index="loc.arr">
						<cfset loc.section = StructFind(args,loc.arr)>
						<cfloop array="#loc.section#" index="loc.item">
							<cfset loc.total += (loc.item.cash + loc.item.credit)>
							<cfswitch expression="#loc.arr#">
								<cfcase value="media">
									<cfset session.basket.header.bMedia += (loc.item.cash + loc.item.credit)>
									<cfset session.basket.total.media += (loc.item.cash + loc.item.credit)>
								</cfcase>
								<cfcase value="news">
									<cfset session.basket.header.bNews += (loc.item.cash + loc.item.credit)>
									<cfset session.basket.total.news += (loc.item.cash + loc.item.credit)>
								</cfcase>
								<cfcase value="vouchers">
									<cfset session.basket.header.cVoucher += (loc.item.cash + loc.item.credit)>
								</cfcase>
								<cfcase value="coupons">
									<cfset session.basket.header.cCoupon += (loc.item.cash + loc.item.credit)>
								</cfcase>
								<cfcase value="prizes">
									<cfset session.basket.header.bPrize += (loc.item.cash + loc.item.credit)>
									<cfset session.basket.total.ext += (loc.item.cash + loc.item.credit)>
								</cfcase>
								<cfcase value="paypoint">
									<cfset session.basket.header.cPaypoint += (loc.item.cash + loc.item.credit)>
									<cfset session.basket.total.ext += (loc.item.cash + loc.item.credit)>
								</cfcase>
							</cfswitch>
							<tr>
								<td colspan="3">#loc.item.title#</td><td align="right">#DecimalFormat(-(loc.item.cash + loc.item.credit))#</td>
							</tr>
						</cfloop>
					</cfloop>
					<cfset loc.payCount = 0>
					<cfloop array="#session.basket.payments#" index="loc.item">
						<cfset loc.payCount++>
						<cfset loc.total += (loc.item.cash + loc.item.credit)>
						<tr class="ebt_payment" #StructToDataAttributes(loc.item)# data-arrIndex="#loc.payCount#">
							<td colspan="3">#loc.item.title#</td><td align="right">#DecimalFormat(-(loc.item.cash + loc.item.credit))#</td>
						</tr>
					</cfloop>
					<tr>
						<td colspan="4">&nbsp;</td>
					</tr>
					<cfif session.basket.header.aDiscStaff neq 0>
						<tr class="ebt_discount">
							<td>Staff Discount</td>
							<td align="right">#loc.discables#</td>
							<td></td>
							<td align="right">#DecimalFormat(session.basket.header.aDiscStaff)#</td>
						</tr>
					</cfif>
					<cfset session.basket.header.balance = -loc.total>
					<cfset session.basket.total.balance = -loc.total>
					<!---<tr class="ebt_totals">
						<td>Balance Due</td>
						<td align="right">#loc.itemCount#</td>
						<td></td>
						<td align="right">#DecimalFormat(-loc.total)#</td>
					</tr>--->
				</table>
				<div class="ebt_totals_w">
					<table width="100%" border="0">
						<cfif session.basket.total.balance lte 0>
							<tr class="ebt_totals h_green">
								<td colspan="2">Balance Due To Customer</td>
								<td align="right">&pound;#DecimalFormat(loc.total)#</td>
							</tr>
						<cfelse>
							<tr class="ebt_totals h_red">
								<td>Balance Due From Customer</td>
								<cfif loc.itemCount lte 0>
									<td align="right">0 Items</td>
								<cfelseif loc.itemCount gt 1>
									<td align="right">#loc.itemCount# Items</td>
								<cfelse>
									<td align="right">#loc.itemCount# Item</td>
								</cfif>
								<td></td>
								<td align="right">&pound;#DecimalFormat(-loc.total)#</td>
							</tr>
						</cfif>
					</table>
				</div>
			</cfoutput>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="" expand="yes" format="html" 
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>
	
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
	
	<cffunction name="CloseTransaction" access="public" returntype="void">
		<cfset var loc = {}>
		
		<cfloop collection="#session.basket.header#" item="loc.key">
			<cfset loc.basketvalue = StructFind(session.basket.header,loc.key)>
			<cfif StructKeyExists(session.till.header,loc.key)>
				<cfset loc.tillvalue = StructFind(session.till.header,loc.key)>
				<cfset StructUpdate(session.till.header,loc.key,loc.tillvalue + loc.basketvalue)>
			<cfelse>
				<cfset StructInsert(session.till.header,loc.key,loc.basketvalue)>
			</cfif>
		</cfloop>
		<cfloop collection="#session.basket.total#" item="loc.key">
			<cfset loc.basketvalue = StructFind(session.basket.total,loc.key)>
			<cfif StructKeyExists(session.till.total,loc.key)>
				<cfset loc.tillvalue = StructFind(session.till.total,loc.key)>
				<cfset StructUpdate(session.till.total,loc.key,loc.tillvalue + loc.basketvalue)>
			<cfelse>
				<cfset StructInsert(session.till.total,loc.key,loc.basketvalue)>
			</cfif>
		</cfloop>
		<!---Transaction in progress flag--->
		<cfset session.till.isTranOpen = false>
		<cfset session.till.prevtran = session.basket>
		<cfset WriteTransaction(session.basket)>
		<cfset SaveTillTotals()>
		<cfset ClearBasket()>
	</cffunction>
	
	<cffunction name="WriteTransaction" access="public" returntype="struct">
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
					122,	<!--- TODO provide user ID --->
					#args.header.bCash + args.header.bCredit#,
					#args.header.aVat#,
					'#args.mode#',
					'#args.type#'
				)
			</cfquery>
			<cfset loc.ID = loc.QInsertHeaderResult.generatedkey>
			<cfset session.basket.tranID = loc.ID>
			<cfset loc.discTotal = 0>
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
					<!---<cfset loc.discTotal += loc.item.totalDisc>--->
				</cfloop>
			</cfloop>
<!---
			<cfif loc.discTotal neq 0>
				<cfset loc.result.str = "#loc.result.str#,(#loc.ID#,'#loc.item.class#','DISC','credit',#loc.item.prodID#,1,#loc.discTotal#,0)">
				<cfset loc.result.str = "#loc.result.str#,(#loc.ID#,'#loc.item.class#','STAFF','credit',#loc.item.prodID#,1,#-loc.discTotal#,0)">
			</cfif>
--->
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
					<cfloop array="#args.products#" index="loc.prod">
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
<!---				SELECT accID,accName 
				FROM tblAccount
				WHERE accGroup =20
				AND accType =  'sales';
--->
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
				<!---<cfset loc.item="#loc.item#,#ediParent#">
				<cfset StructUpdate(session.dealIDs,ediProduct,loc.item)>--->
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
				<cfelse>
					<cfset session.till.prefs.payList = ListAppend(session.till.prefs.payList,epcKey,",")>
				</cfif>
				<cfif NOT StructKeyExists(session.basket.total,epcKey)>
					<cfset StructInsert(session.basket.total,epcKey,0)>
				</cfif>
				<cfif NOT StructKeyExists(session.basket,epcKey)>
					<cfset StructInsert(session.basket,epcKey,[])>
				</cfif>
			</cfloop>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
				output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>
</cfcomponent>