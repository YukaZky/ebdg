<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title') - GeoDesaConnect</title>
    <style>
        :root { color-scheme: light; --ink:#172033; --muted:#5d6878; --brand:#0c4da2; --line:#dce2ea; --danger:#b42318; }
        * { box-sizing:border-box; }
        body { margin:0; background:#f7f9fc; color:var(--ink); font-family:Arial,Helvetica,sans-serif; line-height:1.65; }
        header { background:#fff; border-bottom:1px solid var(--line); }
        header div, main { width:min(860px,calc(100% - 32px)); margin:auto; }
        header div { display:flex; align-items:center; justify-content:space-between; min-height:64px; }
        header a { color:var(--brand); text-decoration:none; font-weight:700; }
        main { background:#fff; margin-top:28px; margin-bottom:40px; padding:32px; border:1px solid var(--line); border-radius:8px; }
        h1 { margin:0 0 8px; font-size:30px; line-height:1.25; }
        h2 { margin:28px 0 8px; font-size:20px; }
        p, li { color:var(--muted); }
        .meta { margin-top:0; font-size:14px; }
        label { display:block; margin-top:16px; font-weight:700; }
        input[type=email], input[type=password] { width:100%; margin-top:6px; padding:12px; border:1px solid #b8c2cf; border-radius:6px; font:inherit; }
        .check { display:flex; gap:10px; align-items:flex-start; font-weight:400; }
        button { margin-top:20px; padding:12px 18px; border:0; border-radius:6px; background:var(--danger); color:#fff; font:inherit; font-weight:700; cursor:pointer; }
        .error { color:var(--danger); font-size:14px; }
        .notice { padding:14px; background:#fff4e5; border-left:4px solid #f59e0b; color:#704100; }
        @media (max-width:600px) { main { margin-top:0; border-width:0; border-radius:0; padding:24px 16px; } h1 { font-size:25px; } }
    </style>
</head>
<body>
<header><div><strong>GeoDesaConnect</strong><a href="{{ url('/') }}">Beranda</a></div></header>
<main>@yield('content')</main>
</body>
</html>
