<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.prodID = prodID>
<cfset cats = epos.LoadCategories()>
<cfset prodcats = epos.LoadProductCategories()>
<cfset groups = epos.LoadProductGroups()>
<cfset prod = epos.LoadProductByID(parm.prodID)>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.epf_cat').bigSelect();
			$('.ui').virtualKeyboard();
			$('.ui2').virtualNumpad();
			$('.epf_co').touchCheckbox();
			$('.epf_ps').touchCheckbox(function(isChecked) {
				$('.epf_p').prop( "disabled", (isChecked) ? true : false );
				if (isChecked) $('.epf_p').val("");
			});
			
			$('.EditProductForm').submit(function(event) {
				if ( $('input[name="epf_title"]').val().length > 0 ) {
					$.ajax({
						type: "POST",
						url: "ajax/apps/fn/post_editProduct.cfm",
						data: $('.EditProductForm').serialize(),
						success: function(data) {
							$('.EditProductForm').fadeOut(function() {
								$('.EditProductResponse').fadeIn();
							});
						}
					});
				}
				event.preventDefault();
			});
			
			var grpBox, catBox;
			
			$('.epf_prodcat').bigSelect(function(box, attrib) {
				catBox = box;
			});
			
			$('.epf_grp').bigSelect(function(box, attrib) {
				grpBox = box;
				catBox.find('li').show();
				catBox.find('li[data-group!="' + attrib.value + '"]').hide();
			});
			
			$('.epf_grp').touchSelect();
		});
	</script>
	<form method="post" enctype="multipart/form-data" class="EditProductForm">
		<input type="hidden" name="epf_id" value="#prod.prodID#">
		<table border="0">
			<tr>
				<th align="right">Title</th>
				<td><input type="text" class="ui appfld" name="epf_title" placeholder="Product Title" value="#prod.prodTitle#"></td>
			</tr>
			<cfif prod.prodEposCatID gt 0>
				<tr>
					<th align="right">Till Category</th>
					<td>
						<select name="epf_cat" class="epf_cat">
							<cfloop array="#cats#" index="item">
								<option value="#item.epcID#" <cfif prod.prodEposCatID is item.epcID>selected="true"</cfif>>#item.epcTitle#</option>
							</cfloop>
						</select>
					</td>
				</tr>
			</cfif>
			<tr>
				<th align="right">Product Group</th>
				<td>
					<select name="epf_grp" class="epf_grp">
						<cfloop array="#groups#" index="item">
							<option value="#item.pgID#" <cfif prod.pcatGroup is item.pgID>selected="true"</cfif>>#item.pgTitle#</option>
						</cfloop>
					</select>
				</td>
			</tr>
			<tr>
				<th align="right">Product Category</th>
				<td>
					<select name="epf_prodcat" class="epf_prodcat">
						<cfloop array="#prodcats#" index="item">
							<option value="#item.pcatID#" data-group="#item.pcatGroup#" <cfif prod.prodCatID is item.pcatID>selected="true"</cfif>>#item.pcatTitle#</option>
						</cfloop>
					</select>
				</td>
			</tr>
			<tr>
				<th align="right">Price</th>
				<td><input type="text" class="money ui2 epf_p" name="epf_price" placeholder="GBP" value="#DecimalFormat(prod.siOurPrice)#"></td>
			</tr>
			<tr>
				<th align="right">Enter price on-the-go</th><td><input type="checkbox" name="epf_priceswitch" class="appchk epf_ps"></td>
			</tr>
			<tr>
				<th align="right">This is a cash only product</th><td><input type="checkbox" name="epf_cashonly" class="appchk epf_co"></td>
			</tr>
		</table>
		<input type="submit" class="appbtn" value="Save Product">
	</form>
	<form class="EditProductResponse" style="display:none;">
		<span class="title">Your product has been updated successfully.</span>
	</form>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>