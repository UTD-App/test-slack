window.copyToClipboard = function (elementId) {
    const text = document.getElementById(elementId)?.textContent;
    if (text) {
        navigator.clipboard.writeText(text).then(() => {
            if (typeof toastr !== 'undefined') {
                toastr.success("Copied");
            } else {
                alert("Copied");
            }
        }).catch(err => {
            console.error("Failed to copy:", err);
        });
    }
};
