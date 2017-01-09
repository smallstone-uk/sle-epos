<cfcomponent displayname="EPOS" hint="version 12. EPOS Till Functions">

	<cffunction name="GetDataSource" access="public" returntype="string">
		<cfreturn application.site.datasource1>
	</cffunction>
	
	<cffunction name="ZTill" access="public" returntype="void" hint="initialise till at start of day.">
		<cfargument name="loadDate" type="date" required="yes">
		<cfset StructDelete(session,"till",false)>
		<cfset session.till = {}>
		
		<!---Transaction in progress flag--->
		<cfset session.till.isTranOpen = true>
		
		<cfset session.till.header = {}>
		<cfset session.till.total = {}>
		<cfset session.till.prevtran = {}>
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
		<cfset ClearBasket()>
	</cffunction>
	
	<cffunction name="ClearBasket" access="public" returntype="void" hint="clear current transaction without affecting till totals.">
		<cfset StructDelete(session,"basket",false)>
		<cfset session.basket = {}>
		<cfset session.basket.mode = "reg">
		<cfset session.basket.type = "SALE">
		<cfset session.basket.bod = "Customer">
		<cfset session.basket.errMsg = "">
        <cfset session.basket.prodKeys = {}>
        <cfset session.basket.deals = {}>
		<cfset session.basket.products = []>
		<cfset session.basket.media = []>
		<cfset session.basket.suppliers = []>
		<cfset session.basket.payments = []>
		<cfset session.basket.prizes = []>
		<cfset session.basket.vouchers = []>
		<cfset session.basket.coupons = []>
		<cfset session.basket.paypoint = []>
		<cfset session.basket.news = []>
		<cfset session.basket.received = 0>	<!--- not required ? --->
		<cfset session.basket.service = 0>
		<cfset session.basket.staff = false>
		<cfset session.basket.vatAnalysis = {}>
		
		<cfset session.basket.header = {}>
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
		
		<cfset session.basket.total = {}>
		<cfset session.basket.total.cashINDW = 0>
		<cfset session.basket.total.cardINDW = 0>
		<cfset session.basket.total.chqINDW = 0>
		<cfset session.basket.total.accINDW = 0>
		<cfset session.basket.total.vchINDW = 0>
		<cfset session.basket.total.coupINDW = 0>
		<cfset session.basket.total.shop = 0>
		<cfset session.basket.total.ext = 0>
		<cfset session.basket.total.news = 0>
		<cfset session.basket.total.media = 0>
		<cfset session.basket.total.supplies = 0>
		<cfset session.basket.total.balance = 0>
	</cffunction>
	
	<cffunction name="CalcTotals" access="public" returntype="void" hint="calculate till totals.">
		<cfset session.basket.total.cashINDW = session.basket.header.cashtaken + session.basket.header.change>
		<cfset session.basket.total.cardINDW = session.basket.header.cardsales + session.basket.header.cashback>
		<cfset session.basket.total.chqINDW = session.basket.header.chqsales>
		<cfset session.basket.total.accINDW = session.basket.header.cAcct>
		
		<cfset session.basket.total.vchINDW = session.basket.header.cVoucher>
		<cfset session.basket.total.coupINDW = session.basket.header.cCoupon>
	</cffunction>

	<cffunction name="ProcessDeals" access="public" returntype="void">
		<cfset var loc = {}>
		
		<cftry>
			<cfloop collection="#session.basket.deals#" item="loc.dealKey">
				<cfset loc.dealData = StructFind(session.dealData,loc.dealKey)>
				<cfset loc.dealRec = StructFind(session.basket.deals,loc.dealKey)>
				<cfset ArraySort(loc.dealRec.prices,"text","ASC")>	<!--- change to DESC to optimise for customer --->
				<cfloop array="#loc.dealRec.prices#" index="loc.priceKey">
					<cfset loc.dealRec.retail = 0>
					<cfset loc.dealRec.netTotal = 0>
					<cfset loc.dealRec.dealTotal = 0>
					<cfset loc.dealRec.totalCharge = 0>
					<cfset loc.dealRec.savingGross = 0>
					<cfset loc.dealRec.groupRetail = 0>
					<cfset loc.item.dealQty = 0>
					<cfset loc.dealRec.VAT = {}>
					<cfset loc.price = ListFirst(loc.priceKey," ")>
					<cfset loc.prodID = ListLast(loc.priceKey," ")>
					<cfset loc.item = StructFind(session.basket.prodKeys,loc.prodID)>
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
						<cfif loc.dealRec.count MOD loc.dealData.edQty eq 0>
							<cfset loc.item.dealQty++>
							<cfset loc.item.style = "red">
							<cfswitch expression="#loc.dealData.edDealType#">
								<cfcase value="anyfor">
									<cfset loc.dealRec.dealTotal = loc.item.dealQty * loc.dealData.edAmount>
									<cfset loc.item.dealTitle = "#loc.dealData.edTitle# &pound;#DecimalFormat(loc.dealData.edAmount)#">
								</cfcase>
								<cfcase value="twofor">
									<cfset loc.item.dealQty = int(loc.dealRec.count / 2)>
									<cfset loc.dealRec.remQty = loc.dealRec.count mod 2>
									<cfset loc.dealRec.dealTotal = loc.item.dealQty * loc.dealData.edAmount + (loc.dealRec.remQty * loc.price)>
									<cfset loc.item.dealTitle = "#loc.dealData.edTitle# &pound;#DecimalFormat(loc.dealData.edAmount)#">
								</cfcase>
								<cfcase value="bogof">
									<cfset loc.item.dealQty = int(loc.dealRec.count / 2)>
									<cfset loc.dealRec.remQty = loc.dealRec.count mod 2>
									<cfset loc.dealRec.dealTotal = (loc.item.dealQty * loc.price) + (loc.dealRec.remQty * loc.price)>
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
				<cfdump var="#loc#" label="loc #loc.dealKey#" expand="yes">			
			</cfloop>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="CheckDeals" access="public" returntype="void" hint="check basket for qualifying deals.">
		<cfset var loc = {}>
		<cftry>
			<cfset session.basket.deals = {}>
			<cfset loc.regMode = (2 * int(session.basket.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
			<cfloop collection="#session.basket.prodKeys#" item="loc.key">
				<cfset loc.item = StructFind(session.basket.prodKeys,loc.key)>
				<cfset loc.vatRate = 1 + (val(loc.item.vrate) / 100)>
				<cfset loc.tranType = (2 * int(ListFind("SALE|SALEZ|SALEL|NEWS|SRV|PP",loc.item.type,"|") eq 0)) - 1> <!--- modes: sales or news = -1 others = 1 --->
				<cfset loc.item.retail = loc.item.qty * loc.item.unitPrice>
					<cfset loc.item.totalNet = loc.item.retail / loc.vatRate>
					<cfset loc.item.totalVAT = loc.item.retail - loc.item.totalNet>
					<cfset loc.item.discount = 0>
					
					<cfset loc.item.retail = loc.item.retail * loc.regMode * loc.tranType>
					<!---<cfset loc.item.totalGross = loc.item.totalGross * loc.regMode * loc.tranType>--->
					<cfset loc.item.totalNet = loc.item.totalNet * loc.regMode * loc.tranType>
					<cfset loc.item.totalVAT = loc.item.totalVAT * loc.regMode * loc.tranType>
					<cfif loc.item.cashOnly>
						<cfset loc.item.cash = loc.item.retail>
					<cfelse>
						<cfset loc.item.credit = loc.item.retail>
					</cfif>
				<cfset loc.item.dealQty = 0>
				<cfif loc.item.dealID gt 0>
					<cfset loc.deal = StructFind(session.dealdata,loc.item.dealID)>
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

	<cffunction name="UpdateBasket" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.insertItem = false>
		
		<!---Transaction in progress flag--->
		<cfset session.till.isTranOpen = true>

		<cfif StructKeyExists(session.basket.prodKeys,args.form.prodID)>
			<cfset loc.rec = StructFind(session.basket.prodKeys,args.form.prodID)>
		<cfelse>
			<cfset loc.insertItem = true>
			<cfset loc.rec = {}>
			<cfset loc.rec.prodID = args.form.prodID>
			<cfset loc.rec.prodTitle = args.form.prodTitle>
			<cfset loc.rec.vrate = args.form.vrate>
			<cfset loc.rec.vcode = args.form.vcode>
			<cfset loc.rec.class = args.form.class>
			<cfset loc.rec.type = args.form.type>
			<cfset loc.rec.cashonly = 0>
			<cfset loc.rec.qty = 0>
		</cfif>
		<cfset loc.rec.discountable = StructKeyExists(args.form,"discountable")>
		<cfset loc.rec.cashonly = args.form.cashonly>
		<cfset loc.rec.cash = args.form.cash>
		<cfset loc.rec.credit = args.form.credit>
		<cfset loc.rec.unitPrice = args.form.cash + args.form.credit>
		<cfset loc.rec.qty += args.form.qty>		<!--- accumulate qty with any previous value. can be +/- --->
		<cfif loc.rec.qty lte 0>
			<cfset StructDelete(session.basket.prodKeys,args.form.prodID,true)>
			<cfset ArrayDelete(session.basket.products,args.form.prodID)>
			<cfset CheckDeals()>
		<cfelse>
			<cfset loc.rec.remQty = 0>
			<cfif loc.insertItem>	<!--- if item not in struct --->
				<cfset StructInsert(session.basket.prodKeys,args.form.prodID,loc.rec)>
				<cfset ArrayAppend(session.basket.products,args.form.prodID)>
			<cfelse>
				<cfset StructUpdate(session.basket.prodKeys,args.form.prodID,loc.rec)>
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
		
		<!---Transaction in progress flag--->
		<cfset session.till.isTranOpen = true>
		
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.result.err = "">
		
		<cfif args.form.type eq "SRV"><cfset session.basket.service = args.form.credit></cfif>	<!--- remember if service charge added --->

		<cfif val(args.form.pubID) gt 0>
			<cfset args.form.prodID = 1>
			<cfset args.form.type = "MEDIA">		
		<cfelseif val(args.form.prodID) gt 0>
			<cfset args.form.type = "SALE">		
		<cfelseif Left(args.form.type,5) eq "prod-">
			<cfset args.form.prodID = val(mid(args.form.type,6,10))>
			<cfset args.form.type = "SALE">
			<cfset args.form.pubID = 1>
		<cfelse>
			<cfset args.form.prodID = 1>
		</cfif>

		<cfset loc.regMode = (2 * int(session.basket.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
		<cfset loc.tranType = (2 * int(ListFind("SALE|SALEZ|SALEL|NEWS|SRV|PP",args.form.type,"|") eq 0)) - 1> <!--- modes: sales or news = -1 others = 1 --->

		<!--- sanitise input fields --->
		<cfset args.form.class = "item">
		<cfset args.form.discount = 0>
		<cfset args.form.qty = val(args.form.qty)>
		<cfset args.form.cash = abs(val(args.form.cash))>
		<cfset args.form.credit = abs(val(args.form.credit))>
		<!---<cfset loc.vrate = 1 + (val(args.form.vrate) / 100)>--->
		<cfset args.form.vcode = StructFind(session.vat,DecimalFormat(args.form.vrate))>
		<cfset session.basket.errMsg = "">

        <cfswitch expression="#args.form.type#">
            <cfcase value="SALE|SALEL|SALEZ|SRV|MEDIA" delimiters="|">
                <cfif ArrayLen(session.basket.suppliers) gt 0>
                    <cfset session.basket.errMsg = "Cannot start a sales transaction during a supplier transaction.">
                <cfelse>
                    <cfif args.form.credit + args.form.cash neq 0>
						<cfif StructKeyExists(args.form,"sign")>
							<cfset args.form.cash = args.form.cash * args.form.sign>
							<cfset args.form.credit = args.form.credit * args.form.sign>
						</cfif>
						<cfdump var="#args#" label="AddItem" expand="yes">
						<!---<cfset UpdateBasket(args)>--->
						<cfset CalcTotals()>
                    <cfelse>
                        <cfset session.basket.errMsg = "No value was passed.">
                    </cfif>
                </cfif>
            </cfcase>			
<!---
            <cfcase value="MEDIA">
                <cfif ArrayLen(session.basket.suppliers) gt 0> <!--- already have supplier transaction in basket --->
                    <cfset session.basket.errMsg = "Cannot add a media item during a supplier transaction.">
                <cfelse>
                    <cfif args.form.credit + args.form.cash neq 0>
						<cfset loc.sign = -1>
                        <cfset args.form.class = "item">
                        <cfset args.form.account = 2>
                        <cfset args.form.title = args.form.pubTitle>
                        <cfset args.form.gross = args.form.credit + args.form.cash>	<!--- calc gross transaction value --->
                        <cfset args.form.vat = args.form.vrate>
                        <cfset args.form.discount = 0>
                        <cfset args.form.gross = args.form.gross * loc.sign * loc.tranType * loc.regMode>
                        <cfset args.form.cash = args.form.cash * loc.sign * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
						<cfset args.form.credit = args.form.credit * loc.sign * loc.tranType * loc.regMode>
                        <cfif args.form.addToBasket><cfset ArrayAppend(session.basket.media,args.form)></cfif> <!--- add item to payment array --->
                        <cfset CalcTotals()>
                    </cfif>
				</cfif>
            </cfcase>			
--->
            <cfcase value="PP">
                <cfif ArrayLen(session.basket.suppliers) gt 0> <!--- already have supplier transaction in basket --->
                    <cfset session.basket.errMsg = "Cannot add a paypoint item during a supplier transaction.">
                <cfelse>
                    <cfif args.form.cash neq 0>
                        <cfset args.form.class = "item">
                        <cfset args.form.account = 2>
                        <cfset args.form.title = "PayPoint">
                        <cfset args.form.credit = 0>	<!--- force empty - only use cash figure --->
                        <cfset args.form.gross = args.form.cash>	<!--- calc gross transaction value --->
                        <cfset args.form.vat = 0>
                        <cfset args.form.discount = 0>
                        <cfset args.form.gross = args.form.gross * loc.tranType * loc.regMode>
                        <cfset args.form.cash = args.form.cash * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
                        <cfif args.form.addToBasket><cfset ArrayAppend(session.basket.paypoint,args.form)></cfif> <!--- add item to payment array --->
                        <cfset CalcTotals()>
                    </cfif>
				</cfif>
            </cfcase>
            <cfcase value="PRIZE">
                <cfif ArrayLen(session.basket.suppliers) gt 0> <!--- already have supplier transaction in basket --->
                    <cfset session.basket.errMsg = "Cannot pay a prize during a supplier transaction.">
                <cfelse>
                    <cfif args.form.cash neq 0>
                        <cfset args.form.class = "item">
                        <cfset args.form.account = 2>
                        <cfset args.form.title = "Prize">
                        <cfset args.form.credit = 0>	<!--- force empty - only use cash figure --->
                        <cfset args.form.gross = args.form.cash>	<!--- calc gross transaction value --->
                        <cfset args.form.vat = 0>
                        <cfset args.form.discount = 0>
                        <cfset args.form.gross = args.form.gross * loc.tranType * loc.regMode>
                        <cfset args.form.cash = args.form.cash * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
                        <cfif args.form.addToBasket><cfset ArrayAppend(session.basket.prizes,args.form)></cfif> <!--- add item to payment array --->
                        <cfset CalcTotals()>
                    </cfif>
                </cfif>
            </cfcase>
            <cfcase value="VCHN">
                <cfif ArrayLen(session.basket.suppliers) gt 0> <!--- already have supplier transaction in basket --->
                    <cfset session.basket.errMsg = "Cannot add a voucher during a supplier transaction.">
                <cfelse>
                    <cfif args.form.cash neq 0>
                        <cfset args.form.class = "item">
                        <cfset args.form.account = 2>
                        <cfset args.form.title = "Voucher">
                        <cfset args.form.credit = 0>	<!--- force empty - only use cash figure --->
                        <cfset args.form.gross = args.form.cash>	<!--- calc gross transaction value --->
                        <cfset args.form.vat = 0>
                        <cfset args.form.discount = 0>
                        <cfset args.form.gross = args.form.gross * loc.tranType * loc.regMode>
                        <cfset args.form.cash = args.form.cash * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
                        <cfif args.form.addToBasket><cfset ArrayAppend(session.basket.vouchers,args.form)></cfif> <!--- add item to payment array --->
                        <cfset CalcTotals()>
                    </cfif>
                </cfif>
            </cfcase>
            <cfcase value="CPN">
                <cfif ArrayLen(session.basket.suppliers) gt 0> <!--- already have supplier transaction in basket --->
                    <cfset session.basket.errMsg = "Cannot add a coupon during a supplier transaction.">
                <cfelse>
                    <cfif args.form.cash neq 0>
                        <cfset args.form.class = "item">
                        <cfset args.form.account = 2>
                        <cfset args.form.title = "Coupon">
                        <cfset args.form.credit = 0>	<!--- force empty - only use cash figure --->
                        <cfset args.form.gross = args.form.cash>	<!--- calc gross transaction value --->
                        <cfset args.form.vat = 0>
                        <cfset args.form.discount = 0>
                        <cfset args.form.gross = args.form.gross * loc.tranType * loc.regMode>
                        <cfset args.form.cash = args.form.cash * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
                        <cfif args.form.addToBasket><cfset ArrayAppend(session.basket.coupons,args.form)></cfif> <!--- add item to payment array --->
                        <cfset CalcTotals()>
                    </cfif>
                </cfif>
            </cfcase>
            <cfcase value="NEWS">
                <cfif ArrayLen(session.basket.suppliers) gt 0> <!--- already have supplier transaction in basket --->
                    <cfset session.basket.errMsg = "Cannot pay a news account during a supplier transaction.">
                <cfelse>
                    <cfif args.form.credit + args.form.cash neq 0>
                        <cfset args.form.class = "item">
                        <cfset args.form.account = 2>
                        <cfset args.form.title = "News A/c">
                        <cfset args.form.gross = args.form.credit + args.form.cash>	<!--- calc gross transaction value --->
                        <cfset args.form.vat = 0>
                        <cfset args.form.discount = 0>
                        <cfset args.form.gross = args.form.gross * loc.tranType * loc.regMode>
                        <cfset args.form.cash = args.form.cash * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
                        <cfset args.form.credit = args.form.credit * loc.tranType * loc.regMode>	<!--- apply mode & type to set sign correctly --->
                        <cfif args.form.addToBasket><cfset ArrayAppend(session.basket.news,args.form)></cfif> <!--- add item to product array --->
                        <cfset CalcTotals()>
                    </cfif>
                </cfif>
            </cfcase>
            <cfcase value="SUPP">
                <cfif ArrayLen(session.basket.products) gt 0> <!--- already have sales transaction in basket --->
                    <cfset session.basket.errMsg = "Cannot pay supplier during a sales transaction.">
                <cfelse>
                    <cfif args.form.credit + args.form.cash neq 0>
                        <cfset args.form.class = "item">
                        <cfset args.form.account = 2>
                        <cfset args.form.title = "Purchase">
                        <cfset args.form.gross = args.form.credit + args.form.cash>	<!--- calc gross transaction value --->
                        <cfset args.form.vat = 0>
                        <cfset args.form.discount = 0>
                        <cfset args.form.gross = args.form.gross * loc.tranType * loc.regMode>
                        <cfset args.form.cash = args.form.cash * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
                        <cfset args.form.credit = args.form.credit * loc.tranType * loc.regMode>	<!--- apply mode & type to set sign correctly --->
                        
                        <cfset session.basket.type = "PURCH">	<!--- set receipt title --->
                        <cfset session.basket.bod = "Supplier">
                        <cfset session.basket.total.supplies += args.form.credit + args.form.cash>	<!--- accumulate supplier total --->
                        <cfset session.basket.header.supplies += args.form.credit + args.form.cash>
                        <cfset session.basket.header.balance -= (args.form.credit + args.form.cash)>
                        <cfif args.form.addToBasket><cfset ArrayAppend(session.basket.suppliers,args.form)></cfif>
                        <cfset CalcTotals()>
                    </cfif>
                </cfif>
            </cfcase>
        </cfswitch>
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
			<!---Transaction in progress flag--->
			<cfset session.till.isTranOpen = true>
			
			<cfset loc.regMode = (2 * int(session.basket.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
			<cfset loc.tranType = (2 * int(ListFind("SALE|SALEZ|SALEL|NEWS|SRV",args.form.type,"|") eq 0)) - 1> <!--- modes: sales or news = -1 others = 1 --->
			<cfset args.form.cash = abs(val(args.form.cash)) * loc.tranType * loc.regMode> <!--- all form values are +ve numbers --->
			<cfset args.form.credit = abs(val(args.form.credit)) * loc.tranType * loc.regMode>	<!--- apply mode & type to set sign correctly --->
			<cfset session.basket.errMsg = "">

			<!--- payment methods --->
			<cfswitch expression="#args.form.btnSend#">
				<cfcase value="Cash">
					<cfif ArrayLen(session.basket.products) + ArrayLen(session.basket.prizes) + ArrayLen(session.basket.suppliers) eq 0>
						<cfset session.basket.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelse>
						<cfset args.form.class = "pay">
						<cfset args.form.type = "CASH">
						<cfset args.form.title = "Cash Payment">
						<cfset args.form.account = 2>
						<cfset args.form.prodID = 2>
						<cfset args.form.credit = 0>
						<cfif args.form.cash is 0>
							<cfset args.form.cash = session.basket.header.balance * loc.tranType>
						</cfif>
						<cfif ArrayLen(session.basket.suppliers) gt 0>
							<cfset args.form.cash = session.basket.header.balance * loc.tranType>
							<cfset session.basket.header.cashtaken = args.form.cash>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
						<cfelse>
							<cfset session.basket.header.cashtaken += args.form.cash>
							<cfset session.basket.header.balance -= args.form.cash>
						</cfif>
	
						<cfset ArrayAppend(session.basket.payments,args.form)>
						<cfif session.basket.mode eq "reg" AND session.basket.header.balance lte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
						<cfelseif session.basket.mode eq "rfd" AND session.basket.header.balance gte 0>
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
				<cfcase value="Card">
					<cfset loc.cashBalance = session.basket.header.cashback + session.basket.header.cashTaken + session.basket.header.bCash + 
						session.basket.header.bPrize + session.basket.header.cVoucher + args.form.cash>
					<cfif args.form.cash + args.form.credit is 0>
						<cfset args.form.credit = session.basket.header.balance * loc.tranType>
					</cfif>
						
					<cfif ArrayLen(session.basket.products) eq 0>
						<cfset session.basket.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.suppliers) gt 0>
						<cfset session.basket.errMsg = "Cannot accept a card payment during a supplier transaction.">
					<cfelseif session.basket.mode eq "reg" AND loc.cashBalance lt 0>
						<cfset session.basket.errMsg = "Some items in the basket must be paid by cash or cashback.">
					<cfelseif session.basket.mode eq "rfd" AND loc.cashBalance gt 0>
						<cfset session.basket.errMsg = "Some items in the basket must be refunded by cash.">
					<cfelseif args.form.credit gt session.basket.header.balance + session.basket.header.bCash>
						<cfset session.basket.errMsg = "Card sale amount is too high.">
					<cfelseif args.form.cash neq 0 AND args.form.credit eq 0>
						<cfset session.basket.errMsg = "Please enter the sale amount from the Paypoint receipt.">
					<cfelseif session.basket.service eq 0 AND abs(args.form.credit) lt session.till.prefs.mincard AND abs(args.form.credit) neq session.till.prefs.service>
						<cfset session.basket.errMsg = "Minimum sale amount allowed on card is &pound;#session.till.prefs.mincard#.">
					<cfelse>
						<cfset args.form.class = "pay">
						<cfset args.form.type = "CARD">
						<cfset args.form.title = "Card Payment">
						<cfset args.form.account = 2>
						<cfset session.basket.header.cardsales += args.form.credit>
						<cfset session.basket.header.cashback += args.form.cash>
						<cfset session.basket.header.balance -= (args.form.credit + args.form.cash)>
						<cfset ArrayAppend(session.basket.payments,args.form)>
						<cfif session.basket.mode eq "reg" AND session.basket.header.balance lte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
						<cfelseif session.basket.mode eq "rfd" AND session.basket.header.balance gte 0>
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
					<cfif ArrayLen(session.basket.suppliers) gt 0>
						<cfset session.basket.errMsg = "Cannot accept a cheque during a supplier transaction.">
					<cfelseif ArrayLen(session.basket.news) eq 0>
						<cfset session.basket.errMsg = "Please put a news account item in the basket before accepting payment.">
					<cfelseif args.form.credit neq 0>
						<cfset session.basket.errMsg = "Please enter the cheque amount in the cash field.">
					<cfelseif abs(session.basket.header.bNews) neq abs(args.form.cash)>
						<cfset session.basket.errMsg = "Cheque amount must equal the news account balance.">
					<cfelse>
						<cfset args.form.class = "pay">
						<cfset args.form.type = "CHQ">
						<cfset args.form.title = "Cheque Payment">
						<cfset args.form.account = 2>
						<cfset session.basket.header.chqsales += args.form.cash>
						<cfset session.basket.header.balance -= (args.form.credit + args.form.cash)>
						<cfset ArrayAppend(session.basket.payments,args.form)>
						<cfif session.basket.mode eq "reg" AND session.basket.header.balance lte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
							<cfset session.basket.total.balance = 0>
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
						<cfelseif session.basket.mode eq "rfd" AND session.basket.header.balance gte 0>
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
					<cfif ArrayLen(session.basket.products) eq 0>
						<cfset session.basket.errMsg = "Please put an item in the basket before accepting payment.">
					<cfelseif ArrayLen(session.basket.suppliers) gt 0>
						<cfset session.basket.errMsg = "Cannot pay on account during a supplier transaction.">
					<cfelseif len(args.form.account) is 0>
						<cfset session.basket.errMsg = "Please select an account to assign this transaction.">
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
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cftry>
			<cfset loc.result = {}>
			<cfset loc.arrCount = 0>
			<cfset loc.itemCount = 0>
			<cfset loc.discables = 0>
			<cfset loc.total = 0>
			<cfset session.basket.vatAnalysis = {}>
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
					
					<cfset session.basket.total.shop = 0>
					<cfset session.basket.total.ext = 0>
					<cfset session.basket.total.news = 0>
					
					<cfloop collection="#session.basket.prodKeys#" item="loc.key">
						<cfset loc.arrCount++>
						<cfset loc.item = StructFind(session.basket.prodKeys,loc.key)>
						
						<cfset loc.total += (loc.item.retail)><!--- + loc.item.discount--->
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
									"vrate"=loc.item.vrate,"net"=loc.item.totalNet,"VAT"=loc.item.totalVat,"items"=1})><!---,"gross"=loc.item.totalGross--->
							<cfelse>
								<cfset loc.vatAnalysis = StructFind(session.basket.vatAnalysis,loc.item.vcode)>
								<cfset loc.vatAnalysis.net += loc.item.totalNet>
								<cfset loc.vatAnalysis.vat += loc.item.totalVat>
								<!---<cfset loc.vatAnalysis.gross += loc.item.totalGross>--->
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
					</cfloop>
					<cfset session.basket.total.shop = loc.total>
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
			<cfdump var="#cfcatch#" label="ShowBasket" expand="yes" format="html" 
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
				<cfset loc.item = StructFind(args.prodKeys,loc.prod)>
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
			<cfdump var="#cfcatch#" label="WriteTransaction" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
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
							<cfset loc.item = StructFind(args.prodKeys,loc.prod)>
							<cfset loc.netTotal += loc.item.totalNet>
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
								<td colspan="2" width="220">Balance Due from #args.bod#</td><td align="right">#DecimalFormat(args.header.balance)#</td><td></td>
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
					<cfif session.basket.mode eq "rfd">
						Refund
						#Chr(10)##Chr(10)#
					</cfif>
					#alignLeftRight("Served By: #session.user.firstName# #Left(session.user.lastName, 1)#", "Ref: #args.tranID#")#
					#alignLeftRight("#loc.dateNow#", "#loc.timeNow#")#
					#Chr(10)##Chr(10)#
					#alignRightLeftRight("QTY", "DESCRIPTION", "AMOUNT")#
					 
					<cfloop array="#args.products#" index="loc.prod">
						<cfset loc.item = StructFind(args.prodKeys,loc.prod)>
						<cfset loc.netTotal += loc.item.totalNet>
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
						#alignLeftRight("Balance Due from #args.bod#", "#Chr(163)##DecimalFormat(args.header.balance)#")#
					</cfif>
				</cfoutput>
			</cfsavecontent>
			
			<cfcatch type="any">
				<p>An error occurred printing the receipt.</p>
				<cfdump var="#cfcatch#" label="PrintASCIIReceipt" expand="yes" format="html" 
					output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
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
						<cfset loc.item = StructFind(args.prodKeys,loc.prod)>
						<cfset loc.netTotal += loc.item.totalNet>
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
								<td align="left" colspan="2">Balance Due from #args.bod#</td>
								<td align="right">#DecimalFormat(args.header.balance)#</td>
							</tr>
						</cfif>
					</table>
				</div>
			</cfoutput>
		<cfcatch type="any">
			<p>An error occurred showing the receipt.</p>
			<cfdump var="#cfcatch#" label="ShowBasketReceipt" expand="yes" format="html" 
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
<!---				SELECT accID,accName 
				FROM tblAccount
				WHERE accGroup =20
				AND accType =  'sales';
--->
				SELECT eaID,eaTitle
				FROM tblEPOS_Account
			</cfquery>
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
			<cfquery name="loc.QTotals" datasource="#GetDataSource()#" result="loc.QQueryResult">
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

	<cffunction name="LoadDeals" access="public" returntype="void" hint="Load deal info.">
		<cfargument name="args" type="struct" required="no" default="{}">
		<cftry>
		<cfset loc = {}>
		<cfquery name="loc.QActiveDeals" datasource="#GetDataSource()#">
			SELECT *
			FROM tblEPOS_Deals
			WHERE edStatus = 'active'
			<!---AND edEnds > #Now()#--->
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
			<!--- AND edStarts <= #Now()#		TODO check time issues
			AND edEnds > #Now()# --->
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
			<cfdump var="#cfcatch#" label="LoadDeals" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
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
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>
</cfcomponent>