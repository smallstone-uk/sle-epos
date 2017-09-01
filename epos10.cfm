<!DOCTYPE HTML>
<html>
<head>
	<meta charset="utf-8">
	<title>EPOS-10</title>
	<style type="text/css">
		#tillpanel {width:580px; float:left; margin:10px; padding:10px; border:solid 2px #ccc; background:#eee; font-family:Arial, Helvetica, sans-serif; font-size:14px;}
		.tableList {border-spacing:0px; border-collapse:collapse; border:1px solid #BDC9DD; font-family:Arial, Helvetica, sans-serif; font-size:12px; border-color:#BDC9DD;}
		.tableList th {padding:4px 5px; background:#EFF3F7; border-color:#BDC9DD; color:#18315C;}
		.tableList td {padding:2px 5px; border-color:#BDC9DD;}
		.header {text-align:center; font-weight:bold; background:#99CCCC;}
		#mode {margin-left:20px; text-transform:uppercase; font-weight:bold;}
		#ctrls {margin:6px;}
		.reg {color:#00FF00;}
		.rfd {color:#FF0000;}
		.pay {margin:0px 10px;}
		.cash {font-size:18px;}
		#errMsg {margin:6px; font-size:16px; color:#ff0000;}
		.bold {font-weight:bold;}
		#receipt {float:left; margin:10px; padding:2px; border:solid 1px #000;}
		#receipt table {border-spacing:0px; border-collapse:collapse; border:1px solid #ccc; font-family:Arial, Helvetica, sans-serif; font-size:12px;}
		#receipt td {padding:2px 5px; border-color:#ccc;}
		.addBtn {float:right; margin:10px; display:block;}
	</style>
	<script src="scripts/jquery-1.11.1.min.js"></script>
	<script>
		$(document).ready(function() {
			$('#productType').change(function(e) {
				var mydata = $(this).children('option:selected').data()
				$('#prodTitle').val(mydata.title);
				$('#prodVATRate').val(mydata.vatrate);
				if (mydata.cashonly) {
					$('#cash').val(mydata.price);
					$('#credit').val("");
				} else {
					$('#cash').val("");
					$('#credit').val(mydata.price);
				}
			}); 
		});
	</script>
</head>

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
		<cfset session.basket.paystation = []>
		<cfset session.basket.news = []>
		<cfset session.basket.items = 0>
		<cfset session.basket.received = 0>
		<cfset session.basket.service = 0>
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
		<cfset session.basket.header.paystation = 0>
		
		<cfset session.basket.total = {}>
		<cfset session.basket.total.cashINDW = 0>
		<cfset session.basket.total.cardINDW = 0>
		<cfset session.basket.total.chqINDW = 0>
		<cfset session.basket.total.accINDW = 0>
		<cfset session.basket.total.sales = 0>
		<cfset session.basket.total.supplies = 0>
		<cfset session.basket.total.prize = 0>
		<cfset session.basket.total.voucher = 0>
		<cfset session.basket.total.paystation = 0>
		<cfset session.basket.total.news = 0>
		<cfset session.basket.total.vat = 0>
		<cfset session.basket.total.discount = 0>
		<cfset session.basket.total.staff = 0>
	</cffunction>
	
	<cffunction name="LoadDeals" access="public" returntype="void" hint="Load deal info.">
		<cfargument name="args" type="struct" required="yes">
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
				"edType" = #edType#,
				"edDealType" = #edDealType#,
				"edTitle" = #edTitle#,
				"edQty" = #edQty#,
				"edAmount" = #edAmount#,
				"edStarts" = #LSDateFormat(edStarts,'yyyy-mm-dd')#,
				"edEnds" = #LSDateFormat(edEnds,'yyyy-mm-dd')#
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

	<cffunction name="CheckDeals" access="public" returntype="void" hint="check basket for qualifying deals.">
		<cfset var loc = {}>
		<cfloop collection="#session.basket.prodKeys#" item="loc.key">
			<cfset loc.item = StructFind(session.basket.prodKeys,loc.key)>
			<cfif loc.item.dealID gt 0>
				<cfset loc.deal = StructFind(session.dealdata,loc.item.dealID)>
				<cfif loc.item.qty gte loc.deal.edQty>
					<cfset loc.item.dealQty = loc.deal.edQty>
					<cfset loc.item.edAmount = loc.deal.edAmount>
					<cfswitch expression="#loc.deal.edDealType#">
						<cfcase value="nodeal">
						</cfcase>
						<cfcase value="bogof">
							<cfset loc.item.dealQty = int(loc.item.qty / 2)>
							<cfset loc.item.dealTotal = loc.item.dealQty * loc.item.unitPrice>
							<cfset loc.item.dealTitle = loc.deal.edTitle>
						</cfcase>
						<cfcase value="twofor">
							<cfset loc.item.dealQty = int(loc.item.qty / 2)>
							<cfset loc.item.remQty = loc.item.qty mod 2>
							<cfset loc.dealTotal = loc.item.dealQty * loc.deal.edAmount + (loc.item.remQty * loc.item.unitPrice)>
							<cfset loc.item.dealTotal = -(loc.item.totalGross + loc.dealTotal)>
							<cfset loc.item.dealTitle = "#loc.deal.edTitle# &pound;#loc.deal.edAmount#">
						</cfcase>
						<cfcase value="anyfor">
						</cfcase>
						<cfcase value="mealdeal">
						</cfcase>
						<cfcase value="halfprice">
						</cfcase>
					</cfswitch>
				<cfelse>
					<cfset loc.item.dealQty = 0>
					<cfset loc.item.dealTotal = 0>
					<cfset loc.item.dealTitle = ''>
					<cfset loc.item.dealDisc = 0>					
				</cfif>
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="UpdateBasket" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.insertItem = false>
		<cfset loc.discount = 0>
		<cfset loc.regMode = (2 * int(session.basket.mode eq "reg")) - 1>	<!--- modes: reg = 1 refund = -1 --->
		<cfset loc.tranType = -1>	<!--- probably all sales now --->
		
		<!--- sanitise input fields
		<cfset args.form.discount = 0>
		<cfset args.form.qty = val(args.form.qty)>
		<cfset args.form.cash = abs(val(args.form.cash))>
		<cfset args.form.credit = abs(val(args.form.credit))>
		<cfset args.form.vrate = val(args.form.vrate)> --->
		<cfset loc.vatRate = 1 + (args.form.vrate / 100)>
		<cfset session.basket.errMsg = "">

		<cfif StructKeyExists(session.basket.prodKeys,args.form.prodID)>
			<cfset loc.rec = StructFind(session.basket.prodKeys,args.form.prodID)>
			<cfset loc.oldNet = loc.rec.totalNet>
			<cfset loc.oldVAT = loc.rec.totalVAT>
			<cfset loc.oldGross = loc.rec.totalGross>
		<cfelse>
			<cfset loc.insertItem = true>
			<cfset loc.rec = {}>
			<cfset loc.rec.prodID = args.form.prodID>
			<cfset loc.rec.prodTitle = args.form.prodTitle>
			<cfset loc.rec.vrate = args.form.vrate>
			<cfset loc.rec.vcode = args.form.vcode>
			<cfset loc.rec.class = args.form.class>
			<cfset loc.rec.type = args.form.type>
			<cfset loc.rec.qty = 0>
			
			<cfset loc.oldNet = 0>
			<cfset loc.oldVAT = 0>
			<cfset loc.oldGross = 0>
			
		</cfif>
		
		<cfset loc.rec.dealID = 0>	<!--- clear any current deal --->
		<cfset loc.rec.unitPrice = args.form.cash + args.form.credit>
		<cfset loc.rec.qty += args.form.qty>		<!--- accumulate qty with any previous value. can be +/- --->

		<cfif loc.rec.qty lte 0>
			<cfset StructDelete(session.basket.prodKeys,args.form.prodID)>
		<cfelse>
			<cfset loc.cash = args.form.cash * loc.rec.qty * 100>		<!--- convert cash value to pence --->
			<cfset loc.credit = args.form.credit * loc.rec.qty * 100>	<!--- convert credit value to pence --->
			<cfset loc.gross = (loc.credit + loc.cash)>	<!--- remember original item pence value submitted regardless of cash/credit --->
			<cfif session.basket.staff AND StructKeyExists(args.form,"discountable")>	<!--- staff sale and is a discountable item --->
				<cfset loc.discount = round(loc.gross * session.till.prefs.discount)>	<!--- item discount in pence --->
			</cfif>	
			<cfset loc.rec.totalGross = loc.gross>	<!--- item pence value less any discount --->
			<!--- <cfset loc.rec.totalGross = (loc.gross - loc.discount)>	item pence value less any discount --->
	
			<cfset loc.rec.cash = loc.cash / 100>
			<cfset loc.rec.credit = loc.credit / 100>
			<cfset loc.rec.totalDisc = (loc.discount / 100)>	<!--- total discount given --->
			<cfset loc.rec.totalNet = round(loc.rec.totalGross / loc.vatRate) / 100> <!--- calc net value of item in pounds & pence --->
			<cfset loc.rec.totalGross = round(loc.rec.totalGross) / 100>	<!--- convert value to money --->
			<cfset loc.rec.totalVat = (loc.rec.totalGross - loc.rec.totalNet)> <!--- calc total vat amount --->
			
			<cfset loc.rec.cash = loc.rec.cash * loc.tranType * loc.regMode>
			<cfset loc.rec.credit = loc.rec.credit * loc.tranType * loc.regMode>
			<cfset loc.rec.totalNet = loc.rec.totalNet * loc.tranType * loc.regMode>
			<cfset loc.rec.totalGross = loc.rec.totalGross * loc.tranType * loc.regMode>
			<cfset loc.rec.totalVat = loc.rec.totalVat * loc.tranType * loc.regMode>
			<cfset loc.rec.totalDisc = loc.rec.totalDisc * loc.tranType * loc.regMode>
	
			<cfif loc.insertItem>	<!--- if item not in struct --->
				<cfset StructInsert(session.basket.prodKeys,args.form.prodID,loc.rec)>
				<cfset ArrayAppend(session.basket.products,args.form.prodID)>
			<cfelse>
				<cfset StructUpdate(session.basket.prodKeys,args.form.prodID,loc.rec)>
			</cfif>
									
			<cfif StructKeyExists(session.dealIDs,args.form.prodID)>
				<cfset loc.rec.dealID = StructFind(session.dealIDs,args.form.prodID)>
				<cfset CheckDeals()>
			</cfif>

			<cfif args.form.type eq "SRV"><cfset session.basket.service = args.form.credit></cfif>	<!--- remember if service charge added --->
			<cfset session.basket.total.sales += loc.rec.totalNet> <!--- accumulate net sales total --->
			<cfset session.basket.total.discount += loc.rec.totalDisc> <!--- accumulate discount granted --->
			<cfset session.basket.total.staff -= loc.rec.totalDisc> <!--- balance accounts --->
			<cfset session.basket.header.acctcash += loc.rec.cash> <!--- store cash sale amount --->
			<cfset session.basket.header.acctcredit += (loc.rec.totalNet - loc.oldNet)> <!--- store credit a/c amount --->
			<cfset session.basket.header.vat += (loc.rec.totalVat - loc.oldVAT)> <!--- accumulate VAT amounts --->
			<cfset session.basket.header.balance -= (loc.rec.totalGross - loc.oldGross)> <!--- accumulate customer balance --->

		</cfif>
		<cfdump var="#loc#" label="loc" expand="yes">
		<cfreturn loc.result>
	</cffunction>

	<cffunction name="ShowBasket" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.arrCount = 0>
		<cfset loc.total = 0>
		<cfset loc.netTotal = args.total.sales + args.total.prize + args.total.news + args.total.voucher + args.total.vat>
		<cfset session.basket.vatAnalysis = {}>
		<cfoutput>
			<table class="tableList" border="1">
				<tr>
					<td></td>
					<td>Description</td>
					<td>Qty</td>
					<td>Price</td>
					<td>Total</td>
				</tr>
				<cfloop collection="#session.basket.prodKeys#" item="key">
					<cfset loc.arrCount++>
					<cfset loc.item = StructFind(session.basket.prodKeys,key)>
					<cfset loc.total += loc.item.totalGross>
					<tr>
                    	<td><!---<a href="#cgi.SCRIPT_NAME#?mode=removeItem&amp;section=#loc.arr#&amp;row=#loc.arrCount#">#loc.arrCount#</a>---></td>
						<!---<td>#loc.item.type#<cfif loc.item.cash neq 0> (cash)</cfif></td>--->
						<td>#loc.item.prodTitle#</td>
						<td align="right">#loc.item.qty#</td>
						<td align="right">#DecimalFormat(loc.item.unitPrice)#</td>
						<td align="right">#DecimalFormat(-loc.item.totalGross)#</td>
					</tr>
					<cfif loc.item.dealID neq 0>
						<cfif loc.item.dealQty neq 0>
							<cfset loc.total += loc.item.dealTotal>
							<tr>
								<td></td>
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
				</cfloop>
				<tr>
					<td></td>
					<td colspan="3">Total</td>
					<td align="right">#DecimalFormat(-loc.total)#</td>
				</tr>
			</table>
		</cfoutput>
	</cffunction>
	
	<cffunction name="AddItem" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		
		<cfset session.temp.args = args>

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
		<cfset args.form.qty = abs(val(args.form.qty))>
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
                    <cfset session.basket.errMsg = "Cannot add a paystation item during a supplier transaction.">
                <cfelse>
                    <cfif args.form.cash neq 0>
                        <cfset args.form.class = "item">
                        <cfset args.form.account = 5>
                        <cfset args.form.title = "PayStation">
                        <cfset args.form.credit = 0>	<!--- force empty - only use cash figure --->
                        <cfset args.form.gross = args.form.cash>	<!--- calc gross transaction value --->
                        <cfset args.form.vat = 0>
                        <cfset args.form.discount = 0>
                        <cfset args.form.cash = args.form.cash * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
                        <cfset args.form.credit = args.form.credit * loc.tranType * loc.regMode>	<!--- apply mode & type to set sign correctly --->

                        <cfset session.basket.total.paystation += args.form.cash>	<!--- accumulate paystation total --->
                        <cfset session.basket.header.paystation += args.form.cash>
                        <cfset session.basket.header.balance -= args.form.cash>
                        <cfif args.form.addToBasket><cfset ArrayAppend(session.basket.paystation,args.form)></cfif> <!--- add item to payment array --->
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
                        <cfset args.form.cash = args.form.cash * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
                        <cfset args.form.credit = args.form.credit * loc.tranType * loc.regMode>	<!--- apply mode & type to set sign correctly --->

                        <cfset session.basket.total.prize += args.form.cash>	<!--- accumulate prize total --->
                        <cfset session.basket.header.prize += args.form.cash>
                        <cfset session.basket.header.balance -= args.form.cash>
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
                        <cfset args.form.cash = args.form.cash * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
                        <cfset args.form.credit = args.form.credit * loc.tranType * loc.regMode>	<!--- apply mode & type to set sign correctly --->

                        <cfset session.basket.total.voucher += args.form.cash>	<!--- accumulate voucher total --->
                        <cfset session.basket.header.voucher += args.form.cash>
                        <cfset session.basket.header.balance -= args.form.cash>
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
                        <cfset args.form.cash = args.form.cash * loc.tranType * loc.regMode> 		<!--- all form values are +ve numbers --->
                        <cfset args.form.credit = args.form.credit * loc.tranType * loc.regMode>	<!--- apply mode & type to set sign correctly --->

                        <cfset session.basket.total.news += args.form.credit + args.form.cash>	<!--- accumulate sales total --->
                        <cfset session.basket.header.acctcredit += args.form.credit>	<!--- store credit a/c amount --->
                        <cfset session.basket.header.acctcash += args.form.cash>	<!--- store cash sale amount --->
                        <cfset session.basket.header.balance -= (args.form.credit + args.form.cash)>
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

	<cffunction name="RemoveItem" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.result.err = "">
 		<cfset loc.parm = {}>
       <cfif StructKeyExists(session,"basket")>	<!--- session may have timed out --->
            <cfset loc.section = StructFind(session.basket,args.section)>
        	<cfif ArrayLen(loc.section) gte args.row>
				<cfset loc.parm.form = loc.section[args.row]>
                <cfif loc.parm.form.credit neq 0>
                	<cfset loc.parm.form.credit = loc.parm.form.gross + loc.parm.form.discount>
                <cfelse>
                	<cfset loc.parm.form.cash = loc.parm.form.gross + loc.parm.form.discount>
                </cfif>
				<cfset loc.parm.form.vat = 0>
				<cfset loc.parm.form.gross = 0>
                <cfset loc.parm.form.addToBasket = false>
				<cfif session.basket.mode IS "reg"><cfset session.basket.mode = "rfd"><cfelse><cfset session.basket.mode = "reg"></cfif>
                <cfset AddItem(loc.parm)>
                <cfset ArrayDeleteAt(StructFind(session.basket,args.section),args.row)>
				<cfset CalcTotals()>
				<cfif session.basket.mode IS "rfd"><cfset session.basket.mode = "reg"><cfelse><cfset session.basket.mode = "rfd"></cfif>
            </cfif>
        </cfif>
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

			<!--- payment methods --->
			<cfswitch expression="#args.form.btnSend#">
				<cfcase value="Cash">
					<cfif StructIsEmpty(session.basket.prodKeys)>		<!---( session.basket.items eq 0>--->
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
							<cfset args.form.cash = session.basket.header.balance * loc.tranType>	<!--- ignore any value passed in --->
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
							<cfset CloseTransaction()>
						<cfelseif session.basket.mode eq "rfd" AND session.basket.header.balance gte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
						<cfelse>
							<cfset CalcTotals()>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="Card">
					<cfset loc.cashBalance = session.basket.header.cashback + session.basket.header.cashTaken + session.basket.header.acctCash + 
						session.basket.header.prize + session.basket.header.voucher + args.form.cash>
					<cfif args.form.cash + args.form.credit is 0>
						<cfset args.form.credit = session.basket.header.balance * loc.tranType>
					</cfif>
						
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
						<cfset session.basket.errMsg = "Please enter the sale amount from the PayStation receipt.">
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
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
						<cfelseif session.basket.mode eq "rfd" AND session.basket.header.balance gte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
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
							<cfset CloseTransaction()>
						<cfelseif session.basket.mode eq "rfd" AND session.basket.header.balance gte 0>
							<cfset session.basket.header.change = session.basket.header.balance>
							<cfset session.basket.header.balance = 0>
							<cfset CalcTotals()>
							<cfset CloseTransaction()>
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
	
	<cffunction name="LoadTillTotals" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
			<h1>Loading till</h1>
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
		<cfset session.till.prevtran=session.basket>
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
					#args.header.acctCash + args.header.acctCredit#,
					#args.header.VAT#,
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

	<cffunction name="DumpTrans" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
			<cfquery name="loc.QTrans" datasource="#GetDataSource()#">
				SELECT *, tblProducts.prodTitle
				FROM tblEPOS_Items
				INNER JOIN tblEPOS_Header ON ehID = eiParent
				INNER JOIN tblProducts ON prodID = eiProdID
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
					<th>Description</th>
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
						<tr><td colspan="12">&nbsp;</td></tr>
					</cfif>
					<tr>
						<td>#eiParent#</td>
						<td>#ehMode#</td>
						<td>#eiID#</td>
						<td>#LSDateFormat(eiTimestamp)#</td>
						<td>#eiType#</td>
						<td align="center">#eiQty#</td>
						<td>#prodTitle#</td>
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
			output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
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
			<cfquery name="loc.QTrans" datasource="#GetDataSource()#">
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

	<cffunction name="ShowBasketOld" access="public" returntype="void">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.netTotal = args.total.sales + args.total.prize + args.total.news + args.total.voucher + args.total.vat>
		<cfset session.basket.vatAnalysis = {}>
		<cfoutput>
		<table class="tableList" border="1">
			<cfloop list="suppliers|products|news|prizes|vouchers" delimiters="|" index="loc.arr">
            	<cfset loc.arrCount = 0>
				<cfset loc.section = StructFind(args,loc.arr)>
				<cfloop array="#loc.section#" index="loc.item">
					<cfset loc.arrCount++>
					<tr>
                    	<td><a href="#cgi.SCRIPT_NAME#?mode=removeItem&amp;section=#loc.arr#&amp;row=#loc.arrCount#">#loc.arrCount#</a></td>
						<td>#loc.item.type#<cfif loc.item.cash neq 0> (cash)</cfif></td>
						<td>#loc.item.title#</td>
						<td>#loc.item.qty#</td>
						<td align="right">#DecimalFormat(loc.item.gross)#</td>
						<td align="right">#DecimalFormat(loc.item.gross * loc.item.qty)#</td>
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
				<td colspan="4">Total Items: #session.basket.items#</td>
                <td></td>
				<td align="right">#DecimalFormat(loc.netTotal)#</td>
			</tr>
			<cfloop list="payments" delimiters="|" index="loc.arr">
				<cfset loc.section = StructFind(args,loc.arr)>
				<cfloop array="#loc.section#" index="loc.item">
					<tr>
						<td>#loc.item.type#<cfif loc.item.cash neq 0> (cash)</cfif></td>
						<td>#loc.item.title#</td>
                        <td></td>
						<td align="right">#DecimalFormat(loc.item.cash + loc.item.credit)#</td>
					</tr>
				</cfloop>
			</cfloop>
			<cfif session.basket.header.balance lte 0>
				<tr>
					<td colspan="5" width="220">Balance Due to #session.basket.bod#</td><td align="right">#DecimalFormat(session.basket.header.balance)#</td>
				</tr>
			<cfelse>
				<tr>
					<td colspan="5" width="220">Balance Due from #session.basket.bod#</td><td align="right">#DecimalFormat(session.basket.header.balance)#</td>
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
						<cfloop array="#args.products#" index="loc.prod">
							<cfset loc.item = StructFind(args.prodKeys,loc.prod)>
							<tr>
								<td>SALE <cfif loc.item.cash neq 0>(cash)</cfif></td>
								<td>#loc.item.prodTitle#</td>
								<td align="right">#DecimalFormat(loc.item.totalGross * loc.invert)#</td>
								<td>#loc.item.vrate#</td>
							</tr>
						</cfloop>
						
						<cfloop list="suppliers|news|prizes|vouchers" delimiters="|" index="loc.arr">
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
				SELECT DATE(ehTimeStamp) AS dateOnly
				FROM tblEPOS_Header
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
	
	<cffunction name="LoadVAT" access="public" returntype="void">
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
	</cffunction>
	
	<cffunction name="LoadProducts" access="public" returntype="query">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
			<cfquery name="loc.QProducts" datasource="#GetDataSource()#" result="loc.QProductsResult">
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly
				FROM tblProducts
				WHERE prodLastBought > '2015-09-01'
				LIMIT 15)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly
				FROM tblProducts
				WHERE prodLastBought > '2015-09-01'
				AND prodVatRate <> 0
				LIMIT 15)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly
				FROM tblProducts
				WHERE prodLastBought > '2015-09-01'
				AND prodVatRate = 5
				LIMIT 5)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly
				FROM tblProducts
				WHERE prodSuppID != 21
				LIMIT 20)				
			</cfquery>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.QProducts>
	</cffunction>
	
<!--- main --->
<cfset receipt = false>
<cfparam name="mode" default="0">
<cfif NOT StructKeyExists(session,"till")>
	<cfset parm = {}>
	<cfset parm.form.reportDate = LSDateFormat(Now(),"yyyy-mm-dd")>
	<cfset LoadTillTotals(parm)>
	<cfset LoadDeals(parm)>
	<cfset LoadVAT(parm)>
	<cfset session.products = LoadProducts(parm)>
</cfif>
<cfif mode neq 0>
	<cfswitch expression="#mode#">
		<cfcase value="reg">
			<cfset session.basket.mode = "reg">
		</cfcase>
		<cfcase value="rfd">
			<cfset session.basket.mode = "rfd">
		</cfcase>
		<cfcase value="staff">
			<cfset session.basket.staff = !session.basket.staff>
		</cfcase>
		<cfcase value="removeItem">
			<cfset RemoveItem(url)>
		</cfcase>
		<cfcase value="destroy">
			<cfset StructDelete(session,"till",false)>
		</cfcase>
		<cfcase value="ztill">
			<cfset ZTill(Now())>
		</cfcase>
		<cfcase value="clear">
			<cfset ClearBasket()>
		</cfcase>
	</cfswitch>
	<cflocation url="#cgi.SCRIPT_NAME#" addtoken="no">
</cfif>

<cfif StructKeyExists(form,"fieldnames")>
	<cfset parm = {}>
	<cfset parm.form = StructCopy(form)>
	<cfif StructKeyExists(parm.form,"reportDate")>
		<cfset LoadTillTotals(parm)>
		<cflocation url="#cgi.SCRIPT_NAME#" addtoken="no">
	<cfelse>
		<cfswitch expression="#parm.form.vrate#">
			<cfcase value="20.00">
				<cfset parm.form.vcode = 2>
			</cfcase>
			<cfcase value="0.00">
				<cfset parm.form.vcode = 1>
			</cfcase>
			<cfcase value="5.00">
				<cfset parm.form.vcode = 3>
			</cfcase>
			<cfdefaultcase>
				<cfset parm.form.vcode = 0>
			</cfdefaultcase>
		</cfswitch>
		<cfswitch expression="#parm.form.btnSend#">
			<cfcase value="Add">
				<cfset AddItem(parm)>
			</cfcase>
			<cfcase value="Cash|Card|Cheque|Account" delimiters="|">
				<cfset AddPayment(parm)>
			</cfcase>
		</cfswitch>
		<!---<cflocation url="#cgi.SCRIPT_NAME#" addtoken="no">--->
	</cfif>
</cfif>

<cfset customers = GetAccounts(session.basket)>
<cfset dates = GetDates(session.basket)>

<cfoutput>
<body>
	<div id="tillpanel">
		<div id="ctrls">
			<a href="?mode=destroy">Destroy</a> &nbsp; 
			<a href="?mode=reg">Reg Mode</a> &nbsp; 
			<a href="?mode=rfd">Refund Mode</a> &nbsp; 
			<a href="?mode=clear">Clear Basket</a> &nbsp; 
			<a href="?mode=ztill">Z Till</a> &nbsp; 
			<a href="?mode=staff">Staff</a> &nbsp; 
			<span><cfif session.basket.staff> Staff &nbsp; </cfif></span>
			<span id="mode" class="#session.basket.mode#">#session.basket.mode# MODE</span>
		</div>
		<form name="basket" method="post" enctype="multipart/form-data">
			<div style="width:100%">
				<select name="type" id="productType">
					<option value="">Select...</option>
					<cfloop query="session.products">
						<option value="prod-#prodID#" data-price="#prodOurPrice#" data-cashonly="#prodCashOnly#" data-title="#prodTitle#" data-vatrate="#prodVATRate#">
							#prodCashOnly# - #prodID# - #Left(prodTitle,20)# #prodOurPrice# #prodVatRate#%</option>
					</cfloop>
	<!---
					<option value="SALE">Sale (VATable)</option>
					<option value="SALEZ">Sale (non-VATable)</option>
					<option value="SALEL">Sale (Low-VAT)</option>
	--->
					<option value="PRIZE" data-price="" data-cashonly="1" data-title="Prize">1 - Prize</option>
					<option value="VCHN" data-price="" data-cashonly="0" data-title="News Voucher">0 - News Voucher</option>
					<option value="NEWS" data-price="" data-cashonly="0" data-title="News Account">0 - News Account</option>
					<option value="SUPP" data-price="" data-cashonly="1" data-title="Supplier Payment">1 - Supplier Payment</option>
					<option value="SRV" data-price="0.50" data-cashonly="0" data-title="Service Charge">0 - Service Charge</option>
					<option value="PS" data-price="" data-cashonly="1" data-title="PayStation">1 - PayStation</option>
				</select>
				<br>
				<input name="addToBasket" type="hidden" value="true" />
				<input name="prodTitle" id="prodTitle" type="hidden" value="" />
				<input name="vrate" id="prodVATRate" type="hidden" value="" />
				Qty: <input type="text" name="qty" id="qty" size="2" value="1" />
				Credit: <input type="text" name="credit" id="credit" size="5" />
				Cash: <input type="text" name="cash" id="cash" size="5" />
				<input type="submit" name="btnSend" class="addBtn" value="Add" /><br>
				<input type="checkbox" name="discountable" />Discountable
				<div style="clear:both"></div>
			</div>
			<div style="width:460px; margin:auto; margin-top:10px; padding:10px; border:solid 2px ##ccc; background:##999999;">
				<input type="submit" name="btnSend" class="pay cash" value="Cash" />
				<input type="submit" name="btnSend" class="pay" value="Card" />
				<input type="submit" name="btnSend" class="pay" value="Cheque" />
				<input type="submit" name="btnSend" class="pay" value="Account" />
				<select name="account">
					<option value="">Select account...</option>
					<cfloop query="customers.accounts">
						<option value="#accID#">#accName#</option>
					</cfloop>
				</select>
			</div>
			<div id="errMsg">Msg : #session.basket.errMsg#</div>
		</form>
		<form method="post" enctype="multipart/form-data">
			Report Date: 
			<select name="reportDate" id="reportDate">
				<option value="">Select date...</option>
				<cfloop array="#dates.recs#" index="item">
					<option value="#item.value#" <cfif session.till.prefs.reportDate eq item.value> selected</cfif>>#item.title#</option>
				</cfloop>
			</select>
			<input type="submit" name="btnGo" value="Go">
		</form>
		<div id="loading"></div>
	</div>
	
	<div style="float:left; margin:10px;">
		<div class="header">Basket</div>
		<cfset ShowBasket(session.basket)>
	</div>
	<div style="clear:both"></div>
	
<!---
	<div style="float:left; margin:10px;">
		<cfif ArrayLen(session.till.trans) gt 0>
			<div class="header">Transaction List</div>
			<cfset receipt = PrintTransactionList(session.till.trans,session.till.header)>
			<cfset tranID = ArrayLen(session.till.trans)>
		</cfif>
	</div>
	<div style="clear:both"></div>
--->
	<div id="xreading" style="float:left; margin:10px;">
		<div class="header">Till Balance</div>
		<table class="tableList" border="1">
			<tr>
				<th>DESCRIPTION</th>
				<th width="70" align="right">DR</th>
				<th width="70" align="right">CR</th>
			</tr>
			<cfset drTotal = 0>
			<cfset crTotal = 0>
			<cfset loopcount = 0>
			<cfset keys = ListSort(StructKeyList(session.till.total,","),"text","ASC",",")>
			<cfloop list="#keys#" index="fld">
				<tr>
					<td>#fld#</td>
					<td align="right">
						<cfif session.till.total[fld] gt 0>
							<cfset drTotal += session.till.total[fld]>
							#DecimalFormat(session.till.total[fld])#
						</cfif>
					</td>
					<td align="right">
						<cfif session.till.total[fld] lt 0>
							<cfset crTotal -= session.till.total[fld]>
							#DecimalFormat(session.till.total[fld] * -1)#
						</cfif>
					</td>
				</tr>
			</cfloop>
			<tr>
				<td><strong>Totals</strong></td>
				<td align="right"><strong>#DecimalFormat(drTotal)#</strong></td>
				<td align="right"><strong>#DecimalFormat(crTotal)#</strong></td>
			</tr>
		</table>
	</div>
	
	<div id="xreading2" style="float:left; margin:10px;">
		<div class="header">Transaction Totals Balance</div>
		<table class="tableList" border="1">
			<tr>
				<th>DESCRIPTION</th>
				<th width="70" align="right">DR</th>
				<th width="70" align="right">CR</th>
			</tr>
			<cfset drTotal = 0>
			<cfset crTotal = 0>
			<cfset loopcount = 0>
			<cfset keys = ListSort(StructKeyList(session.till.header,","),"text","ASC",",")>
			<cfloop list="#keys#" index="fld">
				<tr>
					<td>#fld#</td>
					<td align="right">
						<cfif session.till.header[fld] gt 0>
							<cfset drTotal += session.till.header[fld]>
							#DecimalFormat(session.till.header[fld])#
						</cfif>
					</td>
					<td align="right">
						<cfif session.till.header[fld] lt 0>
							<cfset crTotal -= session.till.header[fld]>
							#DecimalFormat(session.till.header[fld] * -1)#
						</cfif>
					</td>
				</tr>
			</cfloop>
			<tr>
				<td><strong>Totals</strong></td>
				<td align="right"><strong>#DecimalFormat(drTotal)#</strong></td>
				<td align="right"><strong>#DecimalFormat(crTotal)#</strong></td>
			</tr>
		</table>
	</div>
<!---	
	<cfif ArrayLen(session.till.trans) gt 0>
		<cfset PrintReceipt(receipt,tranID)>
	</cfif>
	<div style="clear:both"></div>
--->
	<div style="float:left; margin:10px;">
		<div class="header">Tran Dump</div>
		<cfset DumpTrans(session.basket)>
	</div>
	<div style="clear:both"></div>
	
	<div style="float:left; margin:10px;">
		<div class="header">Tran Report</div>
		<cfset totals = TranReport(session.basket)>
	</div>	
	<div style="clear:both"></div>
	

	<div style="float:left; margin:10px;">
		<cfdump var="#session#" label="session" expand="no">
	</div>

</body>
</cfoutput>
</html>