$(document).ready(function() {
	$('a.delete_bucket').click(function() {
		bucket_info = $(this).parent().find("form.deletion");
		$.post('/control/delete', { bucket_name: bucket_info.find("input.bucket_name").val(), deletion_type: bucket_info.find("input.deletion_type").val()},
			function(data, textStatus, XMLHttpRequest) {
				if(XMLHttpRequest.status != 200 || textStatus != "success") {
					alert("Oh no! "+textStatus+"\n--------------------\n"+data+"\nXMLHttpRequest: "+XMLHttpRequest.status);
				} else {
					bucket_info.parent().parent().fadeOut('fast', function() {
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