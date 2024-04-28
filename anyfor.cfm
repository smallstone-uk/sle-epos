<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Any For</title>
</head>

<cfset loc = {}>
<body>
	<cfoutput>
		<cfif StructKeyExists(session,"basket")>
			<cfset loc.tranType = -1>
			<cfset loc.rec.regMode = (2 * int(session.basket.info.mode neq "rfd")) - 1>	<!--- modes: reg = 1 waste = 1 refund = -1 --->
			<cfloop collection="#session.basket.deals#" item="loc.dealKey">
				<cfset loc.dealData = StructFind(session.dealData,loc.dealKey)>
				<cfset loc.dealRec = StructFind(session.basket.deals,loc.dealKey)>
				<cfset loc.dealRec.VATTable = {}>
				<cfset loc.dealRec.dealQty = 0>
				<cfset loc.dealRec.netTotal = 0>
				<cfset loc.dealRec.dealTotal = 0>
				<cfset loc.dealRec.groupRetail = 0>
				<cfset loc.dealRec.savingGross = 0>
				<cfset loc.dealRec.lastQual = 0>
				<cfset loc.dealRec.remQty = 0>
				<cfset ArraySort(loc.dealRec.prices,"text","ASC")>
				<cfset loc.count = 0>
				<cfset loc.start = 1>
				<cfset loc.trans = []>
				<cfif loc.dealData.edEnds gt Now()>
					<cfswitch expression="#loc.dealData.edDealType#">
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
										<cfset loc.tran.price = loc.data.unitprice>
										<cfset loc.tran.prop = loc.tran.price / loc.dealRec.groupRetail>
										
										<cfset loc.tran.gross = Round(loc.dealData.edAmount * loc.tran.prop * 100) / 100>
										<cfset loc.tran.net = Round(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
										<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
										
										<cfset loc.tran.gross = loc.tran.gross * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.net = loc.tran.net * loc.tranType * loc.rec.regMode>
										<cfset loc.tran.vat = loc.tran.vat * loc.tranType * loc.rec.regMode>
										
										<cfset ArrayAppend(loc.trans,loc.tran)>
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
									<cfset loc.data.discount = 0>
									<cfset loc.tran.cashonly = loc.data.cash neq 0>
									<cfif session.till.info.staff AND loc.data.discountable>	<!--- staff sale and is a discountable item --->
										<cfset loc.itemDiscount = round(loc.data.unitPrice * 100 * session.till.prefs.discount) / 100>
										<cfset loc.data.discount = loc.itemDiscount * loc.data.qty>
									</cfif>
									
									<cfset loc.tran.prop = 1>
									<cfset loc.tran.vrate = loc.data.vrate>
									<cfset loc.tran.vcode = loc.data.vcode>
									<cfset loc.tran.itemClass = loc.data.itemClass>
									<cfset loc.tran.price = loc.data.unitPrice>
									<cfset loc.tran.gross = Round((loc.tran.price - loc.itemDiscount) * 100) / 100>
									<cfset loc.tran.net = Round(loc.tran.gross / (1 + (loc.tran.vrate / 100)) * 100) / 100>
									<cfset loc.tran.vat = loc.tran.gross - loc.tran.net>
										
									<cfset loc.tran.gross = loc.tran.gross * loc.tranType * loc.rec.regMode>
									<cfset loc.tran.net = loc.tran.net * loc.tranType * loc.rec.regMode>
									<cfset loc.tran.vat = loc.tran.vat * loc.tranType * loc.rec.regMode>
										
									<cfset ArrayAppend(loc.trans,loc.tran)>
								</cfloop>
							</cfif>
						</cfcase>
					</cfswitch>
				</cfif>
			</cfloop>
			<cfdump var="#loc#" label="loc" expand="true">
		</cfif>
	</cfoutput>
</body>
</html>