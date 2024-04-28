<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.IntroAddForm').submit(function(event) {
				$.ajax({
					type: "POST",
					url: "ajax/addIntroSlide.cfm",
					data: $('.IntroAddForm').serialize(),
					success: function(data) {
						$.popup.close();
						
						/*INTRO.tooltip(0, {
							ID: data.trim(),
							TEXT: $('textarea[name="ia_text"]').val(),
							NEXT: $('textarea[name="ia_next"]').val(),
							BACK: $('textarea[name="ia_back"]').val(),
							POSITION: [50, 50],
							BOX: [100, 100, 300, 300]
						});*/
						
						var useThisIndex = arrayStructFind( INTRO.slides, "ID", data.trim() );
						
						INTRO.loadData(function() {
							INTRO.tooltip( useThisIndex, INTRO.slides[ useThisIndex ] );
							INTRO.scaleElements( useThisIndex, INTRO.slides[ useThisIndex ] );
							if (INTRO.editable) INTRO.buildAdmin();
							INTRO.setDefaultScale();
						});
					}
				});
				event.preventDefault();
			});
		});
	</script>
	<form method="post" enctype="multipart/form-data" class="IntroAddForm">
		<textarea name="ia_text" placeholder="Enter the tooltip text..."></textarea>
		<textarea name="ia_next" placeholder="Enter the tooltip next code (if any)..."></textarea>
		<textarea name="ia_back" placeholder="Enter the tooltip back code (if any)..."></textarea>
		<input type="submit" value="Create">
	</form>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>