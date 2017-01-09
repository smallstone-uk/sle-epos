
<!DOCTYPE HTML>
<html>
<head>
	<meta charset="utf-8">
	<title>EPOS-14</title>
	<style type="text/css">
		#tillpanel {float:left; padding:10px; border:solid 2px #ccc; background:#eee; font-family:Arial, Helvetica, sans-serif; font-size:14px;}
		.tableList {border-spacing:0px; border-collapse:collapse; border:1px solid #BDC9DD; font-family:Arial, Helvetica, sans-serif; font-size:12px; border-color:#BDC9DD;}
		.tableList th {padding:4px 5px; background:#EFF3F7; border-color:#BDC9DD; color:#18315C;}
		.tableList td {padding:2px 5px; border-color:#BDC9DD;}
		.header {text-align:center; font-weight:bold; background:#99CCCC;}
		.eposBasketTable {border-spacing:0px; border-collapse:collapse; border:1px solid #BDC9DD; font-family:Arial, Helvetica, sans-serif; font-size:12px; border-color:#BDC9DD;}
		.eposBasketTable th {padding:4px 5px; background:#EFF3F7; border-color:#BDC9DD; color:#18315C;}
		.eposBasketTable td {padding:2px 5px; border-color:#BDC9DD;}
		#mode {margin-left:10px; text-transform:uppercase; font-weight:bold;}
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
		.addBtn {float:right; display:block;font-weight:bold;}
		#productType {margin:2px;}
		#mediaType {margin:2px;}
	</style>
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
							if (result.MSG) {
								$('#errMsg').html(result.MSG);
							} else {
								if (result.PRODID && result.PRODTITLE) {
									$('#itemClass').val(result.EPCKEY);
									$('#prodID').val(result.PRODID);
									$('#prodTitle').val(result.PRODTITLE);
									$('#prodVATRate').val(result.PRODVATRATE);
									$('#cashOnly').val(result.PRODCASHONLY);
									$('#credit').val(result.PRODOURPRICE);
									$('#prodSign').val(result.PRODSIGN);
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
				var mydata = $(this).children('option:selected').data();
				console.log(mydata);
				$('#prodID').val(mydata.prodid);
				$('#itemClass').val(mydata.epckey);
				$('#prodTitle').val(mydata.title);
				$('#prodVATRate').val(mydata.vatrate);
				$('#cashOnly').val(mydata.cashonly);
				$('#prodSign').val(mydata.sign);
			//	$('#discountable') = val(mydata.staffDiscount);
				if (mydata.cashonly) {
					$('#cash').val(mydata.price);
					$('#credit').val("");
				} else {
					$('#cash').val("");
					$('#credit').val(mydata.price);
				}
			}); 
			
			$('#publication').change(function(e) {
				var mydata = $(this).children('option:selected').data();
				console.log(mydata);
				$('#itemClass').val(mydata.epckey);
				$('#pubID').val(mydata.pubid);
				$('#pubTitle').val(mydata.title);
				$('#prodVATRate').val(mydata.vatrate);
				$('#cashOnly').val(mydata.cashonly);
				$('#prodSign').val(mydata.sign);
			//	$('#discountable') = val(mydata.staffDiscount);
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

	<cffunction name="LoadProducts" access="public" returntype="query">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry> 
			<cfquery name="loc.QProducts" datasource="#args.datasource#" result="loc.QProductsResult">
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign, epcKey
				FROM tblProducts
				INNER JOIN tblEPOSCats ON prodEposCatID=epcID
				INNER JOIN tblEPOS_DealItems ON ediProduct=prodID
				WHERE prodLastBought > '2015-09-01'
				)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign, epcKey
				FROM tblProducts
				INNER JOIN tblEPOSCats ON prodEposCatID=epcID
				WHERE prodLastBought > '2016-01-22'
				LIMIT 15)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign, epcKey
				FROM tblProducts
				INNER JOIN tblEPOSCats ON prodEposCatID=epcID
				WHERE prodLastBought > '2016-01-01'
				AND prodVatRate <> 0
				LIMIT 15)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign, epcKey
				FROM tblProducts
				INNER JOIN tblEPOSCats ON prodEposCatID=epcID
				WHERE prodLastBought > '2016-01-01'
				AND prodVatRate = 5
				LIMIT 5)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign, epcKey
				FROM tblProducts
				INNER JOIN tblEPOSCats ON prodEposCatID=epcID
				WHERE prodSuppID != 21
				LIMIT 20)
				UNION	
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly,prodStaffDiscount,prodSign, epcKey
				FROM tblProducts
				INNER JOIN tblEPOSCats ON prodEposCatID=epcID
				WHERE prodSuppID =0
				AND prodEposCatID IN (42,142,152,161,171,181,191,221) )	
			</cfquery>
			<cfreturn loc.QProducts>
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
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
			output="#application.site.dir_logs#\epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="Destroy" access="public" returntype="void">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cfquery name="loc.QDeleteTotals" datasource="#ecfc.GetDataSource()#">
			DELETE FROM tblEPOS_Totals
			WHERE totDate = '#session.till.prefs.reportdate#'
		</cfquery>
		<cfset StructDelete(session,"till",false)>
		<cfset StructDelete(session,"products",false)>
	</cffunction>

	<cffunction name="DumpTrans" access="public" returntype="struct">
		<cfargument name="args" type="struct" required="yes">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		
		<cftry>
			<cfquery name="loc.QTrans" datasource="#ecfc.GetDataSource()#">
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

<cfobject component="code/epos14" name="ecfc">
<cfparam name="mode" default="0">
<!---<cfset StructDelete(session,"till",false)>--->
<cfif NOT StructKeyExists(session,"till")>
	<cfset parm = {}>
	<cfset parm.datasource = ecfc.GetDataSource()>
	<cfset parm.form.reportDate = LSDateFormat(Now(),"yyyy-mm-dd")>
	<cfset ecfc.LoadTillTotals(parm)>
	<cfset ecfc.LoadDeals(parm)>
	<cfset ecfc.LoadVAT()>
	<cfset ecfc.LoadCatKeys()>
</cfif>
<cfif NOT StructKeyExists(session,"products")>	<!--- load test products --->
	<cfset parm = {}>
	<cfset parm.datasource = ecfc.GetDataSource()>
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
		<cfcase value="ztill">
			<cfset ecfc.ZTill(Now())>
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
			<cfcase value="Add">
				<cfset ecfc.AddItem(parm)>
			</cfcase>
			<cfcase value="Cash|Card|Cheque|Account" delimiters="|">
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
						<option value="#prodID#" data-price="#prodOurPrice#" data-cashonly="#prodCashOnly#" data-epckey="#epcKey#" data-sign="#prodSign#" data-prodid="#prodID#"
							data-staffDiscount="#prodStaffDiscount#" data-title="#prodTitle#" data-vatrate="#prodVATRate#">
							#prodCashOnly# - #prodID# - #epcKey# - #Left(prodTitle,20)# - #prodOurPrice# - #prodVatRate#%</option>
					</cfloop>
				</select>
				<br>
				Newspapers: 
				<select name="publication" id="publication">
					<option value="">Select...</option>
					<cfloop query="session.papers">
						<option value="#pubID#" data-price="#pubPrice#" data-cashonly="0" data-staffDiscount="1" data-epckey="#epcKey#" data-pubID="#pubID#"
							data-title="#pubTitle#" data-sign="1" data-vatrate="0">
							0 - #pubID# - #epcKey# - #Left(pubTitle,20)# - #pubPrice# - 0%</option>
					</cfloop>
				</select>
				<br>
				<input name="addToBasket" type="hidden" value="true" />
				<input name="prodID" id="prodID" type="hidden" value="" />
				<input name="pubID" id="pubID" type="hidden" value="" />
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
				<input name="prodSign" id="prodSign" type="text" value="" size="3" />
				<input name="prodTitle" id="prodTitle" type="text" value="" />
				<input name="pubTitle" id="pubTitle" type="text" value="" />
				<div style="clear:both"></div>
			</div>
			<div style="width:480px; margin:auto; margin-top:10px; padding:10px; border:solid 2px ##ccc; background:##999999;">
				<input type="submit" name="btnSend" class="pay cash" value="Cash" />
				<input type="submit" name="btnSend" class="pay" value="Card" />
				<input type="submit" name="btnSend" class="pay" value="Cheque" />
				<input type="submit" name="btnSend" class="pay" value="Account" />
				<select name="account">
					<option value="">Select account...</option>
					<cfloop query="session.customers.accounts">
						<option value="#eaID#">#eaTitle#</option>
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
		</form>
		<div id="loading"></div>
	</div>
</cfoutput>

<div style="float:left; margin:0 0 0 10px;">
	<div class="header">Basket</div>
	<cfset ecfc.ShowBasket()>
</div>
<div style="clear:both"></div>
	
<cfoutput>
	<div id="xreading1" style="float:left;">
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
	
	<div id="xreading2" style="float:left; margin:0px 10px;">
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
	
	<cfif NOT StructIsEmpty(session.till.prevtran)>
		<cfset ecfc.PrintReceipt(session.till.prevtran)>
	</cfif>
	<div style="clear:both"></div>
	
	<div id="xreading3" style="float:left; margin:10px 0px;">
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
	
	<div id="xreading4" style="float:left; margin:10px">
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

	<div style="float:left; margin:10px 0px;">
		<div class="header">Tran Dump</div>
		<cfset DumpTrans(session.basket)>
	</div>
	<div style="clear:both"></div>

<div style="float:left; margin:10px;">
	<cfdump var="#session#" label="session" expand="no">
</div>

</body>
</html>
