<cftry>
<link href="css/jstill.css" rel="stylesheet" type="text/css">
<script src="js/jquery-1.11.1.min.js"></script>
<script src="js/jquery-ui.js"></script>
<script src="js/epos.js"></script>

<cfobject component="code/epos" name="epos">
<cfset products = epos.LoadRandomProducts(30)>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			var runningTotal = 0;
			var basket = {
				product: {},
				publication: {},
				paypoint: {},
				deal: {},
				payment: {},
				discount: {},
				supplier: {}
			};
			
			printHeaderObjects = function() {
				$('.key_group').remove();
				
				for (var key in basket) {
					$('.result').append(
						'<div class="key_group" data-key="' + key + '">'+
						'<h1>' + key.toUpperCase() + '</h1>'+
						'</div>'
					);
				}
			}
			
			printChildObjects = function() {
				for (var key in basket) {
					for ( var child in basket[key] ) {
						$('.key_group[data-key="' + key + '"]').append('<li class="key_child" data-child="' + child + '">' + child.toUpperCase() + '</li>');
					}
				}
			}
			
			printChildProperties = function() {
				for (var key in basket) {
					for ( var child in basket[key] ) {
						if ( Object.keys( basket[key][child] ).length > 0 ) {
							$('.key_child[data-child="' + child + '"]').append('<div class="key_props"></div>');
							for ( var prop in basket[key][child] ) {
								$('.key_child[data-child="' + child + '"]').find('.key_props').append(
									'<li>'+
									'<span>' + prop + '</span>'+
									'<span>' + basket[key][child][prop] + '</span>'+
									'</li>'
								);
							}
						}
					}
				}
			}
			
			printRunningTotal = function() {
				runningTotal = 0;
				for (var key in basket) {
					for ( var child in basket[key] ) {
						if ( Object.keys( basket[key][child] ).length > 0 ) {
							for ( var prop in basket[key][child] ) {
								if (prop.toLowerCase() == "price" || prop.toLowerCase() == "value")
									runningTotal += Number( basket[key][child][prop] ) * Number( basket[key][child]["qty"] );
							}
						}
					}
				}
				
				$('.totals').html(
					'<span style="float:left;">Total:</span><span style="float:right;">' + nf(runningTotal, "str") + '</span>'
				);
			}
			
			printHeaderObjects();
			printChildObjects();
			printChildProperties();
			printRunningTotal();
			
			$(document).on("click", ".key_group h1", function(event) {
				$(this).siblings().slideToggle(250);
				event.preventDefault();
			});
			
			$(document).on("click", ".key_group .key_child", function(event) {
				$(this).children().slideToggle(250);
				event.preventDefault();
			});
			
			$('.product_item').click(function(event) {
				var keyTitle = $(this).data("title").replace(" ", "");
				if ( typeof basket.product[ keyTitle ] != "undefined" ) {
					if ( typeof basket.product[ keyTitle ]["qty"] == "undefined" ) {
						basket.product[ keyTitle ]["qty"] = 2;
					} else {
						basket.product[ keyTitle ]["qty"]++;
					}
				} else {
					basket.product[ keyTitle ] = {};
					var a = getDataAttributes( $(this) );
					for (var key in a) basket.product[ keyTitle ][key] = a[key];
				}
				printHeaderObjects();
				printChildObjects();
				printChildProperties();
				printRunningTotal();
				event.preventDefault();
			});
		});
	</script>
	<div class="products noselect">
		<cfloop array="#products#" index="item">
			<li class="product_item" data-title="#item.prodTitle#" data-price="#item.siOurPrice#" data-qty="1">
				<span style="float:left;">#item.prodTitle#</span>
				<span style="float:right;">#DecimalFormat(item.siOurPrice)#</span>
			</li>
		</cfloop>
	</div>
	<div class="result noselect"></div>
	<div class="totals noselect"></div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="no">
</cfcatch>
</cftry>