<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset cats = epos.LoadCategories()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.MethodSelectForm').submit(function(event) {event.preventDefault();});
			$('.NewProductResponse').submit(function(event) {event.preventDefault();});
			$('.msf_new').click(function(event) {$('.MethodSelectForm').fadeOut(function() {$('.NewProductForm').fadeIn();$('.NewProductForm')[0].reset();});event.preventDefault();});
			$('.msf_old').click(function(event) {$('.MethodSelectForm').fadeOut(function() {$('.ExistingProductForm').fadeIn();});event.preventDefault();});
			
			$('.back').click(function(event) {
				var udForm = $(this).attr("data-form");
				var thisForm = $(this).parents('form');
				var prevForm = (typeof udForm != "undefined") ? $(udForm) : thisForm.prev('form');
				thisForm.fadeOut(function() {prevForm.fadeIn();});
				event.preventDefault();
			});
			
			$('.ui').virtualKeyboard();
			$('.ui2').virtualNumpad();
			$('.npf_co').touchCheckbox();
			$('.npf_cat').bigSelect();
			
			$('.npf_ps').touchCheckbox(function(isChecked) {
				$('.npf_p').prop( "disabled", (isChecked) ? true : false );
				if (isChecked) $('.npf_p').val("");
			});
			
			$('.NewProductForm').submit(function(event) {
				if ( $('input[name="npf_title"]').val().length > 0 ) {
					$.ajax({
						type: "POST",
						url: "ajax/apps/fn/post_newProduct.cfm",
						data: $('.NewProductForm').serialize(),
						success: function(data) {
							$('.NewProductForm').fadeOut(function() {
								$('.NewProductResponse').fadeIn();
							});
						}
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
						url: "ajax/apps/fn/post_searchProductByKeyword.cfm",
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
						url: "ajax/apps/fn/get_productsByBarcode.cfm",
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
					url: "ajax/apps/fn/get_productsInCat.cfm",
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
			
			$('.msf_newcat').click(function(event) {
				$.virtualKeyboard({ hint: "Enter the category title", callback: function(text) {
					$.ajax({
						type: "POST",
						url: "ajax/apps/fn/post_addCategory.cfm",
						data: {"catTitle": text},
						success: function(data) {
							$.appMsg(text + " has been added succesfully. You will need to reload the product manager to use the newly added category.");
						}
					});
				} });
				event.preventDefault();
			});
			
			$('.msf_oldcat').click(function(event) {
				$.ajax({
					type: "GET",
					url: "ajax/apps/fn/get_loadCats.cfm",
					success: function(data) {
						$.sidepanel(data, 530);
					}
				});
				event.preventDefault();
			});
			
			$('.msf_reordercat').click(function(event) {
				$.ajax({
					type: "GET",
					url: "ajax/apps/fn/get_reorderCats.cfm",
					success: function(data) {
						$.sidepanel(data, 530);
					}
				});
				event.preventDefault();
			});
			
			$('.msf_assigncat').click(function(event) {
				$.ajax({
					type: "GET",
					url: "ajax/apps/fn/get_assignCats.cfm",
					success: function(data) {
						$.sidepanel(data, 530);
					}
				});
				event.preventDefault();
			});
		});
	</script>
	<form method="post" enctype="multipart/form-data" class="MethodSelectForm">
		<span class="title">What will it be?</span>
		<table border="0" class="btnleft">
			<tr><td class="subtitle">Products</td></tr>
			<tr>
				<td><input type="submit" value="New Product" class="appbtn msf_new"></td>
				<td><input type="submit" value="Existing Product" class="appbtn msf_old"></td>
			</tr>
			<tr><td class="subtitle">Categories</td></tr>
			<tr>
				<td><input type="submit" value="New Category" class="appbtn msf_newcat"></td>
				<td><input type="submit" value="Existing Category" class="appbtn msf_oldcat"></td>
			</tr>
			<tr>
				<td><input type="submit" value="Reorder Category" class="appbtn msf_reordercat"></td>
				<cfif session.user.eposlevel lte 3>
					<td><input type="submit" value="Assign Categories" class="appbtn msf_assigncat"></td>
				</cfif>
			</tr>
		</table>
	</form>
	<form method="post" enctype="multipart/form-data" class="NewProductForm" style="display:none;">
		<span class="title"><span class="back icon-circle-left" data-form=".MethodSelectForm"></span>New Product</span>
		<table border="0">
			<tr>
				<th align="right">Title</th><td><input type="text" class="appfld ui" name="npf_title" placeholder="Product Title"></td>
			</tr>
			<tr>
				<th align="right">Category</th>
				<td>
					<select name="npf_cat" class="npf_cat">
						<cfloop array="#cats#" index="item">
							<option value="#item.epcID#">#item.epcTitle#</option>
						</cfloop>
					</select>
				</td>
			</tr>
			<tr>
				<th align="right">Price</th>
				<td><input type="text" class="money ui2 npf_p" name="npf_price" placeholder="GBP"></td>
			</tr>
			<tr>
				<th align="right">Enter price on-the-go</th><td><input type="checkbox" name="npf_priceswitch" class="appchk npf_ps"></td>
			</tr>
			<tr>
				<th align="right">This is a cash only product</th><td><input type="checkbox" name="npf_cashonly" class="appchk npf_co"></td>
			</tr>
		</table>
		<input type="submit" class="appbtn" value="Continue">
	</form>
	<form class="NewProductResponse" style="display:none;">
		<span class="title"><span class="back icon-circle-left" data-form=".MethodSelectForm"></span>Your product has been added successfully.</span>
	</form>
	<form method="post" enctype="multipart/form-data" class="ExistingProductForm" style="display:none;">
		<span class="title"><span class="back icon-circle-left" data-form=".MethodSelectForm"></span>Existing Product</span>
		<table border="0">
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
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>