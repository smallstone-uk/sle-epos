
<!DOCTYPE HTML>
<html>
<head>
	<meta charset="utf-8">
	<title>EPOS-11</title>
	<style type="text/css">
		#tillpanel {width:520px; float:left; margin:10px; padding:10px; border:solid 2px #ccc; background:#eee; font-family:Arial, Helvetica, sans-serif; font-size:14px;}
		.tableList {border-spacing:0px; border-collapse:collapse; border:1px solid #BDC9DD; font-family:Arial, Helvetica, sans-serif; font-size:12px; border-color:#BDC9DD;}
		.tableList th {padding:4px 5px; background:#EFF3F7; border-color:#BDC9DD; color:#18315C;}
		.tableList td {padding:2px 5px; border-color:#BDC9DD;}
		.header {text-align:center; font-weight:bold; background:#99CCCC;}
		.eposBasketTable {border-spacing:0px; border-collapse:collapse; border:1px solid #BDC9DD; font-family:Arial, Helvetica, sans-serif; font-size:12px; border-color:#BDC9DD;}
		.eposBasketTable th {padding:4px 5px; background:#EFF3F7; border-color:#BDC9DD; color:#18315C;}
		.eposBasketTable td {padding:2px 5px; border-color:#BDC9DD;}
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
		.addBtn {float:right; display:block;font-weight:bold;}
	</style>
	<script src="js/jquery-1.11.1.min.js"></script>
	<script>
		$(document).ready(function() {
			$('#productType').change(function(e) {
				var mydata = $(this).children('option:selected').data()
				$('#prodTitle').val(mydata.title);
				$('#prodVATRate').val(mydata.vatrate);
				$('#cashOnly').val(mydata.cashonly);
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
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly,prodStaffDiscount
				FROM tblProducts
				WHERE prodLastBought > '2015-09-01'
				LIMIT 15)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly,prodStaffDiscount
				FROM tblProducts
				WHERE prodLastBought > '2015-09-01'
				AND prodVatRate <> 0
				LIMIT 15)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly,prodStaffDiscount
				FROM tblProducts
				WHERE prodLastBought > '2015-09-01'
				AND prodVatRate = 5
				LIMIT 5)
				UNION
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly,prodStaffDiscount
				FROM tblProducts
				WHERE prodSuppID != 21
				LIMIT 20)
				UNION	
				(SELECT prodID,prodRef,prodTitle,prodOurPrice,prodVATRate,prodCashOnly,prodStaffDiscount
				FROM tblProducts
				WHERE prodSuppID =0
				AND prodEposCatID = 91)	
			</cfquery>
			<cfreturn loc.QProducts>
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

<cfobject component="code/epos11" name="ecfc">
<cfparam name="mode" default="0">
<cfif NOT StructKeyExists(session,"till")>
	<cfset parm = {}>
	<cfset parm.datasource = ecfc.GetDataSource()>
	<cfset parm.form.reportDate = LSDateFormat(Now(),"yyyy-mm-dd")>
	<cfset ecfc.LoadTillTotals(parm)>
	<cfset ecfc.LoadDeals(parm)>
	<cfset ecfc.LoadVAT(parm)>
</cfif>
<cfif NOT StructKeyExists(session,"products")>	<!--- load test products --->
	<cfset parm = {}>
	<cfset parm.datasource = ecfc.GetDataSource()>
	<cfset parm.form.reportDate = LSDateFormat(Now(),"yyyy-mm-dd")>
	<cfset session.products = LoadProducts(parm)>
	<cfset session.customers = ecfc.GetAccounts(parm)>
	<cfset session.dates = ecfc.GetDates(parm)>
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
		<cflocation url="#cgi.SCRIPT_NAME#" addtoken="no">
	</cfif>
</cfif>

<body>
<cfoutput>
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
						<option value="prod-#prodID#" data-price="#prodOurPrice#" data-cashonly="#prodCashOnly#" 
							data-staffDiscount="#prodStaffDiscount#" data-title="#prodTitle#" data-vatrate="#prodVATRate#">
							#prodCashOnly# - #prodID# - #Left(prodTitle,20)# - #prodOurPrice# - #prodVatRate#%</option>
					</cfloop>
					<option value="PRIZE" data-price="" data-cashonly="1" data-title="Prize">1 - Prize</option>
					<option value="VCHN" data-price="" data-cashonly="0" data-title="News Voucher">0 - News Voucher</option>
					<option value="NEWS" data-price="" data-cashonly="0" data-title="News Account">0 - News Account</option>
					<option value="SUPP" data-price="" data-cashonly="1" data-title="Supplier Payment">1 - Supplier Payment</option>
					<option value="SRV" data-price="0.50" data-cashonly="0" data-title="Service Charge">0 - Service Charge</option>
					<option value="PP" data-price="" data-cashonly="1" data-title="PayPoint">1 - PayPoint</option>
				</select>
				<input type="checkbox" name="discountable" id="discountable" />Discountable
				<br>
				<input name="addToBasket" type="hidden" value="true" />
				<input name="prodTitle" id="prodTitle" type="hidden" value="" />
				<input name="vrate" id="prodVATRate" type="hidden" value="" />
				<input name="cashOnly" id="cashOnly" type="hidden" value="" />
				<div style="width:460px; margin:auto; margin-top:10px; padding:10px; ">
					Qty: <input type="text" name="qty" id="qty" size="2" value="1" />
					Credit: <input type="text" name="credit" id="credit" size="5" />
					Cash: <input type="text" name="cash" id="cash" size="5" />
					<input type="submit" name="btnSend" class="addBtn" value="Add" />
				</div>
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
				<cfloop array="#session.dates.recs#" index="item">
					<option value="#item.value#" <cfif session.till.prefs.reportDate eq item.value> selected</cfif>>#item.title#</option>
				</cfloop>
			</select>
			<input type="submit" name="btnGo" value="Go">
		</form>
		<div id="loading"></div>
	</div>
</cfoutput>

<div style="float:left; margin:10px;">
	<div class="header">Basket</div>
	<cfset ecfc.ShowBasket(session.basket)>
</div>
<div style="clear:both"></div>

<cfif NOT StructIsEmpty(session.till.prevtran)>
	<cfset ecfc.PrintReceipt(session.till.prevtran,0)>
</cfif>
<div style="clear:both"></div>

<cfoutput>
	<div id="xreading1" style="float:left; margin:10px;">
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
	
	<div id="xreading2" style="float:left; margin:10px;">
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
	<div style="clear:both"></div>
	
	<div id="xreading3" style="float:left; margin:10px;">
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
	
	<div id="xreading4" style="float:left; margin:10px;">
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

<div style="float:left; margin:10px;">
	<cfdump var="#session#" label="session" expand="yes">
</div>

</body>
</html>
