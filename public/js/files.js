$(document).ready(function() {
	$('a.delete_file').click(function() {
		file_info = $(this).parent().find("form.deletion");
		$.post('/control/delete', { bucket_name: file_info.find("input.bucket_name").val(), file_name: file_info.find("input.file_name").val(), deletion_type: file_info.find("input.deletion_type").val()},
			function(data, textStatus, XMLHttpRequest) {
				if(XMLHttpRequest.status != 200 || textStatus != "success") {
					alert("Oh no! "+textStatus+"\n--------------------\n"+data+"\nXMLHttpRequest: "+XMLHttpRequest.status);
				} else {
					// Tons many parents. :(
					file_info.parent().parent().parent().fadeOut('fast', function() {
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