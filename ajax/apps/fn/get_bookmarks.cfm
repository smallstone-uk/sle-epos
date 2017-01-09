<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset bookmarks = epos.LoadBookmarks()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			loadBookmarks = function() {
				$.ajax({
					type: "GET",
					url: "ajax/apps/fn/get_bookmarksList.cfm",
					success: function(data) {
						$('.bookmarks').html(data);
					}
				});
			}
			
			loadBookmarks();

			$('.book_add').click(function(event) {
				var text = "", time = "";
				$.virtualKeyboard({
					hint: "Enter the bookmark title, eg. Mop floor.",
					callback: function(title) {
						text = title;
						setTimeout(function() {
							$.virtualTime({
								hint: "Enter the default time this task starts.",
								callback: function(value) {
									time = value;
									$.ajax({
										type: "POST",
										url: "ajax/apps/fn/post_newBookmark.cfm",
										data: {
											text: text,
											time: time
										},
										success: function(data) {
											loadBookmarks();
										}
									});
								}
							});
						}, 500);
					}
				});
				event.preventDefault();
			});
		});
	</script>
	<span class="scalebtn book_add icon-plus"></span>
	<span class="title">Bookmarks</span>
	<ul class="bookmarks"></ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>