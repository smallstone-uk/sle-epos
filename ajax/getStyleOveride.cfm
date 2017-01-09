<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<cfif session.user.id gt 0>
		<cfset userPrefs = new App.User(session.user.id)>
		<cfset session.user.prefs = userPrefs>

		<style>
			<cfif Len(userPrefs.empBackground)>
				body {background-image: url(../images/wallpapers/#userPrefs.empBackground#) !important;}
			</cfif>

			<!---BACKGROUND ACCENT--->
			.header,
			button,
			button:active,
			.btr_header,
			.basket_checkout,
			.big_datepicker_backdrop ul li,
			.openSale,
			.home_list_item,
			.r_start,
			.r_tick,
			.archive_item,
			.payment_item,
			.payment_item_special,
			.FCDPPHeader,
			.FCDPPWRIDay_Active,
			.button_select .active_button,
			.option_left:active,
			.option_right:active,
			.products_item,
			.controls button,
			.controls input,
			.continueBtn,
			.previousBtn,
			.appbtn,
			.inner_checked,
			.epf_categories td ul li:active,
			.epf_products td ul li:active,
			.virtual_keyboard span:active,
			.vk_key_active,
			.virtual_numpad span:active,
			.vkn_close:active,
			.edf_dealitem:active,
			.ac_item:active,
			.book_add:active,
			.supplier_list li:active,
			.basket_closerefund
			{background:#userPrefs.empAccent#;}
			
			<!---BACKGROUND DARK--->
			button:active,
			.openSale:active,
			.continueBtn:active,
			.previousBtn:active,
			.ps_selectedlist .ps_sli_item:active
			{background:##222;}
			
			<!---BACKGROUND ACCENT IMPORTANT--->
			.user_reminders ul li:active,
			.FCDPPWRIDay_Active,
			.suc_profile,
			.loggedInTile,
			.sectionContinue,
			.sectionBack,
			.user-background,
			.alert_item_active,
			.epos-till-page,
			.ps_product_item_active,
			.ps_product_item:active,
			.ps_cat_item:active,
			.ps_cat_item_active,
			.ps_selectedlist .ps_sli_item,
			.product_selector .closing,
			.sidepanel_page_back:active,
			.tm_icon li:active,
			.hollow:active,
			.user_profile ul li:active,
			.payment_item[data-disabled="true"],
			.basket_payment.touch_menu_active
			{background:#userPrefs.empAccent# !important;}
			
			<!---BORDER / COLOUR ACCENT IMPORTANT--->
			.bo_controlList li:active,
			.r_row_completed,
			.reminders ul h1,
			.ps_controls_item:hover,
			.ps_ci_active,
			textarea.appfld:focus,
			.hollow,
			select:focus
			{border-color:#userPrefs.empAccent# !important;color:#userPrefs.empAccent# !important;}
			
			<!---BORDER ACCENT IMPORTANT--->
			.FCDPPHeader,
			.FCDPPWRIDay,
			.bigselect[data-open="true"],
			{border-color:#userPrefs.empAccent# !important;}
			
			<!---BORDER ACCENT 3PX SOLID--->
			input[type="text"]:focus
			{border:3px solid #userPrefs.empAccent#;}
			
			<!---COLOUR ACCENT IMPORTANT--->
			.header_note,
			.close-button,
			.page-title,
			input:focus::-webkit-input-placeholder,
			textarea:focus::-webkit-input-placeholder,
			span.title,
			span.back,
			.bigselect .list span[data-selected="true"],
			.green,
			.epf_cat_ordericon,
			.suc_alerts_active,
			.apptab_active,
			.idents,
			.touchselect li[data-selected="true"]
			{color: #userPrefs.empAccent# !important;}
			
			<!--- COLOUR ACCENT --->
			.touch_menu_active,
			.touch_menu
			.touch_menu_inner li:active,
			span.cidFace,
			caption,
			.ul_header,
			.subtitle
			{color: #userPrefs.empAccent#;}
			
			<!--- SCROLL BAR --->
			::-webkit-scrollbar
			{width: 25px;background:##444;}
			::-webkit-scrollbar-thumb
			{background:#userPrefs.empAccent#;}
			
			.INTRO_OutlineBox {
				box-shadow: 0 0 50px #userPrefs.empAccent#;
				border: 5px solid #userPrefs.empAccent#;
			}
			
			@-moz-keyframes blinker {  
				0% { border-color: ##FFF; box-shadow: 0 0 50px ##FFF; }
				50% { border-color: #userPrefs.empAccent#; box-shadow: 0 0 50px #userPrefs.empAccent#; }
				100% { border-color: ##FFF; box-shadow: 0 0 50px ##FFF; }
			}
			
			@-webkit-keyframes blinker {  
				0% { border-color: ##FFF; box-shadow: 0 0 50px ##FFF; }
				50% { border-color: #userPrefs.empAccent#; box-shadow: 0 0 50px #userPrefs.empAccent#; }
				100% { border-color: ##FFF; box-shadow: 0 0 50px ##FFF; }
			}
			
			@keyframes blinker {  
				0% { border-color: ##FFF; box-shadow: 0 0 50px ##FFF; }
				50% { border-color: #userPrefs.empAccent#; box-shadow: 0 0 50px #userPrefs.empAccent#; }
				100% { border-color: ##FFF; box-shadow: 0 0 50px ##FFF; }
			}
		</style>
	</cfif>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>