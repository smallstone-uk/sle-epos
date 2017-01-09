<cfcomponent displayname="EPOS" hint="EPOS Till Functions">

	<cffunction name="GetDataSource" access="public" returntype="string">
		<cfreturn application.site.datasource1>
	</cffunction>
	
	<cffunction name="ZTill" access="public" returntype="void" hint="initialise till at start of day.">
		<cfargument name="loadDate" type="date" required="yes">
		<cfset StructDelete(session,"till",false)>
		<cfset session.till = {}>
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
		<cfset session.basket.products = []>
		<cfset session.basket.suppliers = []>
		<cfset session.basket.payments = []>
		<cfset session.basket.prizes = []>
		<cfset session.basket.vouchers = []>
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
		<cfset session.basket.header.bPrize = 0>
		
		<cfset session.basket.header.cAcct = 0>
		<cfset session.basket.header.cVoucher = 0>
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
		<cfset session.basket.total.supplies = 0>
		<cfset session.basket.total.balance = 0>
	</cffunction>
	
	<cffunction name="CalcTotals" access="public" returntype="void" hint="calculate till totals.">
		<cfset session.basket.total.cashINDW = session.basket.header.cashtaken + session.basket.header.change>
		<cfset session.basket.total.cardINDW = session.basket.header.cardsales + session.basket.header.cashback>
		<cfset session.basket.total.chqINDW = session.basket.header.chqsales>
		<cfset session.basket.total.accINDW = session.basket.header.cAcct>
<!---
		<cfset session.basket.received = session.basket.header.cashtaken + session.basket.total.cardINDW + 
			session.basket.total.chqINDW>
		<cfset session.basket.items = ArrayLen(session.basket.products) + ArrayLen(session.basket.suppliers) + 
			ArrayLen(session.basket.prizes) + ArrayLen(session.basket.vouchers) + ArrayLen(session.basket.news)>
--->
	</cffunction>

	<cffunction name="CheckDeals" access="public" returntype="void" hint="check basket for qualifying deals.">
		<cfset var loc = {}>
		<cfset loc.regMode = (2 * int(session.basket.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
		<cfset loc.tranType = -1>
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
							<!---<cfset loc.item.dealTotal = -(loc.item.retail - loc.item.dealTotal)>--->
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
				</cfif>
			</cfif>
			<cfif loc.item.dealTotal eq 0>
				<cfset loc.item.totalGross = loc.item.qty * loc.item.unitPrice>
				<cfif session.basket.staff AND loc.item.discountable>	<!--- staff sale and is a discountable item --->
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

	<cffunction name="UpdateBasket" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.insertItem = false>

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
			<cfset StructDelete(session.basket.prodKeys,args.form.prodID)>
			<cfset ArrayDelete(session.basket.products,args.form.prodID)>
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

		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.result.err = "">
		
		<cfif Left(args.form.type,5) eq "prod-">
			<cfset args.form.prodID = val(mid(args.form.type,6,10))>
			<cfset args.form.type = "SALE">
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
		<cfset loc.vrate = 1 + (val(args.form.vrate) / 100)>
		<cfset args.form.vcode = StructFind(session.vat,DecimalFormat(args.form.vrate))>
		<cfset session.basket.errMsg = "">
		
        <cfswitch expression="#args.form.type#">
            <cfcase value="SALE|SALEL|SALEZ|SRV" delimiters="|">
                <cfif ArrayLen(session.basket.suppliers) gt 0>
                    <cfset session.basket.errMsg = "Cannot start a sales transaction during a supplier transaction.">
                <cfelse>
                    <cfif args.form.credit + args.form.cash neq 0>
						<cfset UpdateBasket(args)>
						<cfset CalcTotals()>
                    <cfelse>
                        <cfset session.basket.errMsg = "No value was passed.">
                    </cfif>
                </cfif>
            </cfcase>			
            <cfcase value="PP">
                <cfif ArrayLen(session.basket.suppliers) gt 0> <!--- already have supplier transaction in basket --->
                    <cfset session.basket.errMsg = "Cannot add a paypoint item during a supplier transaction.">
                <cfelse>
                    <cfif args.form.cash neq 0>
                        <cfset args.form.class = "item">
                        <cfset args.form.account = 5>
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
                        <cfset args.form.account = 5>
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
                        <cfset args.form.account = 5>
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
            <cfcase value="NEWS">
                <cfif ArrayLen(session.basket.suppliers) gt 0> <!--- already have supplier transaction in basket --->
                    <cfset session.basket.errMsg = "Cannot pay a news account during a supplier transaction.">
                <cfelse>
                    <cfif args.form.credit + args.form.cash neq 0>
                        <cfset args.form.class = "item">
                        <cfset args.form.account = 5>
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
                        <cfset args.form.account = 5>
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

	<cffunction name="AddPayment" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cftry>
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
						<cfset args.form.account = 5>
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
						<cfset args.form.account = 5>
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
						<cfset args.form.account = 5>
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
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="ShowBasket" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.arrCount = 0>
		<cfset loc.itemCount = 0>
		<cfset loc.discables = 0>
		<cfset loc.total = 0>
		<cfset session.basket.vatAnalysis = {}>
		<cfoutput>
			<table class="eposBasketTable" border="0">
				<tr>
					<td>Description</td>
					<td>Qty</td>
					<td>Price</td>
					<td>Total</td>
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
				<cfset session.basket.header.cPaypoint = 0>
				<cfset session.basket.header.cLottery = 0>
				
				<cfset session.basket.header.balance = 0>
				
				<cfset session.basket.total.shop = 0>
				<cfset session.basket.total.ext = 0>
				<cfset session.basket.total.news = 0>
				
				<cfloop collection="#session.basket.prodKeys#" item="loc.key">
					<cfset loc.arrCount++>
					<cfset loc.item = StructFind(session.basket.prodKeys,loc.key)>
					
					<cfset loc.total += (loc.item.retail + loc.item.discount)>
					<cfset loc.itemCount += loc.item.qty>
					<cfset loc.discables += (loc.item.qty * loc.item.discountable)>
					<tr>
						<td>#loc.item.prodTitle#</td>
						<td align="right">#loc.item.qty#</td>
						<td align="right">#DecimalFormat(loc.item.unitPrice)#</td>
						<td align="right">#DecimalFormat(-loc.item.retail)#</td>
					</tr>
					<cfif loc.item.dealID neq 0>
						<cfif loc.item.dealQty neq 0>
							<cfset loc.total += loc.item.dealTotal>
							<tr>
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
				</cfloop>
				<cfset session.basket.total.shop = loc.total>
				<cfloop list="suppliers|news|prizes|vouchers|paypoint" delimiters="|" index="loc.arr">
					<cfset loc.section = StructFind(args,loc.arr)>
					<cfloop array="#loc.section#" index="loc.item">
						<cfset loc.total += (loc.item.cash + loc.item.credit)>
						<cfswitch expression="#loc.arr#">
							<cfcase value="news">
								<cfset session.basket.header.bNews += (loc.item.cash + loc.item.credit)>
								<cfset session.basket.total.news += (loc.item.cash + loc.item.credit)>
							</cfcase>
							<cfcase value="vouchers">
								<cfset session.basket.header.cVoucher += (loc.item.cash + loc.item.credit)>
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
				<cfloop array="#session.basket.payments#" index="loc.item">
					<cfset loc.total += (loc.item.cash + loc.item.credit)>
					<tr>
						<td colspan="3">#loc.item.title#</td><td align="right">#DecimalFormat(-(loc.item.cash + loc.item.credit))#</td>
					</tr>
				</cfloop>
				<tr>
					<td colspan="4">&nbsp;</td>
				</tr>
				<cfif session.basket.header.aDiscStaff neq 0>
					<tr>
						<td>Staff Discount</td>
						<td align="right">#loc.discables#</td>
						<td></td>
						<td align="right">#DecimalFormat(session.basket.header.aDiscStaff)#</td>
					</tr>
				</cfif>
				<cfset session.basket.header.balance = -loc.total>
				<cfset session.basket.total.balance = -loc.total>
				<tr>
					<td>Balance Due</td>
					<td align="right">#loc.itemCount#</td>
					<td></td>
					<td align="right">#DecimalFormat(-loc.total)#</td>
				</tr>
			</table>
		</cfoutput>
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
					#args.total.vat#,
					'#args.mode#',
					'#args.type#'
				)
			</cfquery>
			<cfset loc.ID = loc.QInsertHeaderResult.generatedkey>
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
				<cfset loc.discTotal += loc.item.totalDisc>
			</cfloop>
			<cfloop list="suppliers|news|prizes|vouchers" delimiters="|" index="loc.arr">
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
					<cfset loc.discTotal += loc.item.totalDisc>
				</cfloop>
			</cfloop>
			<cfif loc.discTotal neq 0>
				<cfset loc.result.str = "#loc.result.str#,(#loc.ID#,'#loc.item.class#','DISC','credit',#loc.item.prodID#,1,#loc.discTotal#,0)">
				<cfset loc.result.str = "#loc.result.str#,(#loc.ID#,'#loc.item.class#','STAFF','credit',#loc.item.prodID#,1,#-loc.discTotal#,0)">
			</cfif>
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
			<cfset loc.accountID = 5>
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
						<cfif loc.item.account neq 5 AND loc.accountID eq 5><cfset loc.accountID = loc.item.account></cfif>
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
		<cfargument name="transactionID" type="numeric" required="yes">
		<cfset var loc = {}>
		<cftry>
			<cfset loc.result = {}>
			<cfset loc.invert = -1>
			<cfset loc.count = 0>
			<cfset loc.itemCount = 0>
			<cfset loc.netTotal = 0>
			
			<cfoutput>
				<div id="receipt">#loc.netTotal#
					<p>#args.type# <cfif args.mode eq "reg">RECEIPT<cfelse>REFUND</cfif> &nbsp; #transactionID#</p>
					<table class="tableList" border="1">
						<cfloop array="#args.products#" index="loc.prod">
							<cfset loc.item = StructFind(args.prodKeys,loc.prod)>
							<cfset loc.netTotal += loc.item.totalGross>
							<cfset loc.itemCount += loc.item.qty>
							<tr>
								<td>SALE <cfif loc.item.cash neq 0>(cash)</cfif></td>
								<td>#loc.item.prodTitle#</td>
								<td align="right">#loc.item.qty#</td>
								<td align="right">#DecimalFormat(loc.item.retail * loc.invert)#</td>
								<td>#loc.item.vrate#</td>
							</tr>
							<cfif loc.item.dealID neq 0>
								<cfif loc.item.dealQty neq 0>
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
						
						<cfloop list="suppliers|news|prizes|vouchers" delimiters="|" index="loc.arr">
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
											<td align="right">#loc.line.vrate#%</td>
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

	<cffunction name="GetAccounts" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
			<cfquery name="loc.result.Accounts" datasource="#GetDataSource()#">
				SELECT accID,accName 
				FROM tblAccount
				WHERE accGroup =20
				AND accType =  'sales';
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
		<cfargument name="args" type="struct" required="yes">
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
				<cfset loc.item="#loc.item#,#ediParent#">
				<cfset StructUpdate(session.dealIDs,ediProduct,loc.item)>
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
			<cfdump var="#loc.QVAT#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>
</cfcomponent>