<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>غير مصرح بالدخول</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">

    {{-- Bootstrap --}}
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

    <style>
        body {
            background: #f4f6f9;
            font-family: "Tahoma", sans-serif;
        }
        .unauthorized-box {
            max-width: 420px;
            margin: 80px auto;
            padding: 25px 30px;
            background: #fff;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 3px 10px rgba(0,0,0,0.1);
        }
        .unauthorized-box h2 {
            color: #dc3545;
            font-size: 22px;
            margin-bottom: 10px;
        }
        .unauthorized-box p {
            color: #666;
            font-size: 15px;
            margin-bottom: 20px;
        }
        .btn-sm-custom {
            font-size: 14px;
            padding: 6px 16px;
        }
        .btn-group-custom {
            gap: 10px;
        }
    </style>
</head>
<body>

<div class="unauthorized-box">
    <h2>🚫 غير مصرح بالدخول</h2>
    <p>عذراً، لا تملك صلاحية الوصول إلى هذه الصفحة.</p>

    <div class="d-flex justify-content-center btn-group-custom">
        <a href="{{ $redirect_url ?? url('/') }}" class="btn btn-outline-primary btn-sm-custom">
            ⬅️ العودة
        </a>

        <a href="{{ route($logout_route ?? 'admin.logout') }}" 
            class="btn btn-outline-danger btn-sm-custom">
            🚪 تسجيل الخروج
            </a>
    </div>
</div>

</body>
</html>
