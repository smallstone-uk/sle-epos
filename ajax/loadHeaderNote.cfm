<cfoutput>
	<cfif StructKeyExists(session, "epos_archive")>
		<cfif StructCount(session.epos_archive) gt 0>
			<script>
				$(document).ready(function(e) {
					$('.header_note').click(function(event) {
						$.ajax({
							type: "GET",
							url: "ajax/openArchive.cfm",
							success: function(data) {
								$.loadBasket();
								$('.header_note').remove();
							}
						});
						event.preventDefault();
					});
				});
			</script>
			<div class="header_note">
				<cfif StructCount(session.epos_archive) is 1>
					Pending Basket
				<cfelse>
					#StructCount(session.epos_archive)# Pending Baskets
				</cfif>
			</div>
		<cfelse>
			<style>
				.header_tabs li {padding:0 30px;}
			</style>
		</cfif>
	</cfif>
</cfoutput>