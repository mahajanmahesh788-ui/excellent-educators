<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>{{ $title }}</title>
    <style>
        body { font-family: ui-sans-serif, system-ui, sans-serif; background: #f4f1ea; color: #122033; padding: 48px 24px; }
        .card { max-width: 560px; margin: 0 auto; background: #fff; border-radius: 16px; padding: 28px; box-shadow: 0 8px 30px rgba(18,32,51,.08); }
        h1 { font-size: 22px; margin: 0 0 12px; }
        p { line-height: 1.5; margin: 0; color: #5e6a78; }
        .ok { color: #0f766e; }
        .bad { color: #b42318; }
    </style>
</head>
<body>
    <div class="card">
        <h1 class="{{ $ok ? 'ok' : 'bad' }}">{{ $title }}</h1>
        <p>{{ $message }}</p>
    </div>
</body>
</html>
