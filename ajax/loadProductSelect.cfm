<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.form = DeserializeJSON(params)>
<cfset parm.form.maxqty = ( StructKeyExists(parm.form, "maxqty") ) ? val(parm.form.maxqty) : 1>
<cfset parm.form.products = ( StructKeyExists(parm.form, "products") ) ? parm.form.products : []>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			window.epos_frame.isStockControl = true;
			
			var #ToScript(parm.form.products, "pre_products")#;
			products = [];
			maxqty = Number( "#parm.form.maxqty#" );
			allowClick = true;
			hasFinished = false;
			
			if (pre_products.length > 0) products = pre_products;
			
			$('.ps_selectedlist').html("");
			for (var i = 0; i < products.length; i++) {
				if (products[i].title)
					$('.ps_selectedlist').append("<span class='ps_sli_item' data-id='"+
						products[i].id + "' data-title='" + products[i].title + "'>"+
						"<span class='indicator icon-cross'></span>" + products[i].title + "</span>"
					);
			}
			
			selectProduct = function(id, title) {
				if (products.length < maxqty) {
					products.push({ id: id, title: title });
					$('.ps_selectedlist').html("");
					for (var i = 0; i < products.length; i++) {
						$('.ps_selectedlist').append("<span class='ps_sli_item' data-id='"+
							products[i].id + "' data-title='" + products[i].title + "'>"+
							"<span class='indicator icon-cross'></span>" + products[i].title + "</span>"
						);
					}
				}
				
				$('.product_selector').center("both", "fixed");
				
				if (products.length == maxqty && !hasFinished) {
					hasFinished = true;
					window.epos_frame.productSelectComplete(products);
				}
			}
			
			deselectProduct = function(id) {
				products.splice( arrayStructFind(products, "id", id), 1 );
				$('.ps_selectedlist').html("");
				for (var i = 0; i < products.length; i++) {
					$('.ps_selectedlist').append("<span class='ps_sli_item' data-id='"+
						products[i].id + "' data-title='" + products[i].title + "'>"+
						"<span class='indicator icon-cross'></span>" + products[i].title + "</span>"
					);
				}
				
				$('.ps_product_item[data-id="' + id + '"]').removeClass("ps_product_item_active");
				$('.product_selector').center("both", "fixed");
				
				if (products.length == maxqty) {
					window.epos_frame.productSelectComplete(products);
				}
			}
			
			$('.ps_main').kinetic({
				cursor: "default",
				x: false,
				y: true,
				moved: function(settings) { allowClick = false; },
				stopped: function(settings) { allowClick = true; }
			});
			
			$('.ps_controls_item').click(function(event) {
				$('.ps_controls_item').removeClass("ps_ci_active");
				$(this).addClass("ps_ci_active");
				
				switch ( $(this).data("method") )
				{
					case "search":
						$.virtualKeyboard({ callback: function(keyword) {
							$.ajax({
								type: "POST",
								url: "ajax/apps/fn/post_searchProductByKeyword_ps.cfm",
								data: {"keyword": keyword},
								beforeSend: function() {
									$('.product_selector').center("both", "fixed");
								},
								success: function(data) {
									$('.ps_main').html(data);
									$('.product_selector').center("both", "fixed");
								}
							});
						} });
						break;
					case "categories":
						$.ajax({
							type: "GET",
							url: "ajax/apps/fn/get_loadCategories.cfm",
							success: function(data) {
								$('.ps_main').html(data);
								$('.product_selector').center("both", "fixed");
							}
						});
						break;
				}
				
				event.preventDefault();
			});
			
			$.scanBarcode({
				callback: function(barcode) {
					$.ajax({
						type: "POST",
						url: "ajax/apps/fn/post_loadProductByBarcode.cfm",
						data: {"barcode": barcode},
						success: function(data) {
							var result = JSON.parse(data);
							if (result.PRODID && result.PRODTITLE)
								selectProduct(result.PRODID, result.PRODTITLE);
						}
					});
				}
			});
			
			$(document).on("click", ".ps_sli_item", function(event) {
				deselectProduct($(this).data("id"));
				event.preventDefault();
			});
			
			$('.psf_complete').click(function(event) {
				hasFinished = true;
				window.epos_frame.productSelectComplete(products);
				event.preventDefault();
			});
		});
	</script>
	
	<span class="title">
		Product Selection
		<span class="idents">
			<span class="icon-barcode"></span>
		</span>
	</span>
	
	<div class="ps_selectedlist"></div>
	
	<div class="ps_controls">
		<ul>
			<li class="ps_controls_item scalebtn" data-method="search"><span class="icon-search"></span>Search</li>
			<li class="ps_controls_item scalebtn" data-method="categories"><span class="icon-menu"></span>Categories</li>
		</ul>
	</div>
	
	<div class="ps_main"></div>
	
	<div class="ps_footer">
		<span class="psf_complete scalebtn">Okay</span>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>