function extracted() {
    // Prevent multiple submissions
    let submitButton = $('#submitButton');
    if (submitButton.prop('disabled')) {
        console.log('Form submission already in progress');
        return false;
    }

    // Collect CSRF token and amount value
    let token = $('input[name="_token"]').val();
    let amount = $('#amount').val();
    let type = $('#type').val();
    let link_type = $('#link_type').val();

    // Disable submit button and show loading text
    submitButton.attr('disabled', true).text('Loading...');

    // Send data using AJAX
    $.ajax({
        url: "/admin/save-payment-with-method",
        method: 'POST',
        data: {
            _token: token,
            amount: amount,
            type: type,
            link_type: link_type
        },
        success: function (response) {
            if (response.status == 0) {
               return $('#responseMessage').html('<div class="alert alert-danger">Error: ' + response.message + '</div>');
            }
            // Enable submit button and reset text
            submitButton.attr('disabled', false).text('Save');

            // Handle the success response (e.g., open a payment URL)
            console.log('Response received:', response);
            
            let paymentUrl = null;
            
            // Check for different response formats
            if (typeof response === 'string') {
                paymentUrl = response;
            } else if (response && response.payment_url) {
                paymentUrl = response.payment_url;
            } else if (response && response.data && response.data.payment_url) {
                paymentUrl = response.data.payment_url;
            } else if (response && response.url) {
                paymentUrl = response.url;
            }
            
            console.log('Extracted payment URL:', paymentUrl);
            
            if (paymentUrl && typeof paymentUrl === 'string') {
                var popup = window.open(paymentUrl);
                if (popup == null || typeof (popup) == 'undefined') {
                    alert('Please allow popups for this website');
                } else {
                    popup.focus();
                }
            } else {
                console.error('Could not extract payment URL from response:', response);
                $('#responseMessage').html('<div class="alert alert-danger">Error: Could not get payment URL</div>');
            }
        },
        error: function (xhr) {
            // Re-enable submit button and reset text
            submitButton.attr('disabled', false).text('Save');

            // Display error message
            $('#responseMessage').html('<div class="alert alert-danger">Error: ' + xhr.responseText + '</div>');
        }
    });
    return false;
}

$(document).ready(function() {


    $('#paymentForm').on('submit', function(e) {
        e.preventDefault();

        return extracted();

    });
});
