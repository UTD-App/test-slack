{{-- Renders an email template's HTML in an isolated, script-disabled iframe.
     $html is escaped into the srcdoc attribute (the browser un-escapes it). --}}
<div style="width:100%;">
    <iframe
        srcdoc="{{ $html }}"
        sandbox=""
        style="width:100%;height:70vh;border:1px solid #e5e7eb;border-radius:8px;background:#fff;"
    ></iframe>
</div>
