<cfoutput>
	<ul>
		<cfif StructKeyExists(session, "epos_archive")>
			<cfif StructCount(session.epos_archive) gt 0>
				<script>
					$(document).ready(function(e) {
						$('.header_note').click(function(event) {
							$.ajax({
								type: "GET",
								url: "ajax/openArchive.cfm",
								success: function(data) {
									window.location = "#application.site.normal#epos2";
								}
							});
							event.preventDefault();
						});
					});
				</script>
				<li class="header_note">
					<cfif StructCount(session.epos_archive) is 1>
						#StructCount(session.epos_archive)# Pending Basket
					<cfelse>
						#StructCount(session.epos_archive)# Pending Baskets
					</cfif>
				</li>
			</cfif>
		</cfif>
	</ul>
</cfoutput>