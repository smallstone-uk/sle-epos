<cftry>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<link href="css/sections.css" rel="stylesheet" type="text/css">
<script src="../scripts/jquery-1.11.1.min.js"></script>
<script src="../scripts/jquery-ui.js"></script>
<script src="js/sections.js"></script>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			sections = new Sections();
			
			sections["stepone"] = function(article, form) {
				console.log(form);
			}
			
			sections.complete = function() {
				alert("Complete");
			}
			
			console.log(sections);
		});
	</script>
	<body>
		<div class="style_overide">
			<cfinclude template="ajax/getStyleOveride.cfm">
		</div>
		<section>
			<article data-title="Step One" data-class="stepone">
				<div>
					<form>
						<label>
							<span>Field Header</span>
							<input type="text" name="title" placeholder="type something">
						</label>
						<label>
							<span>Field Header</span>
							<input type="text" name="price" placeholder="type something">
						</label>
						<label>
							<span>Field Header</span>
							<input type="text" name="date" placeholder="type something">
						</label>
					</form>
				</div>
			</article>
			<article data-title="Step Two">
				<div>
					<form>
						<label>
							<span>Field Header</span>
							<input type="text" placeholder="type something">
						</label>
						<label>
							<span>Field Header</span>
							<input type="text" placeholder="type something">
						</label>
						<label>
							<span>Field Header</span>
							<input type="text" placeholder="type something">
						</label>
					</form>
				</div>
			</article>
			<article data-title="Step Three">
				<div>
					<form>
						<label>
							<span>Field Header</span>
							<input type="text" placeholder="type something">
						</label>
						<label>
							<span>Field Header</span>
							<input type="text" placeholder="type something">
						</label>
						<label>
							<span>Field Header</span>
							<input type="text" placeholder="type something">
						</label>
					</form>
				</div>
			</article>
			<article data-title="Step Four">
				<div>
					<form>
						<label>
							<span>Field Header</span>
							<input type="text" placeholder="type something">
						</label>
						<label>
							<span>Field Header</span>
							<input type="text" placeholder="type something">
						</label>
						<label>
							<span>Field Header</span>
							<input type="text" placeholder="type something">
						</label>
					</form>
				</div>
			</article>
		</section>
	</body>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>