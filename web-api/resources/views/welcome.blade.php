<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Smart Attendance</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            min-height: 100vh;
            background: #0f172a;
            color: #f1f5f9;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 2rem;
        }

        .card {
            width: 100%;
            max-width: 480px;
            text-align: center;
        }

        .badge {
            display: inline-block;
            font-size: 0.7rem;
            font-weight: 600;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            color: #f59e0b;
            background: rgba(245, 158, 11, 0.12);
            border: 1px solid rgba(245, 158, 11, 0.25);
            border-radius: 99px;
            padding: 0.3rem 0.85rem;
            margin-bottom: 1.75rem;
        }

        .logo {
            font-size: 2.5rem;
            font-weight: 800;
            letter-spacing: -0.03em;
            color: #fff;
            line-height: 1.1;
            margin-bottom: 0.5rem;
        }

        .logo span {
            color: #f59e0b;
        }

        .tagline {
            font-size: 1rem;
            color: #94a3b8;
            margin-bottom: 2.5rem;
            line-height: 1.6;
        }

        .divider {
            width: 40px;
            height: 3px;
            background: #f59e0b;
            border-radius: 2px;
            margin: 0 auto 2.5rem;
        }

        .features {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0.75rem;
            margin-bottom: 2.5rem;
            text-align: left;
        }

        .feature {
            background: rgba(255,255,255,0.04);
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 10px;
            padding: 0.875rem 1rem;
            font-size: 0.8rem;
            color: #cbd5e1;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .feature-icon {
            font-size: 1rem;
            flex-shrink: 0;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            background: #f59e0b;
            color: #0f172a;
            font-weight: 700;
            font-size: 0.9rem;
            padding: 0.85rem 2rem;
            border-radius: 10px;
            text-decoration: none;
            transition: background 0.15s, transform 0.15s;
            width: 100%;
            justify-content: center;
        }

        .btn:hover {
            background: #fbbf24;
            transform: translateY(-1px);
        }

        .btn svg {
            width: 16px;
            height: 16px;
        }

        .footer {
            margin-top: 2rem;
            font-size: 0.75rem;
            color: #475569;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="badge">Sistem Absensi Berbasis Mobile</div>

        <div class="logo">Smart <span>Attendance</span></div>

        <p class="tagline">
            Platform manajemen kehadiran karyawan<br>berbasis GPS dan validasi HR
        </p>

        <div class="divider"></div>

        <div class="features">
            <div class="feature">
                <span class="feature-icon">👤</span>
                Manajemen Karyawan
            </div>
            <div class="feature">
                <span class="feature-icon">🏢</span>
                Data Kantor
            </div>
            <div class="feature">
                <span class="feature-icon">✅</span>
                Validasi Absensi
            </div>
            <div class="feature">
                <span class="feature-icon">📅</span>
                Hari Libur
            </div>
            <div class="feature">
                <span class="feature-icon">📊</span>
                Dashboard HR
            </div>
            <div class="feature">
                <span class="feature-icon">📋</span>
                Log Perubahan
            </div>
        </div>

        <a href="/admin" class="btn">
            Masuk ke Dashboard Admin
            <svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M3 8h10M9 4l4 4-4 4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
        </a>

        <p class="footer">Smart Attendance &copy; {{ date('Y') }} &mdash; Kelompok 6</p>
    </div>
</body>
</html>
