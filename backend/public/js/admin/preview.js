function openPreview(id) {
    // Construct the URL based on the record ID
    var url = '/preview/admin/login'; // Change this URL based on your routing structure
    let token = $('input[name="_token"]').val();

    $.ajax({
        url: "/admin/create-preview-user",
        method: 'POST',
        data: {
            _token: token,
            role_id: id
        },
        success: function (response) {

            console.log(response)
            window.open(response.url, '_blank');

        },
        error: function (xhr) {
            console.log(xhr)
            alert('Un-handling error');
        }
    });
    // Open the URL in a new tab
}
