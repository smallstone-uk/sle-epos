<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset cats = epos.LoadCategories()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			deals = {};
			
			$('.MethodSelectForm').submit(function(event) { event.preventDefault(); });
			$('.msf_new').click(function(event) {$('.MethodSelectForm').fadeOut(function() {$('.NewDealForm').fadeIn();$('.NewDealForm')[0].reset();});event.preventDefault();});
			$('.msf_old').click(function(event) {$('.MethodSelectForm').fadeOut(function() {$('.ExistingDealForm').fadeIn();});event.preventDefault();});
			$('.ui-text').virtualKeyboard();
			$('.ui-date').virtualDate();
			$('.ui-number').virtualNumpad();
			//$('.ndf_type').bigSelect();
			$.infoMsg();
			
			dealProductContinue = function() {
				$('.DealItemsForm').fadeOut(function() {
					$('.DealProductForm').fadeIn();
					$('.DealProductForm_Title').html(" - " + deals.product.title);
					$('input[name="dpf_prodid"]').val(deals.product.id);
				});
			}
			
			$('.back').click(function(event) {
				var udForm = $(this).attr("data-form");
				var thisForm = $(this).parents('form');
				var prevForm = (typeof udForm != "undefined") ? $(udForm) : thisForm.prev('form');
				thisForm.fadeOut(function() {prevForm.fadeIn();});
				event.preventDefault();
			});
			
			$('.NewDealForm').submit(function(event) {
				if ( $('.NewDealForm .required').hasLength() ) {
					deals["range"] = $('.NewDealForm').serialize();
					$('.NewDealForm').fadeOut(function() {
						$('.ContinueNewDealForm').fadeIn();
					});
				}
				event.preventDefault();
			});
			
			$('.epf_method_search').click(function(event) {
				$('.epf_categories').fadeOut();
				$('.epf_method_barcode, .epf_method_category').fadeTo(500, 0.5);
				$(this).fadeTo(500, 1);
				$.virtualKeyboard({ callback: function(keyword) {
					$.ajax({
						type: "POST",
						url: "ajax/apps/fn/post_searchProductByKeyword_deal.cfm",
						data: {"keyword": keyword},
						success: function(data) {
							$('.epf_products').fadeIn();
							$('.epf_products td').html(data);
						}
					});
				} });
				event.preventDefault();
			});
			
			$('.epf_method_barcode').click(function(event) {
				$('.epf_categories, .epf_products').fadeOut();
				$('.epf_method_search, .epf_method_category').fadeTo(500, 0.5);
				$(this).fadeTo(500, 1);
				$.virtualNumpad({ wholenumber: true, callback: function(barcode) {
					$.ajax({
						type: "POST",
						url: "ajax/apps/fn/get_productsByBarcode_deal.cfm",
						data: {"barcode": barcode},
						success: function(data) {
							$('.epf_products').fadeIn();
							$('.epf_products td').html(data);
						}
					});
				} });
				event.preventDefault();
			});
			
			$('.epf_method_category').click(function(event) {
				$('.epf_method_search, .epf_method_barcode').fadeTo(500, 0.5);
				$(this).fadeTo(500, 1);
				$('.epf_products').fadeOut(function() {
					$('.epf_categories').fadeIn();
				});
				event.preventDefault();
			});
			
			$('.epf_cat_item').click(function(event) {
				var catID = $(this).data("value");
				$.ajax({
					type: "POST",
					url: "ajax/apps/fn/get_productsInCat_deal.cfm",
					data: {"catID": catID},
					success: function(data) {
						$('.epf_categories').fadeOut(function() {
							$('.epf_products').fadeIn();
							$('.epf_products td').html(data);
						});
					}
				});
				event.preventDefault();
			});
			
			$('.DealProductForm').submit(function(event) {
				if ( $('.required-2').hasLength() ) {
					deals["items"] = $(this).serialize();
					$.ajax({
						type: "POST",
						url: "ajax/apps/fn/post_newDeal.cfm",
						data: { "deal": $.formToStruct( ['.NewDealForm', '.DealProductForm'], "json" ) },
						success: function(data) {
							$.appMsg(data.trim());
							$('.DealProductForm').fadeOut(function() {
								$('.MethodSelectForm').fadeIn();
							});
						}
					});
				}
				event.preventDefault();
			});
			
			$('.ctrlChooseProducts').click(function(event) {
				var obj = $(this);
				$.productSelect({
					maxqty: 100,
					callback: function(data) {
						console.log(data);
						var html = "";
						
						for (i = 0; i < data.length; i++) {
							html += "<tr data-id='" + data[i].id + "' data-title='" + data[i].title + "'>"+
							"<td style='font-size:22px' align='right'>" + data[i].title + "</td>"+
							"<td><input type='text' name='pfd_i_minqty' placeholder='Min Qty' class='appfld' style='width:100px !important'></td>"+
							"<td><input type='text' name='pfd_i_maxqty' placeholder='Max Qty' class='appfld' style='width:100px !important'></td></tr>";
						}
						
						var row = obj.parents('tr');
						row.after(html);
					}
				});
				event.preventDefault();
			});
		});
	</script>
	<form method="post" enctype="multipart/form-data" class="MethodSelectForm">
		<span class="title">What will it be?</span>
		<table border="0" class="btnleft">
			<tr>
				<td><input type="submit" value="New Deal" class="appbtn msf_new"></td>
				<td><input type="submit" value="Existing Deal" class="appbtn msf_old"></td>
			</tr>
		</table>
	</form>
	<form method="post" enctype="multipart/form-data" class="NewDealForm" style="display:none;">
		<span class="title"><span class="back icon-circle-left" data-form=".MethodSelectForm"></span>New Deal</span>
		<table border="0" class="header-align-right">
			<caption>Pick a date range that the following deals will apply for.</caption>
			<tr>
				<th>Start Date</th>
				<td><input type="text" name="ndf_start" class="appfld required ui-date" value="15/02/1997" placeholder="DD/MM/YYYY"></td>
				<td><span class="infomsg icon-info">The deal will only be valid <strong>from</strong> this starting date. The starting time is default to 00:00.</span></td>
			</tr>
			<tr>
				<th>End Date</th>
				<td><input type="text" name="ndf_end" class="appfld required ui-date" value="30/02/1997" placeholder="DD/MM/YYYY" data-past="false"></td>
				<td><span class="infomsg icon-info">The deal will only be valid <strong>to</strong> this ending date. The ending time is default to 00:00.</span></td>
			</tr>
		</table>
		<input type="submit" class="appbtn" value="Continue">
	</form>
	<form method="post" enctype="multipart/form-data" class="ContinueNewDealForm" style="display:none;">
		<span class="title"><span class="back icon-circle-left" data-form=".MethodSelectForm"></span>New Deal &gt; Headers</span>
		<table border="0" class="header-align-right">
			<tr>
				<td><input type="text" name="ndf_title" class="appfld required ui-text" placeholder="Deal Title" style="width:250px !important;"></td>
				<!---<td>
					<span class="infomsg icon-info">
						The deal title will show up on labels and on the till so make sure it's both descriptive and concise. Eg. 3 Pasties for &pound;1
					</span>
				</td>
				<td></td>--->
				
				<td>
					<select name="ndf_dealtype" class="ndf_dealtype required">
						<option value="nodeal">No Deal</option>
						<option value="bogof">Buy One Get One Free</option>
						<option value="twofor">Two For...</option>
						<option value="anyfor">Any For...</option>
						<option value="mealdeal">Meal Deal</option>
						<option value="halfprice">Half Price</option>
					</select>
				</td>
				<!---<td><span class="infomsg icon-info">Description TODO.</span></td>
				<td></td>--->
				
				<!---<td>
					<select name="ndf_type" class="ndf_type required">
						<option value="Quantity">Quantity</option>
						<option value="Discount">Discount</option>
						<!---<option value="Selection">Selection</option>--->
					</select>
				</td>
				<td>
					<span class="infomsg icon-info">
					The deal type defines how the deal itself will be handled.<br /><br />A "quantity" deal means the deal requires X amount of products to qualify for the deal, eg. 3 for &pound;1 would require a "quantity" deal type as it relies on the quantity being 3.<br /><br />The discount deal type is a more simple approach to a deal. It simply means X product will be discounted, eg. 50% off all chocolate bars etc.
					</span>
				</td>
				<td></td>--->
				
				<td><input type="text" name="ndf_amount" class="money ui-number required" placeholder="GBP"></td>
				<!---<td>
					<span class="infomsg icon-info">
						This is the amount the product(s) will be sold for if they qualify for the deal. For example if you wanted a product to be &pound;1 if bought in quantities of 3, then you would first of all make sure the type is set to quantity, then simply enter 1.00 into the amount field, then you'd enter 3 into the quantity field.
					</span>
				</td>
				<td></td>--->
				
				<td><input type="text" name="ndf_qty" class="money ui-number required" placeholder="Qty" data-wholenumber="true"></td>
				<!---<td><span class="infomsg icon-info">Quantity defines how many of the chosen product(s) is required before they become eligible for the deal. For example if you wanted a 3 for 1 deal, you would enter 3 into the quantity field.</span></td>
				<td></td>--->
				
				<td><button class="ctrlChooseProducts scalebtn" style="margin: 5px 5px 0 5px;height: 45px;">Products</button></td>
			</tr>
		</table>
	</form>
	<form method="post" enctype="multipart/form-data" class="DealItemsForm" style="display:none;">
		<span class="title"><span class="back icon-circle-left" data-form=".NewDealForm"></span>New Deal Products</span>
		<table border="0" class="header-align-right">
			<caption>Find a product by...</caption>
			<tr>
				<td>
					<button class="appbtn epf_method_search">Search</button>
					<button class="appbtn epf_method_category">Category</button>
					<button class="appbtn epf_method_barcode">Barcode</button>
				</td>
			</tr>
			<tr class="epf_products" style="display:none;">
				<td></td>
			</tr>
			<tr class="epf_categories" style="display:none;">
				<td>
					<ul>
						<cfloop array="#cats#" index="item">
							<li class="epf_cat_item" data-value="#item.epcID#">#item.epcTitle#</li>
						</cfloop>
					</ul>
				</td>
			</tr>
		</table>
	</form>
	<form method="post" enctype="multipart/form-data" class="DealProductForm" style="display:none;">
		<input type="hidden" name="dpf_prodid">
		<span class="title"><span class="back icon-circle-left" data-form=".DealItemsForm"></span>Deal Product<span class="DealProductForm_Title"></span></span>
		<table border="0" class="header-align-right">
			<tr>
				<th>Minimum Quantity</th>
				<td><input type="text" name="dpf_minqty" class="appfld ui-number required-2" placeholder="Qty" data-wholenumber="true" data-minimum="1"></td>
				<td><span class="infomsg icon-info">This is the minimum quantity of the selected product the customer is allowed to be granted the deal. For example if you were creating a 3 for 1 deal, you would enter a minimum quantity of 3.</span></td>
			</tr>
			<tr>
				<th>Maximum Quantity</th>
				<td><input type="text" name="dpf_maxqty" class="appfld ui-number required-2" placeholder="Qty" data-wholenumber="true" data-minimum="1"></td>
				<td><span class="infomsg icon-info">This is the maximum quantity of the selected product the customer is allowed to be granted the deal. For example if you were creating a 3 for 1 deal, you would enter a maximum quantity of 3.</span></td>
			</tr>
		</table>
		<input type="submit" class="appbtn" value="Complete">
	</form>
	<form method="post" enctype="multipart/form-data" class="ExistingDealForm" style="display:none;">
		<span class="title"><span class="back icon-circle-left" data-form=".MethodSelectForm"></span>Existing Deal</span>
		<table border="0" class="header-align-right">
			<caption>Here's all the deals...</caption>
			<tr>
				<td class="edf_deallist">
					<script>
						$(document).ready(function(e) {
							$('.edf_dealitem').touchHold([
								{
									text: "edit",
									action: function(a, e) {
										$.ajax({
											type: "POST",
											url: "ajax/apps/fn/get_editDeal.cfm",
											data: {"dealID": a.id},
											success: function(data) {
												$.sidepanel(data, 700);
											}
										});
									}
								},
								{
									text: "delete",
									action: function(a, e) {
										$.confirmation(function() {
											$.ajax({
												type: "POST",
												url: "ajax/apps/fn/post_delDeal.cfm",
												data: {"dealID": a.id},
												success: function(data) {
													e.remove();
													$.appMsg("Deal Deleted Successfully");
												}
											});
										});
									}
								}
							]);
						});
					</script>
					<ul>
						<cfloop query="session.deals">
							<li class="edf_dealitem" data-id="#edID#">#edTitle#</li>
						</cfloop>
					</ul>
				</td>
			</tr>
		</table>
	</form>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>