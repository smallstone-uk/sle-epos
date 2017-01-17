
<!DOCTYPE HTML>
<html>
<head>
	<meta charset="utf-8">
	<title>EPOS-15</title>
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<script src="js/jquery-1.11.1.min.js"></script>
	<script src="js/epos.js"></script>
	<script>
		$(document).ready(function() {
			$.scanBarcode({
				unbindOnCallback: false,
				preinit: function() {
					window["barcode"] = "";
					$(document).unbind("keypress.scanBarcodeEvent");
				},
				callback: function(barcode) {
					console.log(barcode);
					$.ajax({
						type: "POST",
						url: "ajax/apps/fn/post_loadProductByBarcode.cfm",
						data: { "barcode": barcode },
						success: function(data) {
							var result = JSON.parse(data);
								$('#errMsg').html(result);
							if (result.MSG) {
								$('#errMsg').html(result.MSG);
							} else {
								if (result.PRODID && result.PRODTITLE) {
									$('#itemClass').val(result.EPCKEY);
									$('#prodID').val(result.PRODID);
									$('#prodTitle').val(result.PRODTITLE);
									$('#prodVATRate').val(result.PRODVATRATE);
									$('#cashOnly').val(result.PRODCASHONLY);
									$('#credit').val(result.SIOURPRICE);
									$('#prodSign').val(result.PRODSIGN);
									$('#prodClass').val(result.PRODCLASS);
									$('#discountable').prop('checked', result.PRODSTAFFDISCOUNT);
								} else if (result.PUBID && result.PUBTITLE) {
									$('#itemClass').val(result.EPCKEY);
									$('#pubID').val(result.PUBID);
									$('#pubTitle').val(result.PUBTITLE);
									$('#prodVATRate').val(result.PUBVATCODE);
									$('#cashOnly').val(0);
									$('#credit').val(result.PUBPRICE);							
									$('#prodSign').val(1);
								}
								$('#basket').append('<input type="hidden" name="btnSend" id="btnSend" value="Add" />');
								$('#basket').submit();
							}
						}
					});
				}
			});

			$('#product').change(function(e) {
				$("#publication").val([]);
				var mydata = $(this).children('option:selected').data();
				console.log(mydata);
				$('#prodID').val(mydata.prodid);
				$('#pubID').val(0);
				$('#itemClass').val(mydata.epckey);
				$('#prodTitle').val(mydata.title);
				$('#prodVATRate').val(mydata.vatrate);
				$('#cashOnly').val(mydata.cashonly);
				$('#prodSign').val(mydata.sign);
				$('#prodClass').val(mydata.prodClass);
				$('#discountable').prop('checked', mydata.staffdiscount == "Yes");
				if (mydata.cashonly) {
					$('#cash').val(mydata.price);
					$('#credit').val("");
				} else {
					$('#cash').val("");
					$('#credit').val(mydata.price);
				}
			}); 
			
			$('#publication').change(function(e) {
				$("#product").val([]);
				var mydata = $(this).children('option:selected').data();
				console.log(mydata);
				$('#prodID').val(0);
				$('#pubID').val(mydata.pubid);
				$('#itemClass').val(mydata.epckey);
				$('#pubTitle').val(mydata.title);
				$('#prodVATRate').val(mydata.vatrate);
				$('#cashOnly').val(mydata.cashonly);
				$('#prodSign').val(mydata.sign);
				if (mydata.cashonly) {
					$('#cash').val(mydata.price);
					$('#credit').val("");
				} else {
					$('#cash').val("");
					$('#credit').val(mydata.price);
				}
			});
			$('.pay').click(function(e) {
				var payID = $(this).attr('data-id');
				$('#payID').val(payID);
				console.log("payid " + payID);
			});
		});
	</script>
</head>

	<cffunction name="LoadProducts" access="public" returntype="query">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cftry> 
			<cfquery name="loc.QProducts" datasource="#args.datasource#" result="loc.QProductsResult">
				(SELECT prodID,prodRef,prodTitle,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign,prodOurPrice,prodClass, siOurPrice, epcKey
				FROM tblProducts
				LEFT JOIN tblStockItem ON prodID = siProduct
				AND tblStockItem.siID = (
					SELECT MAX( siID )
					FROM tblStockItem
					WHERE prodID = siProduct )
				INNER JOIN tblEPOS_Cats ON prodEposCatID=epcID
				INNER JOIN tblEPOS_DealItems ON ediProduct=prodID
				WHERE prodLastBought > '2016-07-01'
				)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign,prodOurPrice,prodClass, siOurPrice, epcKey
				FROM tblProducts
				LEFT JOIN tblStockItem ON prodID = siProduct
				AND tblStockItem.siID = (
					SELECT MAX( siID )
					FROM tblStockItem
					WHERE prodID = siProduct )
				INNER JOIN tblEPOS_Cats ON prodEposCatID=epcID
				WHERE prodLastBought > '2016-07-01'
				LIMIT 15)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign,prodOurPrice,prodClass, siOurPrice, epcKey
				FROM tblProducts
				LEFT JOIN tblStockItem ON prodID = siProduct
				AND tblStockItem.siID = (
					SELECT MAX( siID )
					FROM tblStockItem
					WHERE prodID = siProduct )
				INNER JOIN tblEPOS_Cats ON prodEposCatID=epcID
				WHERE prodLastBought > '2016-07-01'
				AND prodVatRate <> 0
				LIMIT 15)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign,prodOurPrice,prodClass, siOurPrice, epcKey
				FROM tblProducts
				LEFT JOIN tblStockItem ON prodID = siProduct
				AND tblStockItem.siID = (
					SELECT MAX( siID )
					FROM tblStockItem
					WHERE prodID = siProduct )
				INNER JOIN tblEPOS_Cats ON prodEposCatID=epcID
				WHERE prodLastBought > '2016-07-01'
				AND prodVatRate = 5
				LIMIT 5)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign,prodOurPrice,prodClass, siOurPrice, epcKey
				FROM tblProducts
				LEFT JOIN tblStockItem ON prodID = siProduct
				AND tblStockItem.siID = (
					SELECT MAX( siID )
					FROM tblStockItem
					WHERE prodID = siProduct )
				INNER JOIN tblEPOS_Cats ON prodEposCatID=epcID
				WHERE prodSuppID != 21
				LIMIT 20)
				UNION	
				(SELECT prodID,prodRef,prodTitle,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign,prodOurPrice,prodClass, siOurPrice, epcKey
				FROM tblProducts
				LEFT JOIN tblStockItem ON prodID = siProduct
				AND tblStockItem.siID = (
					SELECT MAX( siID )
					FROM tblStockItem
					WHERE prodID = siProduct )
				INNER JOIN tblEPOS_Cats ON prodEposCatID=epcID
				WHERE prodSuppID = 0
				AND prodEposCatID IN (42,142,152,161,171,181,191,122,221,241,251,261) )
			</cfquery>
			<cfreturn loc.QProducts>
			
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="LoadPapers" access="public" returntype="query">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry> 
			<cfquery name="loc.QPapers" datasource="#args.datasource#">
				SELECT pubID,pubTitle,pubPrice,pubTradePrice, 'MEDIA' AS epcKey
				FROM `tblPublication` 
				WHERE `pubGroup` = 'News' 
				AND `pubEPOS` = 1
			</cfquery>
			<cfreturn loc.QPapers>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="FillBasket" access="public" returntype="void">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.prodIDs = "511,27562,2041,6201,8121,21411,21481,25872,25882,33002,28402,28622,42651">
		<cfset loc.price = 9.00>
		<cftry>
			<cfloop list="#loc.prodIDs#" delimiters="," index="loc.pID">
				<cfquery name="loc.QProduct" datasource="#GetDataSource()#">
					SELECT prodID,prodSign,prodTitle,prodCashOnly,prodStaffDiscount,prodVATRate,prodClass, siOurPrice, epcKey
					FROM tblProducts
					LEFT JOIN tblStockItem ON prodID = siProduct
					AND tblStockItem.siID = (
						SELECT MAX( siID )
						FROM tblStockItem
						WHERE prodID = siProduct )
					INNER JOIN tblEPOS_Cats ON prodEposCatID=epcID
					WHERE prodID=#val(loc.pID)#
				</cfquery>
				<cfloop query="loc.QProduct">
					<cfset loc.rec = {}>
					<cfset loc.parm = {}>
					<cfset loc.rec.account = "">
					<cfset loc.rec.addToBasket = true>
					<cfset loc.rec.btnSend = "Add">
					<cfset loc.rec.cashOnly = prodCashOnly>
					<cfset loc.rec.discountable = prodStaffDiscount>
					<cfif prodCashOnly>
						<cfif val(siOurPrice) neq 0>
							<cfset loc.rec.cash = siOurPrice>
						<cfelse>
							<cfset loc.rec.cash = loc.price>
							<cfset loc.price-->
						</cfif>
						<cfset loc.rec.credit = 0>
					<cfelse>
						<cfif val(siOurPrice) neq 0>
							<cfset loc.rec.credit = siOurPrice>
						<cfelse>
							<cfset loc.rec.credit = loc.price>
							<cfset loc.price-->
						</cfif>
						<cfset loc.rec.cash = 0>
					</cfif>
					<cfset loc.rec.itemClass = epcKey>
					<cfset loc.rec.prodID = prodID>
					<cfset loc.rec.prodSign = prodSign>
					<cfset loc.rec.prodTitle = prodTitle>
					<cfset loc.rec.vrate = prodVATRate>
					<cfset loc.rec.pubID = 0>
					<cfset loc.rec.publication = "">
					<cfset loc.rec.pubTitle = "">
					<cfset loc.rec.qty = 1>
					<cfset loc.rec.prodClass=prodClass>
					<cfset loc.parm.form = loc.rec>
					<cfset ecfc.AddItem(loc.parm)>
				</cfloop>
			</cfloop>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="Destroy" access="public" returntype="void">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cftry>
			<cfquery name="loc.QDeleteTotals" datasource="#GetDataSource()#">
				DELETE FROM tblEPOS_Totals
				WHERE totDate = '#session.till.prefs.reportdate#'
			</cfquery>
			<cfquery name="loc.QDeleteHeaders" datasource="#GetDataSource()#">
				DELETE FROM tblEPOS_Header
				WHERE DATE(ehTimeStamp) = '#session.till.prefs.reportdate#'
			</cfquery>
			<cfset StructDelete(session,"till",false)>
			<cfset StructDelete(session,"products",false)>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>

<cfobject component="#application.site.codePath#" name="ecfc">
<cfparam name="mode" default="0">
<cfif NOT StructKeyExists(session,"till")>
	<cfset parm = {}>
	<cfset parm.datasource = GetDataSource()>
	<cfset parm.form.reportDate = LSDateFormat(Now(),"yyyy-mm-dd")>
	<cfset ecfc.LoadTillTotals(parm)>
	<cfset ecfc.LoadDeals(parm)>
	<cfset ecfc.LoadVAT()>
	<cfset ecfc.LoadCatKeys()>
</cfif>
<cfif NOT StructKeyExists(session,"products")>	<!--- load test products --->
	<cfset parm = {}>
	<cfset parm.datasource = GetDataSource()>
	<cfset parm.form.reportDate = LSDateFormat(Now(),"yyyy-mm-dd")>
	<cfset session.products = LoadProducts(parm)>
	<cfset session.papers = LoadPapers(parm)>
	<cfset session.customers = ecfc.GetAccounts(parm)>
	<cfset session.dates = ecfc.GetDates(parm)>
</cfif>
<cfif mode neq 0>
	<cfswitch expression="#mode#">
		<cfcase value="reg">
			<cfset session.basket.info.mode = "reg">
		</cfcase>
		<cfcase value="rfd">
			<cfset session.basket.info.mode = "rfd">
		</cfcase>
		<cfcase value="staff">
			<cfset session.till.info.staff = !session.till.info.staff>
		</cfcase>
		<cfcase value="removeItem">
			<cfset RemoveItem(url)>
		</cfcase>
		<cfcase value="destroy">
			<cfset Destroy()>
		</cfcase>
		<cfcase value="reload">
			<cfset parm = {}>
			<cfset parm.datasource = GetDataSource()>
			<cfset ecfc.LoadDeals(parm)>
		</cfcase>
		<cfcase value="ztill">
			<cfset ecfc.ZTill(Now())>
		</cfcase>
		<cfcase value="fill">
			<cfset FillBasket()>
		</cfcase>
		<cfcase value="clear">
			<cfset ecfc.ClearBasket()>
		</cfcase>
	</cfswitch>
	<cflocation url="#cgi.SCRIPT_NAME#" addtoken="no">
</cfif>

<cfif StructKeyExists(form,"fieldnames")>
	<cfset parm = {}>
	<cfset parm.form = StructCopy(form)>
	<cfif StructKeyExists(parm.form,"reportDate")>
		<cfset ecfc.LoadTillTotals(parm)>
		<cflocation url="#cgi.SCRIPT_NAME#" addtoken="no">
	<cfelse>
		<cfswitch expression="#parm.form.btnSend#">
			<cfcase value="Add" delimiters="|">
				<cfset ecfc.AddItem(parm)>
			</cfcase>
			<cfcase value="Cash|Card|Cheque|Account|Voucher|Coupon" delimiters="|">
				<cfset ecfc.AddPayment(parm)>
			</cfcase>
		</cfswitch>
		<!---<cflocation url="#cgi.SCRIPT_NAME#" addtoken="no">--->
	</cfif>
</cfif>

<body>
<cfoutput>
	<div id="tillpanel">
		<div id="ctrls">
			<a href="?mode=destroy">Destroy</a> &nbsp; 
			<a href="?mode=reg">Register</a> &nbsp; 
			<a href="?mode=rfd">Refund</a> &nbsp; 
			<a href="?mode=clear">Clear Basket</a> &nbsp; 
			<a href="?mode=fill">Fill</a> &nbsp; 
			<a href="?mode=ztill">Z Till</a> &nbsp; 
			<a href="?mode=staff">Staff</a> &nbsp; 
			<span><cfif session.till.info.staff> Staff &nbsp; </cfif></span>
			<span id="mode" class="#session.basket.info.mode#">#session.basket.info.mode# MODE</span>
		</div>
		<form name="basket" id="basket" method="post" enctype="multipart/form-data">
			<div style="width:100%">
				Products:
				<select name="product" id="product">
					<option value="">Select...</option>
					<cfloop query="session.products">
						<cfif val(siOurPrice) neq 0><cfset itemPrice = siOurPrice>
							<cfelse><cfset itemPrice = prodOurPrice></cfif>
						<option value="#prodID#" data-price="#itemPrice#" data-cashonly="#prodCashOnly#" data-epckey="#epcKey#" data-sign="#prodSign#" data-prodid="#prodID#"
							data-staffDiscount="#prodStaffDiscount#" data-title="#prodTitle#" data-vatrate="#prodVATRate#" data-prodClass="#prodClass#">
							#prodCashOnly# - #prodStaffDiscount# - #prodID# - #epcKey# - #Left(prodTitle,20)# - #itemPrice# - #prodVatRate#%</option>
					</cfloop>
				</select>
				<br>
				Newspapers: 
				<select name="publication" id="publication">
					<option value="">Select...</option>
					<cfloop query="session.papers">
						<option value="#pubID#" data-price="#pubPrice#" data-cashonly="0" data-staffDiscount="1" data-epckey="#epcKey#" data-pubID="#pubID#"
							data-title="#pubTitle#" data-sign="1" data-vatrate="0" data-prodClass="multiple">
							0 - 1 - #pubID# - #epcKey# - #Left(pubTitle,20)# - #pubPrice# - 0%</option>
					</cfloop>
				</select>
				<br>
				<input name="addToBasket" type="hidden" value="true" />
				<input name="prodID" id="prodID" type="hidden" value="" />
				<input name="pubID" id="pubID" type="hidden" value="" />
				<input name="payID" id="payID" type="text" size="3" value="" />
				<input name="itemClass" id="itemClass" type="hidden" value="" />
				<input name="vrate" id="prodVATRate" type="hidden" value="" />
				<input name="cashOnly" id="cashOnly" type="hidden" value="" />
				<div style="width:460px; margin:auto; margin-top:10px; padding:10px; ">
					Qty: <input type="text" name="qty" id="qty" size="2" value="1" />
					Credit: <input type="text" name="credit" id="credit" size="5" />
					Cash: <input type="text" name="cash" id="cash" size="5" />
					<input type="checkbox" name="discountable" id="discountable" />Discountable
					<input type="submit" name="btnSend" id="btnSend" class="addBtn" value="Add" />
				</div>
				<input name="prodSign" id="prodSign" type="text" value="1" size="3" />
				<input name="prodTitle" id="prodTitle" type="text" value="" />
				<input name="prodClass" id="prodClass" type="text" value="" size="3" />
				<input name="pubTitle" id="pubTitle" type="text" value="" />
				<div style="clear:both"></div>
			</div>
			<div style="width:480px; margin:auto; margin-top:10px; padding:10px; border:solid 2px ##ccc; background:##999999;">
				<cfloop array="#session.customers.btns#" index="btn">
					<cfif btn.eaTitle eq "cash"><cfset btnClass="pay cash"><cfelse><cfset btnClass="pay"></cfif>
					<input type="submit" name="btnSend" class="#btnClass#" value="#btn.eaTitle#" data-id="#btn.eaID#" />
				</cfloop>
				<select name="account">
					<option value="">Select account...</option>
					<cfloop array="#session.customers.accts#" index="acc">
						<option value="#acc.eaID#" data-id="#btn.eaID#">#acc.eaTitle#</option>
					</cfloop>
				</select>
			</div>
			<div id="errMsg">Msg : #session.basket.info.errMsg#</div>
		</form>
		<form method="post" enctype="multipart/form-data">
			Report Date: 
			<select name="reportDate" id="reportDate">
				<option value="">Select date...</option>
				<cfloop array="#session.dates.recs#" index="item">
					<option value="#item.value#" <cfif session.till.prefs.reportDate eq item.value> selected</cfif>>#item.title#</option>
				</cfloop>
			</select>
			<input type="submit" name="btnGo" value="Go">
			<a href="?mode=reload">Reload Deals</a>
		</form>
		<div id="loading"></div>
	</div>
</cfoutput>

<div style="float:left; margin:0 0 0 10px;">
	<div class="header">Basket</div>
	<cfset receipt = ecfc.ShowBasket()>
	<cfset ecfc.ShowTrans(session.basket)>
</div>
<div style="clear:both"></div>

<cfoutput>
	<div id="xreading1" class="totalPanel">
		<div class="header">Basket Header</div>
		<table class="tableList" border="1">
			<tr>
				<th>DESCRIPTION</th>
				<th width="70" align="right">DR</th>
				<th width="70" align="right">CR</th>
			</tr>
			<cfset drTotal = 0>
			<cfset crTotal = 0>
			<cfset loopcount = 0>
			<cfset keys = ListSort(StructKeyList(session.basket.header,","),"text","ASC",",")>
			<cfloop list="#keys#" index="fld">
				<tr>
					<td>#fld#</td>
					<td align="right">
						<cfif session.basket.header[fld] gt 0>
							<cfset drTotal += session.basket.header[fld]>
							#DecimalFormat(session.basket.header[fld])#
						</cfif>
					</td>
					<td align="right">
						<cfif session.basket.header[fld] lt 0>
							<cfset crTotal -= session.basket.header[fld]>
							#DecimalFormat(session.basket.header[fld] * -1)#
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
	
	<div id="xreading2" class="totalPanel">
		<div class="header">Basket Totals</div>
		<table class="tableList" border="1">
			<tr>
				<th>DESCRIPTION</th>
				<th width="70" align="right">DR</th>
				<th width="70" align="right">CR</th>
			</tr>
			<cfset drTotal = 0>
			<cfset crTotal = 0>
			<cfset loopcount = 0>
			<cfset keys = ListSort(StructKeyList(session.basket.total,","),"text","ASC",",")>
			<cfloop list="#keys#" index="fld">
				<tr>
					<td>#fld#</td>
					<td align="right">
						<cfif session.basket.total[fld] gt 0>
							<cfset drTotal += session.basket.total[fld]>
							#DecimalFormat(session.basket.total[fld])#
						</cfif>
					</td>
					<td align="right">
						<cfif session.basket.total[fld] lt 0>
							<cfset crTotal -= session.basket.total[fld]>
							#DecimalFormat(session.basket.total[fld] * -1)#
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
	
	<div class="totalPanel" style="width:250px">
		<div class="header">VAT Analysis</div>
		<cfset ecfc.VATSummary(session.basket.trans)>
	</div>
	
	<cfif NOT StructIsEmpty(session.till.prevtran)>
		<!---<cfset ecfc.PrintReceipt(session.till.prevtran)>--->
	</cfif>
	<div style="clear:both"></div>
	
	<div id="xreading3" class="totalPanel">
		<div class="header">Till Header</div>
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
	
	<div id="xreading4" class="totalPanel">
		<div class="header">Till Totals</div>
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
	<div style="clear:both"></div>
</cfoutput>

<div class="totalPanel">
	<div class="header">Tran Dump</div>
	<cfset parm = {}>
	<cfset parm.reportDate = session.till.prefs.reportDate>
	<cfset ecfc.DumpTrans(parm)>
</div>
<div style="clear:both"></div>

<div style="float:left; margin:10px;">
	<cfdump var="#session#" label="session" expand="no">
</div>

</body>
</html>
