$(document).ready(function() {
	$('a.delete_user').click(function() {
		user_info = $(this).parent().find("form.deletion");
		$.post('/control/users/delete', { login: user_info.find("input.user_login").val() },
			function(data, textStatus, XMLHttpRequest) {
				if(XMLHttpRequest.status != 200 || textStatus != "success") {
					alert("Oh no! "+textStatus+"\n--------------------\n"+data+"\nXMLHttpRequest: "+XMLHttpRequest.status);
				} else {
					user_info.parent().parent().fadeOut('fast', function() {
						$(this).remove();
					});
				}
			}
		);
	});
});
$(document).ajaxError(function(event, XMLHttpRequest, ajaxOptions, thrownError) {
	if(XMLHttpRequest.status == 500) {
		alert(XMLHttpRequest.responseText);
	}
});