<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset bookmarks = epos.LoadBookmarks()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.book_item').touchHoldIcon([
				{
					icon: "pencil",
					action: function(attrib, el) {
						el.iconOptions([
							{
								icon: "font-size",
								action: function() {
									$.virtualKeyboard({
										value: attrib.title,
										callback: function(new_text) {
											$.ajax({
												type: "POST",
												url: "ajax/apps/fn/post_editBookmarkTitle.cfm",
												data: {
													"book_id": attrib.id,
													"new_text": new_text
												},
												success: function(data) {
													el.find('.bi_content').html(new_text);
												}
											});
										}
									});
								}
							},
							{
								icon: "clock2",
								action: function() {
									$.virtualTime({
										value: attrib.time,
										callback: function(new_time) {
											$.ajax({
												type: "POST",
												url: "ajax/apps/fn/post_editBookmarkTime.cfm",
												data: {
													"book_id": attrib.id,
													"new_time": new_time
												},
												success: function(data) {
													el.find('.bi_timestamp').html(new_time);
												}
											});
										}
									});
								}
							}
						], function() {
							$('.book_item').css("opacity", 0.25);
							el.css("opacity", 1);
						}, function() {
							$('.book_item').css("opacity", 1);
						});
					}
				},
				{
					icon: "bin",
					action: function(attrib, el) {
						$.confirmation("Are you sure you want to delete this bookmark?", function() {
							$.ajax({
								type: "POST",
								url: "ajax/apps/fn/post_deleteBookmark.cfm",
								data: {"book_id": attrib.id},
								success: function(data) {
									el.remove();
								}
							});
						});
					}
				}
			], function() {
				$('.book_item').css("opacity", 0.25);
				$('.touch_menu_active').css("opacity", 1);
			}, function() {
				$('.book_item').css("opacity", 1);
			});
		});
	</script>
	<cfloop array="#bookmarks#" index="item">
		<li class="scalebtn book_item" data-id="#item.ebID#" data-title="#item.ebTitle#" data-time="#LSTimeFormat(item.ebTime, 'HH:mm')#">
			<span class="bi_icon icon-bookmark"></span>
			<span class="bi_timestamp">#LSTimeFormat(item.ebTime, "HH:mm")#</span>
			<span class="bi_content">#item.ebTitle#</span>
		</li>
	</cfloop>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>