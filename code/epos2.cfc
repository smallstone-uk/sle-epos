<cfcomponent displayname="epos2" extends="epos">
	<cffunction name="ZTill" access="public" returntype="void" hint="initialise till at start of day.">
		<cfset StructDelete(session,"till",false)>
		<cfset session.till = {}>
		<cfset session.till.header = {}>
		<cfset session.till.total = {}>
		<cfset session.till.trans = []>
		<cfset session.till.total.float = -200>
		<cfset session.till.total.cashINDW = 200>
		<cfset session.till.prefs.mincard = 3.00>
		<cfset session.till.prefs.service = 0.50>
		<cfset session.till.prefs.discount = 0.10>
		<cfset session.till.prefs.reportDate = LSDateFormat(Now(),"yyyy-mm-dd")>
		<cfset ClearBasket()>
	</cffunction>

	<cffunction name="ClearBasket" access="public" returntype="void" hint="clear current transaction without affecting till totals.">
		<cfset StructDelete(session,"basket",false)>
		<cfset session.basket = {}>
		<cfset session.basket.datasource = "kcc_sle_production">
		<cfset session.basket.mode = "reg">
		<cfset session.basket.type = "SALE">
		<cfset session.basket.bod = "Customer">
		<cfset session.basket.errMsg = "">
		<cfset session.basket.products = []>
		<cfset session.basket.suppliers = []>
		<cfset session.basket.payments = []>
		<cfset session.basket.prizes = []>
		<cfset session.basket.vouchers = []>
		<cfset session.basket.news = []>
		<cfset session.basket.items = 0>
		<cfset session.basket.received = 0>
		<cfset session.basket.staff = false>
		<cfset session.basket.vatAnalysis = {}>
				
		<cfset session.basket.header = {}>
		<cfset session.basket.header.acctcash = 0>
		<cfset session.basket.header.acctcredit = 0>
		<cfset session.basket.header.vat = 0>
		<cfset session.basket.header.cashback = 0>
		<cfset session.basket.header.change = 0>
		<cfset session.basket.header.cashtaken = 0>
		<cfset session.basket.header.cardsales = 0>
		<cfset session.basket.header.chqsales = 0>
		<cfset session.basket.header.accsales = 0>
		<cfset session.basket.header.balance = 0>
		<cfset session.basket.header.supplies = 0>
		<cfset session.basket.header.prize = 0>
		<cfset session.basket.header.voucher = 0>
		
		<cfset session.basket.total = {}>
		<cfset session.basket.total.cashINDW = 0>
		<cfset session.basket.total.cardINDW = 0>
		<cfset session.basket.total.chqINDW = 0>
		<cfset session.basket.total.accINDW = 0>
		<cfset session.basket.total.sales = 0>
		<cfset session.basket.total.supplies = 0>
		<cfset session.basket.total.prize = 0>
		<cfset session.basket.total.voucher = 0>
		<cfset session.basket.total.news = 0>
		<cfset session.basket.total.vat = 0>
		<cfset session.basket.total.discount = 0>
		<cfset session.basket.total.staff = 0>
	</cffunction>
	
	<cffunction name="CalcTotals" access="public" returntype="void" hint="calculate till totals.">
		<cfset session.basket.total.cashINDW = session.basket.header.cashtaken + session.basket.header.change>
		<cfset session.basket.total.cardINDW = session.basket.header.cardsales + session.basket.header.cashback>
		<cfset session.basket.total.chqINDW = session.basket.header.chqsales>
		<cfset session.basket.total.accINDW = session.basket.header.accsales>
		<cfset session.basket.total.vat = session.basket.header.vat>
		<cfset session.basket.received = session.basket.header.cashtaken + session.basket.total.cardINDW + 
			session.basket.total.chqINDW + session.basket.total.prize + session.basket.total.voucher>
		<cfset session.basket.items = ArrayLen(session.basket.products) + ArrayLen(session.basket.suppliers) + 
			ArrayLen(session.basket.prizes) + ArrayLen(session.basket.vouchers) + ArrayLen(session.basket.news)>
	</cffunction>
	
	<cffunction name="AddItem" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>

<!---		<cfdump var="#args#" label="" expand="yes" format="html" 
			output="#application.site.dir_logs#item-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
--->
		<cfset loc.result = {}>
		<cfset loc.result.err = "">
		<cfset loc.regMode = (2 * int(session.basket.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
		<cfset loc.tranType = (2 * int(ListFind("SALE|SALEZ|SALEL|NEWS",args.form.type,"|") eq 0)) - 1> <!--- modes: sales or news = -1 others = 1 --->
		<cfset args.form.cash = abs(val(args.form.cash)) * loc.tranType * loc.regMode> <!--- all form values are +ve numbers --->
		<cfset args.form.credit = abs(val(args.form.credit)) * loc.tranType * loc.regMode>	<!--- apply mode & type to set sign correctly --->
		<cfset loc.receipts = session.basket.received>
		<cfset session.basket.errMsg = "">	<!--- clear error message --->

		<cfswitch expression="#args.form.btnSend#">
			<!--- product types --->
			<cfcase value="Add">
				<cfswitch expression="#args.form.type#">
					<cfcase value="SALE|SALEL|SALEZ|product" delimiters="|">
						<cfif ArrayLen(session.basket.suppliers) gt 0>
							<cfset session.basket.errMsg = "Cannot start a sales transaction during a supplier transaction.">
						<cfelse>
							<cfif args.form.credit + args.form.cash neq 0>
								<cfset args.form.class = "item">
								<cfset args.form.account = 5>
								<!---<cfset args.form.title = "Sale">--->
								<cfif session.basket.staff AND StructKeyExists(args.form,"discountable")>	<!--- staff sale and discountable item --->
									<cfset loc.cashDiscount = args.form.cash * session.till.prefs.discount>
									<cfset args.form.cash = args.form.cash - loc.cashDiscount>
									<cfset loc.creditDiscount = args.form.credit * session.till.prefs.discount>
									<cfset args.form.credit = args.form.credit - loc.creditDiscount>
									<cfset args.form.discount = loc.cashDiscount + loc.creditDiscount>
								<cfelse>
									<cfset args.form.discount = 0>
								</cfif>
								<cfset args.form.gross = args.form.credit + args.form.cash>	<!--- calc gross transaction value --->
								<cfset args.form.cash = int(args.form.cash / (1 + args.form.vrate) * 100) / 100>	<!--- calc clean cash net value --->
								<cfset args.form.credit = int(args.form.credit / (1 + args.form.vrate) * 100) / 100>	<!--- calc clean credit net value --->
								<cfset args.form.vat = args.form.gross - args.form.credit - args.form.cash> <!--- calc vat element --->
								
								<cfset session.basket.total.sales += args.form.credit + args.form.cash> <!--- accumulate net sales total --->
								<cfset session.basket.total.discount += args.form.discount> <!--- accumulate discount granted --->
								<cfset session.basket.total.staff -= args.form.discount> <!--- balance accounts --->
								<cfset session.basket.header.acctcredit += args.form.credit> <!--- store credit a/c amount --->
								<cfset session.basket.header.acctcash += args.form.cash> <!--- store cash sale amount --->
								<cfset session.basket.header.vat += args.form.vat> <!--- accumulate VAT amounts --->
								<cfset session.basket.header.balance -= args.form.gross> <!--- accumulate customer balance --->
								<cfset ArrayAppend(session.basket.products,args.form)> <!--- add item to product array --->
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
								<cfset session.basket.total.prize += args.form.cash>	<!--- accumulate prize total --->
								<cfset session.basket.header.prize += args.form.cash>
								<cfset session.basket.header.balance -= args.form.cash>
								<cfset ArrayAppend(session.basket.prizes,args.form)> <!--- add item to payment array --->
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
								<cfset session.basket.total.voucher += args.form.cash>	<!--- accumulate voucher total --->
								<cfset session.basket.header.voucher += args.form.cash>
								<cfset session.basket.header.balance -= args.form.cash>
								<cfset ArrayAppend(session.basket.vouchers,args.form)> <!--- add item to payment array --->
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
								<cfset session.basket.total.news += args.form.credit + args.form.cash>	<!--- accumulate sales total --->
								<cfset session.basket.header.acctcredit += args.form.credit>	<!--- store credit a/c amount --->
								<cfset session.basket.header.acctcash += args.form.cash>	<!--- store cash sale amount --->
								<cfset session.basket.header.balance -= (args.form.credit + args.form.cash)>
								<cfset ArrayAppend(session.basket.news,args.form)> <!--- add item to product array --->
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
								<cfset session.basket.type = "PURCH">	<!--- set receipt title --->
								<cfset session.basket.bod = "Supplier">
								<cfset session.basket.total.supplies += args.form.credit + args.form.cash>	<!--- accumulate supplier total --->
								<cfset session.basket.header.supplies += args.form.credit + args.form.cash>
								<cfset session.basket.header.balance -= (args.form.credit + args.form.cash)>
								<cfset ArrayAppend(session.basket.suppliers,args.form)>
								<cfset CalcTotals()>
							</cfif>
						</cfif>
					</cfcase>
				</cfswitch>
			</cfcase>
			<!--- payment methods --->
			<cfcase value="Cash">
				<cfif session.basket.items eq 0>
					<cfset session.basket.errMsg = "Please put an item in the basket before accepting payment.">
				<cfelse>
					<cfset args.form.class = "pay">
					<cfset args.form.type = "CASH">
					<cfset args.form.title = "Cash Payment">
					<cfset args.form.account = 5>
					<cfset args.form.credit = 0>
					<cfif args.form.cash is 0>
						<cfset args.form.cash = session.basket.header.balance * loc.tranType>
					</cfif>
					<cfif ArrayLen(session.basket.suppliers) gt 0>
						<cfset args.form.cash = session.basket.header.balance * loc.tranType>
						<cfset session.basket.header.cashtaken = args.form.cash>
						<cfset session.basket.header.balance = 0>
					<cfelse>
						<cfset session.basket.header.cashtaken += args.form.cash>
						<cfset session.basket.header.balance -= (args.form.credit + args.form.cash)>
					</cfif>
					<cfset ArrayAppend(session.basket.payments,args.form)>
					<cfif session.basket.mode eq "reg" AND session.basket.header.balance lte 0>
						<cfset session.basket.header.change = session.basket.header.balance>
						<cfset session.basket.header.balance = 0>
						<cfset CalcTotals()>
						<cfset CloseTransaction(args.form.writeTran)>
					<cfelseif session.basket.mode eq "rfd" AND session.basket.header.balance gte 0>
						<cfset session.basket.header.change = session.basket.header.balance>
						<cfset session.basket.header.balance = 0>
						<cfset CalcTotals()>
						<cfset CloseTransaction(args.form.writeTran)>
					<cfelse>
						<cfset CalcTotals()>
					</cfif>
				</cfif>
			</cfcase>
			<cfcase value="Card">
				<cfset loc.cashBalance = session.basket.header.cashback + session.basket.header.cashTaken + session.basket.header.acctCash + 
					session.basket.header.prize + session.basket.header.voucher + args.form.cash>
				<cfif session.basket.items eq 0>
					<cfset session.basket.errMsg = "Please put an item in the basket before accepting payment.">
				<cfelseif ArrayLen(session.basket.suppliers) gt 0>
					<cfset session.basket.errMsg = "Cannot accept a card payment during a supplier transaction.">
				<cfelseif session.basket.mode eq "reg" AND loc.cashBalance lt 0>
					<cfset session.basket.errMsg = "Some items in the basket must be paid by cash or cashback.">
				<cfelseif session.basket.mode eq "rfd" AND loc.cashBalance gt 0>
					<cfset session.basket.errMsg = "Some items in the basket must be refunded by cash.">
				<cfelseif args.form.credit gt session.basket.header.balance + session.basket.header.acctcash>
					<cfset session.basket.errMsg = "Card sale amount is too high.">
				<cfelseif args.form.cash neq 0 AND args.form.credit eq 0>
					<cfset session.basket.errMsg = "Please enter the sale amount from the Paypoint receipt.">
				<cfelseif abs(args.form.credit) lt session.till.prefs.mincard AND abs(args.form.credit) neq session.till.prefs.service>
					<cfset session.basket.errMsg = "Minimum sale amount allowed on card is &pound;#session.till.prefs.mincard#.">
				<cfelse>
					<cfset args.form.class = "pay">
					<cfset args.form.type = "CARD">
					<cfset args.form.title = "Card Payment">
					<cfset args.form.account = 5>
					<cfif args.form.cash + args.form.credit is 0>
						<cfset args.form.credit = session.basket.header.balance * loc.tranType>
					</cfif>
					<cfset session.basket.header.cardsales += args.form.credit>
					<cfset session.basket.header.cashback += args.form.cash>
					<cfset session.basket.header.balance -= (args.form.credit + args.form.cash)>
					<cfset ArrayAppend(session.basket.payments,args.form)>
					<cfif session.basket.mode eq "reg" AND session.basket.header.balance lte 0>
						<cfset session.basket.header.change = session.basket.header.balance>
						<cfset session.basket.header.balance = 0>
						<cfset CalcTotals()>
						<cfset CloseTransaction(args.form.writeTran)>
					<cfelseif session.basket.mode eq "rfd" AND session.basket.header.balance gte 0>
						<cfset session.basket.header.change = session.basket.header.balance>
						<cfset session.basket.header.balance = 0>
						<cfset CalcTotals()>
						<cfset CloseTransaction(args.form.writeTran)>
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
				<cfelseif abs(session.basket.total.news) neq abs(args.form.cash)>
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
						<cfset CalcTotals()>
						<cfset CloseTransaction(args.form.writeTran)>
					<cfelseif session.basket.mode eq "rfd" AND session.basket.header.balance gte 0>
						<cfset session.basket.header.change = session.basket.header.balance>
						<cfset session.basket.header.balance = 0>
						<cfset CalcTotals()>
						<cfset CloseTransaction(args.form.writeTran)>
					<cfelse>
						<cfset CalcTotals()>
					</cfif>
				</cfif>
			</cfcase>
			<cfcase value="Account">
				<cfif session.basket.items eq 0>
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
					<cfset session.basket.header.accsales += session.basket.header.balance>
					<cfset session.basket.header.balance = 0>
					<cfset ArrayAppend(session.basket.payments,args.form)>
					<cfset CalcTotals()>
					<cfset CloseTransaction(args.form.writeTran)>
				</cfif>
			</cfcase>
		</cfswitch>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="WriteTotal" access="public" returntype="struct">
		<cfargument name="datasource" type="string" required="yes">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="numeric" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cftry>
			<cfquery name="loc.QFindKey" datasource="#datasource#">
				SELECT *
				FROM tblEPOS_Totals
				WHERE totDate='#session.till.prefs.reportDate#'
				AND totAcc='#key#'
				LIMIT 1;
			</cfquery>
			<cfif loc.QFindKey.recordcount eq 1>
				<cfquery name="loc.QUpdate" datasource="#datasource#" result="loc.QUpdateResult">
					UPDATE tblEPOS_Totals
					SET totValue = #value#
					WHERE totDate='#session.till.prefs.reportDate#'
					AND totAcc='#key#'
				</cfquery>
			<cfelse>
				<cfquery name="loc.QInsert" datasource="#datasource#" result="loc.QInsertResult">
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
				output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="SaveTillTotals" access="public" returntype="void">
		<cfset var loc = {}>
		<cfset loc.keys = ListSort(StructKeyList(session.till.total,","),"text","ASC",",")>
		<cfloop list="#loc.keys#" index="loc.fld">
			<cfif session.till.total[loc.fld] neq 0>
				<cfset WriteTotal(session.basket.datasource,loc.fld,session.till.total[loc.fld])>
			</cfif>
		</cfloop>
	</cffunction>
	
	<cffunction name="CloseTransaction" access="public" returntype="void">
		<cfargument name="writeTran" type="boolean" default="true" required="yes">
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
		<cfset ArrayAppend(session.till.trans,session.basket)>
		<cfif writeTran>
			<cfset WriteTransaction(session.basket)>
			<cfset SaveTillTotals()>
		</cfif>
		<cfset ClearBasket()>
	</cffunction>
	
	<cffunction name="WriteTransaction" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.count = 0>
		<cfset loc.result.str = "">
		<cftry>
			<cfquery name="loc.QInsertHeader" datasource="#args.datasource#" result="loc.QInsertHeaderResult">
				INSERT INTO tblEPOS_Header (
					ehEmployee,
					ehNet,
					ehVAT,
					ehMode,
					ehType
					
				) VALUES (
					122,	<!--- TODO provide user ID --->
					#args.header.acctCash + args.header.acctCredit#,
					#args.header.VAT#,
					'#args.mode#',
					'#args.type#'
				)
			</cfquery>
			<cfset loc.ID = loc.QInsertHeaderResult.generatedkey>
			<cfset loc.discTotal = 0>
			<cfloop list="suppliers|products|news|prizes|vouchers" delimiters="|" index="loc.arr">
				<cfset loc.section = StructFind(args,loc.arr)>
				<cfloop array="#loc.section#" index="loc.item">
					<cfset loc.count++>
					<cfif loc.item.cash neq 0>
						<cfset loc.item.payType = 'cash'>
					<cfelse>
						<cfset loc.item.payType = 'credit'>
					</cfif>
					<cfset loc.result.str = "#loc.result.str#,(#loc.ID#,'#loc.item.class#','#loc.item.type#','#loc.item.payType#',#loc.item.cash + loc.item.credit#,#loc.item.VAT#)">
					<cfset loc.discTotal += loc.item.discount>
				</cfloop>
			</cfloop>
			<cfif loc.discTotal neq 0>
				<cfset loc.result.str = "#loc.result.str#,(#loc.ID#,'#loc.item.class#','DISC','credit',#loc.discTotal#,0)">
				<cfset loc.result.str = "#loc.result.str#,(#loc.ID#,'#loc.item.class#','STAFF','credit',#-loc.discTotal#,0)">
			</cfif>
			<cfset loc.result.str = RemoveChars(loc.result.str,1,1)>	<!--- delete leading comma --->
			<cfquery name="loc.QInserItem" datasource="#args.datasource#">
				INSERT INTO tblEPOS_Items (
					eiParent,
					eiClass,
					eiType,
					eiPayType,
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
					<cfquery name="loc.QInserItem" datasource="#args.datasource#">
						INSERT INTO tblEPOS_Items (
							eiParent,
							eiClass,
							eiType,
							eiAccID,
							eiNet
						) VALUES (
							#loc.QInsertHeaderResult.generatedkey#,
							'pay',
							'#loc.key#',
							#loc.accountID#,
							#loc.value#
						)
					</cfquery>
				</cfif>			
			</cfloop>

		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="DumpTrans" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
			<cfquery name="loc.QTrans" datasource="#args.datasource#">
				SELECT *
				FROM tblEPOS_Items
				INNER JOIN tblEPOS_Header ON ehID = eiParent
				WHERE Date(ehTimestamp) = '#session.till.prefs.reportDate#'
			</cfquery>
			<cfset loc.result.QTrans = loc.QTrans>
			<cfset loc.net = 0>
			<cfset loc.vat = 0>
			<cfset loc.cr = 0>
			<cfset loc.dr = 0>
			<cfset loc.tran = 0>
			<cfoutput>
			<table class="tableList" width="700">
				<tr>
					<th>Tran</th>
					<th>Mode</th>
					<th>ID</th>
					<th>Timestamp</th>
					<th>Type</th>
					<th>Qty</th>
					<th align="right">Net</th>
					<th align="right">VAT</th>
					<th align="right">DR</th>
					<th align="right">CR</th>
				</tr>
				<cfloop query="loc.QTrans">
					<cfset loc.gross = eiNet + eiVAT>
					<cfset loc.net += eiNet>
					<cfset loc.vat += eiVAT>
					<cfif loc.tran gt 0 AND loc.tran neq eiParent>
						<tr><td colspan="11">&nbsp;</td></tr>
					</cfif>
					<tr>
						<td>#eiParent#</td>
						<td>#ehMode#</td>
						<td>#eiID#</td>
						<td>#LSDateFormat(eiTimestamp)#</td>
						<td>#eiType#</td>
						<td align="center">#eiQty#</td>
						<td align="right">#eiNet#</td>
						<td align="right">#eiVAT#</td>
						<cfif loc.gross gt 0>
							<cfset loc.dr += loc.gross>
							<td align="right">#DecimalFormat(loc.gross)#</td>
							<td align="right"></td>
						<cfelse>
							<cfset loc.cr -= loc.gross>
							<td align="right"></td>
							<td align="right">#DecimalFormat(-loc.gross)#</td>
						</cfif>
					</tr>
					<cfset loc.tran = eiParent>
				</cfloop>
				<tr>
					<th></th>
					<th></th>
					<th></th>
					<th></th>
					<th></th>
					<th></th>
					<th align="right">#DecimalFormat(loc.net)#</th>
					<th align="right">#DecimalFormat(loc.vat)#</th>
					<th align="right">#DecimalFormat(loc.dr)#</th>
					<th align="right">#DecimalFormat(loc.cr)#</th>
				</tr>
			</table>
			</cfoutput>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="TranReport" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.result.summ.cashtaken = 0>
		<cfset loc.result.summ.cardsales = 0>
		<cfset loc.result.summ.purch = 0>
		<cfset loc.result.sales = {"count"=0,"value"=0}>
		<cfset loc.result.vat = {"count"=0,"value"=0}>
		<cftry>
			<cfquery name="loc.QTrans" datasource="#args.datasource#">
				SELECT eiType, SUM(eiNet) AS net, SUM(eiVAT) AS vat, COUNT(*) AS num
				FROM tblEPOS_Items
				INNER JOIN tblEPOS_Header ON ehID = eiParent
				WHERE Date(ehTimestamp) = '#session.till.prefs.reportDate#'
				GROUP BY eiType
			</cfquery>
			<cfloop query="loc.QTrans">
				<cfset loc.gross = Net + VAT>
				<cfif ListFind("SALE|SALEL|SALEZ",eiType,"|")>
					<cfset loc.tot = StructFind(loc.result,"sales")>
					<cfset loc.tot.count += num>
					<cfset loc.tot.value += Net>
					<cfset StructUpdate(loc.result,"sales",loc.tot)>
					
					<cfset loc.tot = StructFind(loc.result,"VAT")>
					<cfset loc.tot.count += num>
					<cfset loc.tot.value += VAT>
					<cfset StructUpdate(loc.result,"VAT",loc.tot)>
					
				<cfelse>
					<cfset StructInsert(loc.result,eiType,{"count"=num,"value"=Net + VAT})>
				</cfif>
				<cfif ListFind("CASH|SUPP",eiType,"|")><cfset loc.result.summ.cashtaken += loc.gross></cfif>
				<cfif ListFind("CARD",eiType,"|")><cfset loc.result.summ.cardsales += loc.gross></cfif>
				<cfif ListFind("SUPP",eiType,"|")><cfset loc.result.summ.purch += loc.gross></cfif>
			</cfloop>
			<cfset loc.cr = 0>
			<cfset loc.dr = 0>
			<cfoutput>
			<table class="tableList" width="400" border="1">
				<tr>
					<th>Type</th>
					<th>Count</th>
					<th align="right">DR</th>
					<th align="right">CR</th>
				</tr>
				<cfloop collection="#loc.result#" item="loc.key">
					<cfif loc.key neq "SUMM">
					<cfset loc.item=StructFind(loc.result,loc.key)>
					<tr>
						<td>#loc.key#</td>
						<td align="center">#loc.item.count#</td>
						<cfif loc.item.value gt 0>
							<cfset loc.dr += loc.item.value>
							<td align="right">#DecimalFormat(loc.item.value)#</td>
							<td align="right"></td>
						<cfelse>
							<cfset loc.cr -= loc.item.value>
							<td align="right"></td>
							<td align="right">#DecimalFormat(-loc.item.value)#</td>
						</cfif>
					</tr>
					</cfif>
				</cfloop>
				<tr>
					<th></th>
					<th></th>
					<th align="right">#DecimalFormat(loc.dr)#</th>
					<th align="right">#DecimalFormat(loc.cr)#</th>
				</tr>
			</table>
			</cfoutput>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="CalcVAT" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfif NOT StructKeyExists(session.basket.vatAnalysis,args.vcode)>
			<cfset StructInsert(session.basket.vatAnalysis,args.vcode,{"vrate"=args.vrate, "net"=args.cash+args.credit, "VAT"=args.vat, "gross"=args.gross})>
		<cfelse>
			<cfset loc.vatAnalysis = StructFind(session.basket.vatAnalysis,args.vcode)>
			<cfset loc.vatAnalysis.net += args.cash+args.credit>
			<cfset loc.vatAnalysis.vat += args.vat>
			<cfset loc.vatAnalysis.gross += args.gross>
			<cfset StructUpdate(session.basket.vatAnalysis,args.vcode,loc.vatAnalysis)>
		</cfif>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="ShowBasket" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.netTotal = args.total.sales + args.total.prize + args.total.news + args.total.voucher + args.total.vat>
		<cfset session.basket.vatAnalysis = {}>
		<cfoutput>
		<table class="tableList">
			<cfloop list="suppliers|products|news|prizes|vouchers" delimiters="|" index="loc.arr">
				<cfset loc.section = StructFind(args,loc.arr)>
				<cfloop array="#loc.section#" index="loc.item">
					<tr>
						<td>#loc.item.type#<cfif loc.item.cash neq 0> (cash)</cfif></td>
						<td>#loc.item.title#</td>
						<td align="right">#DecimalFormat(loc.item.gross)#</td>
					</tr>
					<cfif loc.item.vcode gt 0>
						<cfif NOT StructKeyExists(session.basket.vatAnalysis,loc.item.vcode)>
							<cfset StructInsert(session.basket.vatAnalysis,loc.item.vcode,{
								"vrate"=loc.item.vrate,"net"=loc.item.cash + loc.item.credit,"VAT"=loc.item.vat,"gross"=loc.item.gross})>
						<cfelse>
							<cfset loc.vatAnalysis = StructFind(session.basket.vatAnalysis,loc.item.vcode)>
							<cfset loc.vatAnalysis.net += loc.item.cash + loc.item.credit>
							<cfset loc.vatAnalysis.vat += loc.item.vat>
							<cfset loc.vatAnalysis.gross += loc.item.gross>
							<cfset StructUpdate(session.basket.vatAnalysis,loc.item.vcode,loc.vatAnalysis)>
						</cfif>
					</cfif>
				</cfloop>
			</cfloop>
			<tr>
				<td colspan="2">Total Items: #session.basket.items#</td>
				<td align="right">#DecimalFormat(loc.netTotal)#</td>
			</tr>
			<cfloop list="payments" delimiters="|" index="loc.arr">
				<cfset loc.section = StructFind(args,loc.arr)>
				<cfloop array="#loc.section#" index="loc.item">
					<tr>
						<td>#loc.item.type#<cfif loc.item.cash neq 0> (cash)</cfif></td>
						<td>#loc.item.title#</td>
						<td align="right">#DecimalFormat(loc.item.cash + loc.item.credit)#</td>
					</tr>
				</cfloop>
			</cfloop>
			<cfif session.basket.header.balance lte 0>
				<tr>
					<td colspan="2" width="220">Balance Due to #session.basket.bod#</td><td align="right">#DecimalFormat(session.basket.header.balance)#</td>
				</tr>
			<cfelse>
				<tr>
					<td colspan="2" width="220">Balance Due from #session.basket.bod#</td><td align="right">#DecimalFormat(session.basket.header.balance)#</td>
				</tr>
			</cfif>
		</table>
		</cfoutput>
	</cffunction>

	<cffunction name="PrintTransactionList" access="public" returntype="struct">
		<cfargument name="trans" type="array" required="yes">
		<cfargument name="totals" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.keys = "">
		<cfoutput>
		<table class="tableList" border="1">
			<cfset loc.loopcount = 0>
			<cfloop array="#trans#" index="loc.item">
				<cfset loc.loopcount++>
				<cfset loc.header = StructFind(loc.item,"header")>
				<cfset loc.keys = ListSort(StructKeyList(loc.header,","),"text","ASC",",")>
				<cfif loc.loopcount IS 1>
					<tr>
						<th></th>
						<th>MODE</th>
						<th>TYPE</th>
						<cfloop list="#loc.keys#" index="loc.title">
							<th>#loc.title#</th>
						</cfloop>
					</tr>
				</cfif>
				<tr>
					<td>#loc.loopcount#</td>
					<td>#loc.item.mode#</td>
					<td>#loc.item.type#</td>
					<cfloop list="#loc.keys#" index="loc.fld">
						<td align="right"><cfif loc.header[loc.fld] neq 0>#DecimalFormat(loc.header[loc.fld])#</cfif></td>
					</cfloop>
				</tr>
			</cfloop>
			<tr>
				<td colspan="3"></td>
				<cfloop list="#loc.keys#" index="loc.fld">
					<td align="right"><strong>#DecimalFormat(totals[loc.fld])#</strong></td>
				</cfloop>
			</tr>
		</table>
		</cfoutput>
		<cfreturn loc.item>	<!--- return last item to output receipt --->
	</cffunction>

	<cffunction name="PrintReceipt" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfargument name="transactionID" type="numeric" required="yes">
		<cfset var loc = {}>
		<cftry>
			<cfset loc.result = {}>
			<cfset loc.invert = -1>
			<cfset loc.count = 0>
			<cfset loc.netTotal = args.total.sales + args.total.prize + args.total.news + args.total.voucher>
			<cfoutput>
				<div id="receipt">
					<p>#args.type# <cfif args.mode eq "reg">RECEIPT<cfelse>REFUND</cfif> &nbsp; #transactionID#</p>
					<table class="tableList" border="1">
						<cfloop list="suppliers|products|news|prizes|vouchers" delimiters="|" index="loc.arr">
							<cfset loc.section = StructFind(args,loc.arr)>
							<cfloop array="#loc.section#" index="loc.item">
								<cfset loc.count++>
								<tr>
									<td>#loc.item.type# <cfif loc.item.cash neq 0>(cash)</cfif></td>
									<td>#loc.item.title#</td>
									<td align="right">#DecimalFormat(loc.item.gross * loc.invert)#</td>
									<td>#loc.item.vcode#</td>
								</tr>
							</cfloop>
						</cfloop>
						<tr>
							<td>#loc.count# items</td>
							<td class="bold">Gross Total</td>
							<td align="right" class="bold">#DecimalFormat((loc.netTotal + args.total.vat) * loc.invert)#</td>
							<td></td>
						</tr>
						<tr><td colspan="5">&nbsp;</td></tr>
						<cfloop array="#args.payments#" index="loc.item">
							<tr>
								<td colspan="2">#loc.item.title#</td><td align="right">#DecimalFormat((loc.item.cash + loc.item.credit))#</td><td></td>
							</tr>
						</cfloop>
						<cfif args.header.balance gte 0>
							<tr>
								<td colspan="2" width="220">Change</td><td align="right">#DecimalFormat(args.header.change * loc.invert)#</td><td></td>
							</tr>
						<cfelse>
							<tr>
								<td colspan="2" width="220">Balance Due from #args.bod#</td><td align="right">#DecimalFormat(args.header.balance)#</td><td></td>
							</tr>
						</cfif>
						<tr>
							<td colspan="4" align="center">
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
											<td align="right">#loc.line.vrate*100#%</td>
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
								VAT No.: <!---#application.siteclient.cltvatno#--->
							</td>
						</tr>
					</table>
				</div>
				<div style="clear:both"></div>
			</cfoutput>
		<cfcatch type="any">
			<p>An error occurred printing the receipt.</p>
			<cfdump var="#cfcatch#" label="" expand="no">
			<cfdump var="#cfcatch#" label="" expand="yes" format="html" 
				output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="GetAccounts" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
			<cfquery name="loc.result.Accounts" datasource="#args.datasource#">
				SELECT accID,accName 
				FROM tblAccount
				WHERE accGroup =20
				AND accType =  'sales';
			</cfquery>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="GetDates" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.result.recs =[]>
		<cftry>
			<cfquery name="loc.QDates" datasource="#args.datasource#">
				SELECT DATE(ehTimeStamp) AS dateOnly
				FROM tblEPOS_Header
				WHERE 1
				GROUP BY dateOnly
				ORDER BY dateOnly DESC
			</cfquery>
			<cfset ArrayAppend(loc.result.recs,{"value"=LSDateFormat(Now(),"yyyy-mm-dd"),"title"=LSDateFormat(Now(),"dd-mmm-yyyy")})>
			<cfloop query="loc.QDates">
				<cfset ArrayAppend(loc.result.recs,{"value"=LSDateFormat(dateOnly,"yyyy-mm-dd"),"title"=LSDateFormat(dateOnly,"dd-mmm-yyyy")})>
			</cfloop>
			
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>
	
	<cffunction name="loadDay" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
			<cfquery name="loc.QTrans" datasource="#args.datasource#" result="loc.QTransResult">
				SELECT tblEPOS_Items.*,DATE(ehTimeStamp) AS dateOnly
				FROM tblEPOS_Header
				INNER JOIN tblEPOS_Items ON eiParent = ehID
				WHERE 1
				HAVING dateOnly='#args.reportDate#';
			</cfquery>
			<cfset ZTill()>
			<cfset session.till.prefs.reportDate = args.reportDate>		
			<cfloop query="loc.QTrans">
				<cfset loc.form = {}>
				<cfset loc.form.type = eiType>
				<cfset loc.form.vrate = 0.20>
				<cfset loc.form.vcode = 2>
				<cfif eiClass eq "item">
					<cfset loc.form.btnSend = "Add">
				<cfelse>
					<cfset loc.form.btnSend = eiType>
				</cfif>
				<cfif eiPayType eq 'cash'>
					<cfset loc.form.cash = eiNet + eiVAT>
					<cfset loc.form.credit = 0>
				<cfelse>
					<cfset loc.form.cash = 0>
					<cfset loc.form.credit = eiNet + eiVAT>
				</cfif>
				<cfset loc.form.writeTran = false>
				<cfset AddItem(loc)>
			</cfloop>
			<cfset ClearBasket()>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
				output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>
</cfcomponent>