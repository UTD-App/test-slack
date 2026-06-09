<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{  $appName }} - Meet New People & Go Live</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" integrity="sha512-pap7tB9iKkZrV8+WZgQ4a8PSULs2uR3bBjrEk1DThwSbWbQ4zX+9XbQ1tXEbJ0fJG2hnvGH+FvAb5N1yZ2lPGA==" crossorigin="anonymous" referrerpolicy="no-referrer" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css"/>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            /* Enhanced color scheme */
            --primary-color: {{ data_get($settings, 'app_primary_color', '#32e5ac') }};     
            --secondary-color:{{ data_get($settings, 'app_primary_color', '#ffffff') }};
            --accent-color: #06b6d4;
            --dark-bg: #0f0f23;
            --text-color: #1a1a2e;
            --text-light: {{ data_get($settings, 'text_header_color', '#fff') }};
            
            --background:{{ data_get($settings, 'background_color', '#fff') }};
            --background-alt:{{ data_get($settings, 'background_color', '#fff') }};
            --gradient-1: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            --gradient-2: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            --gradient-3: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            --gradient-4: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            overflow-x: hidden;
            color: var(--text-color);
            background: var(--background);
            transition: direction 0.3s;
        }

        /* RTL Support */
        body[dir="rtl"] {
            font-family: 'Cairo', 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }

        body[dir="rtl"] .hero-content,
        body[dir="rtl"] .feature-card,
        body[dir="rtl"] nav,
        body[dir="rtl"] .footer-section {
            text-align: right;
        }

        body[dir="rtl"] .logo-container {
            flex-direction: row-reverse;
        }

        body[dir="rtl"] .hero-buttons,
        body[dir="rtl"] .social-links,
        body[dir="rtl"] .app-stores {
            flex-direction: row-reverse;
        }

        body[dir="rtl"] .store-badge > div {
            text-align: right !important;
        }

        body[dir="rtl"] nav a:not(.download-btn)::after {
            left: auto;
            right: 0;
        }

        body[dir="rtl"] .footer-section a:hover {
            padding-left: 0;
            padding-right: 5px;
        }

        /* Preloader */
        .preloader {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 9999;
            transition: opacity 0.5s, visibility 0.5s;
        }

        .preloader.fade-out {
            opacity: 0;
            visibility: hidden;
        }

        .loader {
            width: 60px;
            height: 60px;
            border: 3px solid rgba(255,255,255,0.3);
            border-top-color: white;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* Language Switcher */
        .lang-switcher {
            position: relative;
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 8px 16px;
            background: rgba(124, 58, 237, 0.1);
            border-radius: 20px;
            cursor: pointer;
            transition: all 0.3s;
            border: 1px solid rgba(124, 58, 237, 0.2);
        }

        .lang-switcher:hover {
            background: rgba(124, 58, 237, 0.15);
            transform: translateY(-2px);
        }

        .lang-icon {
            width: 20px;
            height: 20px;
            opacity: 0.8;
        }

        .lang-current {
            font-weight: 600;
            color: var(--primary-color);
            font-size: 14px;
        }

        .lang-dropdown {
            position: absolute;
            top: 100%;
            margin-top: 10px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.15);
            overflow: hidden;
            opacity: 0;
            visibility: hidden;
            transform: translateY(-10px);
            transition: all 0.3s;
            z-index: 1000;
            min-width: 150px;
        }

        body[dir="rtl"] .lang-dropdown {
            right: 0;
        }

        body[dir="ltr"] .lang-dropdown {
            left: 0;
        }

        .lang-switcher.active .lang-dropdown {
            opacity: 1;
            visibility: visible;
            transform: translateY(0);
        }

        .lang-option {
            padding: 12px 20px;
            display: flex;
            align-items: center;
            gap: 10px;
            cursor: pointer;
            transition: all 0.3s;
            font-size: 14px;
        }

        .lang-option:hover {
            background: rgba(124, 58, 237, 0.1);
        }

        .lang-option.active {
            background: rgba(124, 58, 237, 0.15);
            color: var(--primary-color);
            font-weight: 600;
        }

        .lang-flag {
            width: 24px;
            height: 24px;
            border-radius: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
        }

        /* Animated Background */
        .animated-bg {
            position: fixed;
            width: 100%;
            height: 100%;
            top: 0;
            left: 0;
            z-index: -1;
            background: linear-gradient(45deg, #f3f4f6, #fafafe);
            overflow: hidden;
        }

        .bg-bubble {
            position: absolute;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            opacity: 0.05;
            animation: float-bubble 20s infinite ease-in-out;
        }

        @keyframes float-bubble {
            0%, 100% {
                transform: translate(0, 100vh) scale(0);
            }
            20% {
                transform: translate(100px, 80vh) scale(1);
            }
            40% {
                transform: translate(-100px, 60vh) scale(0.5);
            }
            60% {
                transform: translate(150px, 40vh) scale(1.2);
            }
            80% {
                transform: translate(-50px, 20vh) scale(0.8);
            }
        }

        /* Parallax Shapes */
        .parallax-shapes {
            position: absolute;
            width: 100%;
            height: 100%;
            overflow: hidden;
            z-index: 1;
        }

        .shape {
            position: absolute;
            opacity: 0.1;
            animation: float-shape 20s infinite ease-in-out;
            will-change: transform;
        }

        .shape1 {
            width: 300px;
            height: 300px;
            background: var(--gradient-1);
            border-radius: 50%;
            top: 10%;
            left: -150px;
            animation-delay: 0s;
        }

        body[dir="rtl"] .shape1 {
            left: auto;
            right: -150px;
        }

        .shape2 {
            width: 200px;
            height: 200px;
            background: var(--gradient-2);
            border-radius: 30% 70% 70% 30% / 30% 30% 70% 70%;
            top: 60%;
            right: -100px;
            animation-delay: 2s;
        }

        body[dir="rtl"] .shape2 {
            right: auto;
            left: -100px;
        }

        .shape3 {
            width: 150px;
            height: 150px;
            background: var(--gradient-3);
            clip-path: polygon(50% 0%, 0% 100%, 100% 100%);
            bottom: 20%;
            left: 20%;
            animation-delay: 4s;
        }

        body[dir="rtl"] .shape3 {
            left: auto;
            right: 20%;
        }

        @keyframes float-shape {
            0%, 100% { 
                transform: translate(0, 0) rotate(0deg) scale(1);
            }
            33% { 
                transform: translate(100px, -100px) rotate(120deg) scale(1.2);
            }
            66% { 
                transform: translate(-50px, 100px) rotate(240deg) scale(0.8);
            }
        }

        /* Header */
        header {
            position: fixed;
            top: 0;
            width: 100%;
            background: rgba(255, 255, 255, 0.9);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            padding: 20px 5%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            z-index: 1000;
            box-shadow: 0 2px 20px rgba(0,0,0,0.08);
            animation: slideDown 0.5s ease-out;
            transition: all 0.3s ease;
        }

        header.scrolled {
            padding: 15px 5%;
            box-shadow: 0 5px 30px rgba(0,0,0,0.1);
        }

        @keyframes slideDown {
            from {
                transform: translateY(-100%);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }

        .logo-container {
            display: flex;
            align-items: center;
            gap: 12px;
            cursor: pointer;
            transition: transform 0.3s;
        }

        .logo-container:hover {
            transform: scale(1.05);
        }

        .logo-icon {
            width: 45px;
            height: 45px;
            background: {{ data_get($settings, 'app_primary_color', '#32e5ac') }};
            /* background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); */
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            font-weight: bold;
            color: white;
            box-shadow: 0 4px 15px rgba(124, 58, 237, 0.3);
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0%, 100% { 
                transform: scale(1);
                box-shadow: 0 4px 15px rgba(124, 58, 237, 0.3);
            }
            50% { 
                transform: scale(1.05);
                box-shadow: 0 4px 25px rgba(124, 58, 237, 0.5);
            }
        }

        .logo-text {
            font-size: 28px;
            font-weight: 700;
            /* background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); */
            background: {{ data_get($settings, 'app_primary_color', '#32e5ac') }};
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        nav {
            display: flex;
            gap: 35px;
            align-items: center;
        }

        nav a {
            text-decoration: none;
            color: var(--text-light);
            font-weight: 500;
            transition: all 0.3s;
            position: relative;
        }

        nav a:not(.download-btn):hover {
            color: var(--primary-color);
        }

        nav a:not(.download-btn)::after {
            content: '';
            position: absolute;
            width: 0;
            height: 2px;
            bottom: -5px;
            left: 0;
            background: linear-gradient(90deg, var(--primary-color), var(--secondary-color));
            transition: width 0.3s;
        }

        nav a:not(.download-btn):hover::after {
            width: 100%;
        }

        .download-btn {
            background: {{ data_get($settings, 'app_primary_color', '#32e5ac') }};
            /* background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); */
            color: white !important;
            padding: 12px 30px;
            border-radius: 25px;
            font-weight: 600;
            transition: all 0.3s;
            box-shadow: 0 4px 15px rgba(124, 58, 237, 0.3);
            position: relative;
            overflow: hidden;
        }

        .download-btn::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
            transition: left 0.5s;
        }

        .download-btn:hover::before {
            left: 100%;
        }

        .download-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(124, 58, 237, 0.5);
        }

        /* Mobile Menu */
        .mobile-menu-btn {
            display: none;
            flex-direction: column;
            gap: 4px;
            cursor: pointer;
            z-index: 1001;
        }

        .mobile-menu-btn span {
            width: 25px;
            height: 3px;
            background: var(--primary-color);
            border-radius: 2px;
            transition: all 0.3s;
        }

        .mobile-menu-btn.active span:nth-child(1) {
            transform: rotate(45deg) translate(5px, 5px);
        }

        .mobile-menu-btn.active span:nth-child(2) {
            opacity: 0;
        }

        .mobile-menu-btn.active span:nth-child(3) {
            transform: rotate(-45deg) translate(7px, -6px);
        }

        /* Hero Section */
        .hero {
            margin-top: 80px;
            min-height: 100vh;
            /* background: linear-gradient(135deg, #7c3aed 0%, #ec4899 100%); */
            background: {{ data_get($settings, 'app_primary_color', '#32e5ac') }} ;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 60px 8%;
            position: relative;
            overflow: hidden;
        }

        body[dir="rtl"] .hero {
            flex-direction: row-reverse;
        }

        .hero-bg-pattern {
            position: absolute;
            width: 100%;
            height: 100%;
            opacity: 0.1;
            background-image: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.4'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
        }

        .hero-content {
            flex: 1;
            z-index: 2;
            color: white;
            animation: fadeInLeft 1s ease-out;
        }

        @keyframes fadeInLeft {
            from {
                opacity: 0;
                transform: translateX(-50px);
            }
            to {
                opacity: 1;
                transform: translateX(0);
            }
        }

        body[dir="rtl"] .hero-content {
            animation: fadeInRight 1s ease-out;
        }

        .hero-content h1 {
            font-size: 56px;
            margin-bottom: 20px;
            line-height: 1.2;
            animation: fadeInUp 0.8s ease-out 0.2s both;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
            min-height: 135px;
        }

        .hero-title-main {
            display: block;
            transition: all 0.6s ease;
        }

        .gradient-text {
            background: linear-gradient(90deg, #fff, #fbbf24);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            animation: gradient-shift 3s ease infinite;
            display: block;
            transition: all 0.6s ease;
        }

        @keyframes gradient-shift {
            0%, 100% { filter: hue-rotate(0deg); }
            50% { filter: hue-rotate(30deg); }
        }

        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .hero-content p {
            font-size: 20px;
            margin-bottom: 40px;
            opacity: 0.95;
            line-height: 1.6;
            animation: fadeInUp 0.8s ease-out 0.4s both;
            min-height: 100px;
            transition: all 0.6s ease;
        }

        .content-fade {
            animation: contentFade 0.6s ease;
        }

        @keyframes contentFade {
            0% { opacity: 1; transform: translateY(0); }
            50% { opacity: 0; transform: translateY(-10px); }
            100% { opacity: 1; transform: translateY(0); }
        }

        .hero-buttons {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
            animation: fadeInUp 0.8s ease-out 0.6s both;
        }

        .btn {
            padding: 15px 40px;
            border-radius: 30px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            border: none;
            transition: all 0.3s;
            text-decoration: none;
            display: inline-block;
            position: relative;
            overflow: hidden;
        }

        .btn::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 0;
            height: 0;
            border-radius: 50%;
            background: rgba(255,255,255,0.3);
            transform: translate(-50%, -50%);
            transition: width 0.6s, height 0.6s;
        }

        .btn:hover::before {
            width: 300px;
            height: 300px;
        }

        .btn-primary {
            background: white;
            color: var(--primary-color);
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }

        .btn-primary:hover {
            transform: translateY(-3px) scale(1.05);
            box-shadow: 0 8px 25px rgba(0,0,0,0.3);
        }

        .btn-secondary {
            background: transparent;
            color: white;
            border: 2px solid white;
        }

        .btn-secondary:hover {
            background: white;
            color: var(--primary-color);
        }

        .hero-image {
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 2;
            animation: fadeInRight 1s ease-out;
        }

        @keyframes fadeInRight {
            from {
                opacity: 0;
                transform: translateX(50px);
            }
            to {
                opacity: 1;
                transform: translateX(0);
            }
        }

        body[dir="rtl"] .hero-image {
            animation: fadeInLeft 1s ease-out;
        }

        .phone-mockup {
            width: 320px;
            height: 640px;
            background: linear-gradient(145deg, #1a1a2e, #16213e);
            border-radius: 45px;
            box-shadow: 0 30px 80px rgba(0,0,0,0.4), 
                        inset 0 0 0 2px rgba(255,255,255,0.1);
            padding: 18px;
            position: relative;
            animation: float 3s ease-in-out infinite;
        }

        @keyframes float {
            0%, 100% { 
                transform: translateY(0px) rotate(0deg);
            }
            25% { 
                transform: translateY(-15px) rotate(-2deg);
            }
            50% { 
                transform: translateY(-20px) rotate(0deg);
            }
            75% { 
                transform: translateY(-15px) rotate(2deg);
            }
        }

        .phone-notch {
            position: absolute;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            width: 120px;
            height: 25px;
            background: #0a0a14;
            border-radius: 0 0 20px 20px;
            z-index: 10;
        }

        .phone-screen {
            width: 100%;
            height: 100%;
            border-radius: 35px;
            overflow: hidden;
            position: relative;
            background: #000;
        }

        .slideshow {
            width: 100%;
            height: 100%;
            position: relative;
        }

        .slide-indicators {
            position: absolute;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            display: flex;
            gap: 8px;
            z-index: 10;
        }

        .slide-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.5);
            cursor: pointer;
            transition: all 0.3s;
        }

        .slide-dot.active {
            width: 24px;
            border-radius: 4px;
            background: white;
        }

        .slide-dot:hover {
            background: rgba(255, 255, 255, 0.8);
        }

        .slide {
            position: absolute;
            width: 100%;
            height: 100%;
            opacity: 0;
            transition: opacity 1s ease-in-out;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            color: white;
            font-weight: 600;
            font-size: 18px;
            padding: 20px;
            text-align: center;
            background-size: cover;
            background-position: center;
        }

        .slide.active {
            opacity: 1;
        }

        .slide1 {
            background-image: linear-gradient(rgba(103,126,234,0.8), rgba(118,75,162,0.8)), url('https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=400');
        }

        .slide2 {
            background-image: linear-gradient(rgba(240,147,251,0.8), rgba(245,87,108,0.8)), url('https://images.unsplash.com/photo-1577563908411-5077b6dc7624?w=400');
        }

        .slide3 {
            background-image: linear-gradient(rgba(79,172,254,0.8), rgba(0,242,254,0.8)), url('https://images.unsplash.com/photo-1543269865-cbf427effbad?w=400');
        }

        .slide4 {
            background-image: linear-gradient(rgba(67,233,123,0.8), rgba(56,249,215,0.8)), url('https://images.unsplash.com/photo-1530268729831-4b0b9e170218?w=400');
        }

        .slide-icon {
            font-size: 64px;
            margin-bottom: 20px;
            animation: bounceIn 1s ease-out;
            text-shadow: 0 4px 15px rgba(0,0,0,0.3);
        }

        @keyframes bounceIn {
            0% { 
                transform: scale(0); 
                opacity: 0; 
            }
            50% { 
                transform: scale(1.1); 
            }
            100% { 
                transform: scale(1); 
                opacity: 1; 
            }
        }

        /* Features Section */
        .features {
            padding: 100px 8%;
            background: var(--background-alt);
            position: relative;
        }

        .section-title {
            text-align: center;
            font-size: 42px;
            margin-bottom: 20px;
            color: var(--text-color);
            position: relative;
            display: inline-block;
            width: 100%;
        }

        .section-title::after {
            content: '';
            position: absolute;
            bottom: -10px;
            left: 50%;
            transform: translateX(-50%);
            width: 60px;
            height: 4px;
            background: {{ data_get($settings, 'app_primary_color', '#32e5ac') }};

            /* background: linear-gradient(90deg, var(--primary-color), var(--secondary-color)); */
            border-radius: 2px;
        }

        .section-subtitle {
            text-align: center;
            font-size: 18px;
            color: var(--text-light);
            margin-bottom: 60px;
            animation: fadeInUp 0.8s ease-out 0.2s both;
        }

        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 40px;
        }

        .feature-card {
                color: #383232;
            background: white;
            padding: 40px;
            border-radius: 20px;
            text-align: center;
            transition: all 0.4s;
            box-shadow: 0 5px 20px rgba(0,0,0,0.05);
            opacity: 0;
            transform: translateY(30px);
            border: 1px solid rgba(124, 58, 237, 0.1);
            position: relative;
            overflow: hidden;
        }

        .feature-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: {{ data_get($settings, 'app_primary_color', '#32e5ac') }};
            /* background: linear-gradient(90deg, var(--primary-color), var(--secondary-color)); */
            transform: scaleX(0);
            transition: transform 0.4s;
        }

        .feature-card:hover::before {
            transform: scaleX(1);
        }

        .feature-card.animate {
            animation: fadeInUp 0.6s ease-out forwards;
        }

        .feature-card:nth-child(1) { animation-delay: 0.1s; }
        .feature-card:nth-child(2) { animation-delay: 0.2s; }
        .feature-card:nth-child(3) { animation-delay: 0.3s; }
        .feature-card:nth-child(4) { animation-delay: 0.4s; }
        .feature-card:nth-child(5) { animation-delay: 0.5s; }
        .feature-card:nth-child(6) { animation-delay: 0.6s; }

        .feature-card:hover {
            transform: translateY(-15px);
            box-shadow: 0 20px 50px rgba(124, 58, 237, 0.2);
        }
       

        .feature-icon {
            width: 90px;
            height: 90px;
            background: {{ data_get($settings, 'app_primary_color', '#32e5ac') }};

            /* background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); */
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 25px;
            font-size: 40px;
            transition: all 0.4s;
            box-shadow: 0 10px 30px rgba(124, 58, 237, 0.3);
            position: relative;
        }

        .feature-icon img {
            width: 50px;
            height: 50px;
            filter: brightness(0) invert(1);
        }

        .feature-card:hover .feature-icon {
            transform: rotateY(360deg) scale(1.1);
            box-shadow: 0 15px 40px rgba(124, 58, 237, 0.4);
        }

        .feature-card h3 {
            font-size: 24px;
            margin-bottom: 15px;
            color: var(--text-color);
        }

        .feature-card p {
            color: #000000;
            line-height: 1.6;
        }

        /* Stats Section */
        .stats {
            background: {{ data_get($settings, 'app_primary_color', '#ffffff') }};
            /* background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); */
            padding: 80px 8%;
            color: white;
            position: relative;
            overflow: hidden;
        }

        .stats::before {
            content: '';
            position: absolute;
            width: 200%;
            height: 200%;
            top: -50%;
            left: -50%;
            background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.05'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
            animation: slide 20s linear infinite;
        }

        @keyframes slide {
            0% { transform: translate(0, 0); }
            100% { transform: translate(60px, 60px); }
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 40px;
            text-align: center;
            position: relative;
            z-index: 2;
        }

        .stat-item {
            opacity: 0;
            transform: scale(0.5);
        }

        .stat-item.animate {
            animation: scaleIn 0.6s ease-out forwards;
        }

        .stat-item:nth-child(1) { animation-delay: 0.2s; }
        .stat-item:nth-child(2) { animation-delay: 0.4s; }
        .stat-item:nth-child(3) { animation-delay: 0.6s; }
        .stat-item:nth-child(4) { animation-delay: 0.8s; }

        @keyframes scaleIn {
            to {
                opacity: 1;
                transform: scale(1);
            }
        }

        .stat-item h2 {
            font-size: 52px;
            margin-bottom: 10px;
            font-weight: 700;
            text-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }

        .stat-number {
            display: inline-block;
        }

        .stat-item p {
            font-size: 18px;
            opacity: 0.9;
        }

        /* Gallery Section */
        .gallery {
            padding: 100px 8%;
            background: {{ data_get($settings, 'background_color', '#fff') }};
        }

        .gallery-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 50px;
        }

        .gallery-item {
            position: relative;
            border-radius: 15px;
            overflow: hidden;
            height: 250px;
            cursor: pointer;
            transition: all 0.3s;
            opacity: 0;
            transform: scale(0.8);
        }

        .gallery-item.animate {
            animation: scaleIn 0.5s ease-out forwards;
        }

        .gallery-item:nth-child(1) { animation-delay: 0.1s; }
        .gallery-item:nth-child(2) { animation-delay: 0.2s; }
        .gallery-item:nth-child(3) { animation-delay: 0.3s; }
        .gallery-item:nth-child(4) { animation-delay: 0.4s; }

        .gallery-item img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.3s;
        }

        .gallery-item:hover img {
            transform: scale(1.1);
        }

        .gallery-overlay {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            background: linear-gradient(to top, rgba(0,0,0,0.8), transparent);
            padding: 20px;
            color: white;
            transform: translateY(100%);
            transition: transform 0.3s;
        }

        .gallery-item:hover .gallery-overlay {
            transform: translateY(0);
        }

        /* CTA Section */
        .cta {
            padding: 100px 8%;
            text-align: center;
            background: {{ data_get($settings, 'background_color', '#fff') }};
            /* background: linear-gradient(135deg, #fafafe 0%, #f3f4f6 100%); */
            position: relative;
            overflow: hidden;
        }

        .cta::before {
            content: '';
            position: absolute;
            width: 150%;
            height: 150%;
            background: radial-gradient(circle, var(--primary-color) 0%, transparent 70%);
            opacity: 0.05;
            top: -25%;
            left: -25%;
            animation: rotate 30s linear infinite;
        }

        @keyframes rotate {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .cta h2 {
            font-size: 42px;
            margin-bottom: 20px;
            color: var(--text-color);
            animation: fadeInUp 0.8s ease-out;
        }

        .cta p {
            font-size: 20px;
            color: var(--text-light);
            margin-bottom: 50px;
            animation: fadeInUp 0.8s ease-out 0.2s both;
        }

        .app-stores {
            display: flex;
            gap: 20px;
            justify-content: center;
            flex-wrap: wrap;
            animation: fadeInUp 0.8s ease-out 0.4s both;
        }

        .store-badge {
            display: inline-flex;
            align-items: center;
            gap: 12px;
            padding: 15px 35px;
            background: #000;
            color: white;
            border-radius: 12px;
            text-decoration: none;
            font-weight: 600;
            transition: all 0.3s;
            box-shadow: 0 5px 20px rgba(0,0,0,0.2);
            position: relative;
            overflow: hidden;
        }

        .store-badge::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
            transition: left 0.5s;
        }

        .store-badge:hover::before {
            left: 100%;
        }

        .store-badge:hover {
            transform: translateY(-5px) scale(1.05);
            box-shadow: 0 15px 40px rgba(0,0,0,0.3);
        }

        .store-icon {
            width: 30px;
            height: 30px;
        }

        /* Footer */
        footer {
            background: linear-gradient(135deg, #0f172a 0%, #1a1a2e 100%);
            color: white;
            padding: 60px 8% 30px;
        }

        .footer-content {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 40px;
            margin-bottom: 40px;
        }

        .footer-section h3 {
            margin-bottom: 20px;
            font-size: 20px;
        }

        .footer-section ul {
            list-style: none;
        }

        .footer-section ul li {
            margin-bottom: 12px;
        }

        .footer-section a {
            color: #94a3b8;
            text-decoration: none;
            transition: all 0.3s;
        }

        .footer-section a:hover {
            color: var(--primary-color);
            padding-left: 5px;
        }

        .social-links {
            display: flex;
            gap: 15px;
            margin-top: 20px;
        }

        .social-icon {
            width: 45px;
            height: 45px;
            background: rgba(255,255,255,0.1);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s;
            font-size: 20px;
            text-decoration: none;
            color: white;
        }

        .social-icon:hover {
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            transform: translateY(-5px) rotate(360deg);
        }

        .footer-bottom {
            text-align: center;
            padding-top: 30px;
            border-top: 1px solid rgba(255,255,255,0.1);
            color: #94a3b8;
        }

        /* Responsive */
        @media (max-width: 968px) {
            .hero {
                flex-direction: column;
                text-align: center;
                padding: 40px 5%;
            }

            body[dir="rtl"] .hero {
                flex-direction: column;
            }

            .hero-content h1 {
                font-size: 40px;
            }

            .hero-buttons {
                justify-content: center;
            }

            body[dir="rtl"] .hero-buttons {
                flex-direction: row;
            }

            .phone-mockup {
                margin-top: 40px;
                width: 280px;
                height: 560px;
            }

            nav {
                position: fixed;
                top: 0;
                right: -100%;
                width: 250px;
                height: 100vh;
                background: white;
                flex-direction: column;
                padding: 100px 30px;
                box-shadow: -5px 0 20px rgba(0,0,0,0.1);
                transition: right 0.3s;
            }

            body[dir="rtl"] nav {
                right: auto;
                left: -100%;
                box-shadow: 5px 0 20px rgba(0,0,0,0.1);
                transition: left 0.3s;
            }

            nav.active {
                right: 0;
            }

            body[dir="rtl"] nav.active {
                right: auto;
                left: 0;
            }

            .mobile-menu-btn {
                display: flex;
            }

            .section-title {
                font-size: 32px;
            }

            .features-grid {
                grid-template-columns: 1fr;
            }

            .gallery-grid {
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            }

            .app-stores {
                flex-direction: column;
                align-items: center;
            }

            body[dir="rtl"] .app-stores {
                flex-direction: column;
            }
        }

        /* Custom Cursor */
        .cursor {
            width: 20px;
            height: 20px;
            border: 2px solid var(--primary-color);
            border-radius: 50%;
            position: fixed;
            pointer-events: none;
            z-index: 9998;
            transition: transform 0.1s;
            mix-blend-mode: difference;
        }

        .cursor-follower {
            width: 40px;
            height: 40px;
            background: var(--primary-color);
            opacity: 0.2;
            border-radius: 50%;
            position: fixed;
            pointer-events: none;
            z-index: 9997;
            transition: transform 0.2s;
        }

        /* Scroll Progress Bar */
        .scroll-progress {
            position: fixed;
            top: 0;
            left: 0;
            width: 0%;
            height: 3px;
            background: {{ data_get($settings, 'app_primary_color', '#32e5ac') }};
            /* background: linear-gradient(90deg, var(--primary-color), var(--secondary-color)); */
            z-index: 1001;
            transition: width 0.1s;
        }

        body[dir="rtl"] .scroll-progress {
            left: auto;
            right: 0;
        }


        .social-links {
            display: flex;
            gap: 10px;
        }

        .social-icon {
            display: inline-flex;
            justify-content: center;
            align-items: center;
            width: 50px;
            height: 50px;
            border-radius: 50%;
            color: white;
            font-size: 24px;
            transition: transform 0.3s, box-shadow 0.3s;
            text-decoration: none;
        }

        .social-icon:hover {
            transform: scale(1.15);
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        }

        .whatsapp { background-color: #25D366; }
        .facebook { background-color: #1877F2; }
        .twitter { background-color: #1DA1F2; }

        .social-icon {
            display: inline-flex;
            justify-content: center;
            align-items: center;
            width: 50px;
            height: 50px;
            border-radius: 50%;
            font-weight: bold;
            font-size: 24px;
            color: #ffffff;
            text-decoration: none;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .whatsapp-text-icon {
            background-color: #25D366; /* لون واتساب */
            color: #ffffff;            /* الحرف أبيض */
            box-shadow: 0 2px 6px rgba(0,0,0,0.2);
        }

        .whatsapp-text-icon:hover {
            transform: scale(1.15);
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        }

        .social-icon svg {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: #f1f1f1;
            padding: 6px;
            transition: transform 0.3s ease;
        }

        .social-icon svg:hover {
            transform: scale(1.1);
            background: #e0e0e0;
        }
        .logo-icon img{
            width: 100% !important;
        }

    </style>
</head>
<body dir="ltr">
    <!-- Preloader -->
    <div class="preloader" id="preloader">
        <div class="loader"></div>
    </div>

    <!-- Scroll Progress -->
    <div class="scroll-progress" id="scrollProgress"></div>

    <!-- Custom Cursor -->
    <div class="cursor" id="cursor"></div>
    <div class="cursor-follower" id="cursorFollower"></div>

    <!-- Animated Background -->
    <div class="animated-bg" id="animatedBg"></div>

    <!-- Header -->
    <header id="header">


        <div class="logo-container">

            <div class="logo-icon">
                @if(!empty($logo))
                    <img src="{{ $logo }}" alt="{{ $appName }}" class="h-12 w-12 object-contain rounded-full">
                @else
                        {{ strtoupper(substr($appName, 0, 1)) }}
                @endif
            </div>
            <div class="logo-text">{{  $appName }}</div>
        </div>
        <nav id="nav">
            <a href="#features" data-translate="nav.features">Features</a>
            <a href="#gallery" data-translate="nav.gallery">Gallery</a>
            <a href="{{ @$settings['about_us_link'] }}" data-translate="nav.about">About</a>
            <div class="lang-switcher" id="langSwitcher">
                <svg class="lang-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <path d="M2 12h20M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z"></path>
                </svg>
                <span class="lang-current" id="currentLang">EN</span>
                <div class="lang-dropdown">
                    <div class="lang-option" data-lang="en">
                        <span class="lang-flag">🇬🇧</span>
                        <span>English</span>
                    </div>
                    <div class="lang-option" data-lang="ar">
                        <span class="lang-flag">🇸🇦</span>
                        <span>العربية</span>
                    </div>
                </div>
            </div>
            <a href="#download" class="download-btn" data-translate="nav.download">Download Now</a>
        </nav>
        <div class="mobile-menu-btn" id="mobileMenuBtn">
            <span></span>
            <span></span>
            <span></span>
        </div>
    </header>

    <!-- Hero Section -->
    <section class="hero">
        <div class="hero-bg-pattern"></div>
        <div class="parallax-shapes">
            <div class="shape shape1"></div>
            <div class="shape shape2"></div>
            <div class="shape shape3"></div>
        </div>
        <div class="hero-content">
            <h1>
                <span class="hero-title-main" id="heroTitleMain">Meet New People</span>
                <span class="gradient-text" id="heroTitleSub">& Go Live</span>
            </h1>
            <p id="heroDescription">Connect with millions worldwide through live streaming, video calls, and instant messaging. Break language barriers with real-time translation and discover new friends from over 100 countries.</p>
            <div class="hero-buttons">
                <a href="#download" class="btn btn-primary" data-translate="hero.btn1">Download Now</a>
                <a href="#features" class="btn btn-secondary" data-translate="hero.btn2">Explore Features</a>
            </div>
        </div>
        <div class="hero-image">
            <div class="phone-mockup">
                <div class="phone-notch"></div>
                <div class="phone-screen">
                    <div class="slideshow">
                        <div class="slide slide1 active">
                            <div class="slide-icon">📹</div>
                            <div data-translate="slide1.text">Go Live<br>Stream Instantly</div>
                        </div>
                        <div class="slide slide2">
                            <div class="slide-icon">💬</div>
                            <div data-translate="slide2.text">Chat & Connect<br>With Friends</div>
                        </div>
                        <div class="slide slide3">
                            <div class="slide-icon">🎉</div>
                            <div data-translate="slide3.text">Group Parties<br>Up to 9 People</div>
                        </div>
                        <div class="slide slide4">
                            <div class="slide-icon">🌍</div>
                            <div data-translate="slide4.text">100+ Countries<br>One Community</div>
                        </div>
                        <div class="slide-indicators">
                            <span class="slide-dot active" data-slide="0"></span>
                            <span class="slide-dot" data-slide="1"></span>
                            <span class="slide-dot" data-slide="2"></span>
                            <span class="slide-dot" data-slide="3"></span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section class="features" id="features">
        <h2 class="section-title" data-translate="features.title">Amazing Features</h2>
        <p class="section-subtitle" data-translate="features.subtitle">Everything you need to connect and share with the world</p>
        <div class="features-grid">
            <div class="feature-card">
                <div class="feature-icon">
                    <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolygon points='23 7 16 12 23 17 23 7'%3E%3C/polygon%3E%3Crect x='1' y='5' width='15' height='14' rx='2' ry='2'%3E%3C/rect%3E%3C/svg%3E" alt="Live">
                </div>
                <h3 data-translate="feature1.title">Live Streaming</h3>
                <p data-translate="feature1.desc">Go live instantly and share your talents with the world. Watch thousands of exciting broadcasts daily from talented streamers worldwide.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">
                    <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z'%3E%3C/path%3E%3C/svg%3E" alt="Chat">
                </div>
                <h3 data-translate="feature2.title">Instant Chat</h3>
                <p data-translate="feature2.desc">Connect through text, voice, and video chat. Real-time translation makes communication seamless across languages.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">
                    <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2'%3E%3C/path%3E%3Ccircle cx='9' cy='7' r='4'%3E%3C/circle%3E%3Cpath d='M23 21v-2a4 4 0 0 0-3-3.87'%3E%3C/path%3E%3Cpath d='M16 3.13a4 4 0 0 1 0 7.75'%3E%3C/path%3E%3C/svg%3E" alt="Groups">
                </div>
                <h3 data-translate="feature3.title">Group Parties</h3>
                <p data-translate="feature3.desc">Host or join group video calls with up to 9 people. Create unforgettable moments with friends from around the globe.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">
                    <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Ccircle cx='12' cy='12' r='10'%3E%3C/circle%3E%3Cline x1='2' y1='12' x2='22' y2='12'%3E%3C/line%3E%3Cpath d='M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z'%3E%3C/path%3E%3C/svg%3E" alt="Global">
                </div>
                <h3 data-translate="feature4.title">Global Community</h3>
                <p data-translate="feature4.desc">Meet new friends from over 100 countries. Discover diverse cultures and make meaningful connections worldwide.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">
                    <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='4 17 10 11 4 5'%3E%3C/polyline%3E%3Cline x1='12' y1='19' x2='20' y2='19'%3E%3C/line%3E%3C/svg%3E" alt="Translate">
                </div>
                <h3 data-translate="feature5.title">Real-Time Translation</h3>
                <p data-translate="feature5.desc">Built-in translation breaks down language barriers, allowing you to communicate effortlessly with anyone, anywhere.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">
                    <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3' y='3' width='18' height='18' rx='2' ry='2'%3E%3C/rect%3E%3Ccircle cx='8.5' cy='8.5' r='1.5'%3E%3C/circle%3E%3Cpolyline points='21 15 16 10 5 21'%3E%3C/polyline%3E%3C/svg%3E" alt="Share">
                </div>
                <h3 data-translate="feature6.title">Share Moments</h3>
                <p data-translate="feature6.desc">Post photos and short videos to share your daily life. Build your followers and increase your popularity.</p>
            </div>
        </div>
    </section>

    <!-- Gallery Section -->
    <section class="gallery" id="gallery">
        <h2 class="section-title" data-translate="gallery.title">Experience {{ $appName }}</h2>
        <p class="section-subtitle" data-translate="gallery.subtitle">See how millions connect and share every day</p>
        <div class="gallery-grid">
            <div class="gallery-item">
                <img src="https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=400&h=300&fit=crop" alt="Live Streaming">
                <div class="gallery-overlay">
                    <h3 data-translate="gallery1.title">Live Streaming</h3>
                    <p data-translate="gallery1.desc">Broadcast to the world</p>
                </div>
            </div>
            <div class="gallery-item">
                <img src="https://images.unsplash.com/photo-1577563908411-5077b6dc7624?w=400&h=300&fit=crop" alt="Video Chat">
                <div class="gallery-overlay">
                    <h3 data-translate="gallery2.title">Video Chat</h3>
                    <p data-translate="gallery2.desc">Face-to-face connections</p>
                </div>
            </div>
            <div class="gallery-item">
                <img src="https://images.unsplash.com/photo-1543269865-cbf427effbad?w=400&h=300&fit=crop" alt="Group Parties">
                <div class="gallery-overlay">
                    <h3 data-translate="gallery3.title">Group Parties</h3>
                    <p data-translate="gallery3.desc">Fun with friends</p>
                </div>
            </div>
            <div class="gallery-item">
                <img src="https://images.unsplash.com/photo-1530268729831-4b0b9e170218?w=400&h=300&fit=crop" alt="Global Community">
                <div class="gallery-overlay">
                    <h3 data-translate="gallery4.title">Global Community</h3>
                    <p data-translate="gallery4.desc">Connect worldwide</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Stats Section -->
    <section class="stats" id="stats">
        <div class="stats-grid">
            <div class="stat-item">
                <h2>
                    {{ numToStringNew( (int)@$settings['landing_users_count'] ) ?? 0 }}
                    @if((int)@$settings['landing_users_count'] > 0)
                        <span>+</span>
                    @endif
                </h2>
                <p data-translate="stats1.desc">Active Users</p>
            </div>
            <div class="stat-item">
                <h2>{{numToStringNew( (int)(@$settings['landing_countries_count'] )?? 0) }}
                    @if((int)@$settings['landing_countries_count'] > 0)
                        <span>+</span>
                    @endif</h2>
                <p data-translate="stats2.desc">Countries</p>
            </div>
            <div class="stat-item">
                <h2>{{numToStringNew( @$settings['landing_live_count'] )?? 0 }}
                    @if((int)@$settings['landing_live_count'] > 0)
                        <span>+</span>
                    @endif
                </h2>
                <p data-translate="stats3.desc">Daily Streams</p>
            </div>
            <div class="stat-item">
                <h2>24/7</h2>
                <p data-translate="stats4.desc">Support</p>
            </div>
        </div>
    </section>

    <!-- CTA Section -->
    <section class="cta" id="download">
        <h2 data-translate="cta.title">Ready to Join {{ $appName }}?</h2>
        <p data-translate="cta.subtitle">Download now and start connecting with millions of people worldwide</p>
        <div class="app-stores">
            <a href="{{ @$settings['ios_link'] }}" class="store-badge">
                <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='white'%3E%3Cpath d='M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z'/%3E%3C/svg%3E" alt="Apple" class="store-icon">
                <div style="text-align: left;">
                    <div style="font-size: 10px; opacity: 0.8;" data-translate="store.apple1">Download on the</div>
                    <div data-translate="store.apple2">App Store</div>
                </div>
            </a>
            <a href="{{ @$settings['android_link'] ?? '' }}" class="store-badge">
                <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='white'%3E%3Cpath d='M3,20.5A0.5,0.5 0 0,1 2.5,20V3.5A0.5,0.5 0 0,1 3,3H10.75L21,13.25A0.5,0.5 0 0,1 21,14H10.5L2.5,20A0.5,0.5 0 0,1 3,20.5M10.55,2L2.04,19.25L10.3,13H19.96L10.55,2Z'/%3E%3C/svg%3E" alt="Google Play" class="store-icon">
                <div style="text-align: left;">
                    <div style="font-size: 10px; opacity: 0.8;" data-translate="store.google1">GET IT ON</div>
                    <div data-translate="store.google2">Google Play</div>
                </div>
            </a>
            <a href="{{ @@$settings['gallery_app_link'] ?? '' }}" class="store-badge">
                <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='white'%3E%3Cpath d='M5,3H19A2,2 0 0,1 21,5V19A2,2 0 0,1 19,21H5A2,2 0 0,1 3,19V5A2,2 0 0,1 5,3M12,8A3,3 0 0,0 9,11A3,3 0 0,0 12,14A3,3 0 0,0 15,11A3,3 0 0,0 12,8M12,16A5,5 0 0,1 7,11H5A7,7 0 0,0 12,18A7,7 0 0,0 19,11H17A5,5 0 0,1 12,16Z'/%3E%3C/svg%3E" alt="Huawei" class="store-icon">
                <div style="text-align: left;">
                    <div style="font-size: 10px; opacity: 0.8;" data-translate="store.huawei1">EXPLORE IT ON</div>
                    <div data-translate="store.huawei2">AppGallery</div>
                </div>
            </a>
        </div>
    </section>

    <!-- Footer -->
    <footer>
        <div class="footer-content">
            <div class="footer-section">
                <div class="logo-container">
                    <div class="logo-icon">
                        @if(!empty($logo))
                            <img src="{{ $logo }}" alt="{{ $appName }}" class="h-12 w-12 object-contain rounded-full">
                        @else
                                {{ strtoupper(substr($appName, 0, 1)) }}
                        @endif
                    </div>
                
                <div class="logo-text">{{ $appName }}</div>
                </div>
                <p style="margin-top: 20px; color: #94a3b8;" data-translate="footer.desc">Connect with millions worldwide through live streaming and social discovery.</p>
                
                <div class="social-links flex gap-4">

                @if(!empty(@$settings['facebook_link']))
                    <a href="{{ @$settings['facebook_link'] }}" target="_blank" class="social-icon">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="#1877F2" xmlns="http://www.w3.org/2000/svg">
                            <path d="M22 12C22 6.477 17.523 2 12 2S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.507 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.462h-1.26c-1.243 0-1.63.772-1.63 1.562V12h2.773l-.443 2.891h-2.33v6.987C18.343 21.128 22 16.991 22 12z"/>
                        </svg>
                    </a>
                @endif

                @if(!empty(@$settings['twitter_link']))
                    <a href="{{ @$settings['twitter_link'] }}" target="_blank" class="social-icon">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="#1DA1F2" xmlns="http://www.w3.org/2000/svg">
                            <path d="M23 3a10.9 10.9 0 01-3.14.86 4.48 4.48 0 001.95-2.48 9.07 9.07 0 01-2.88 1.1 4.52 4.52 0 00-7.69 4.12A12.86 12.86 0 013 4s-4 9 5 13a13 13 0 01-8 2c9 5 20 0 20-11.5a4.5 4.5 0 00-.08-.83A7.72 7.72 0 0023 3z"/>
                        </svg>
                    </a>
                @endif

                @if(!empty(@$settings['whatsapp_link']))
            <a href="{{ @$settings['whatsapp_link'] }}" target="_blank" class="social-icon whatsapp">
                <i class="fab fa-whatsapp"></i>
            </a>
    @endif


            </div>


            </div>
            <div class="footer-section">
                <h3 data-translate="footer.product">Product</h3>
                <ul>
                    <li><a href="#" data-translate="footer.features">Features</a></li>
                    <li><a href="#" data-translate="footer.download">Download</a></li>
                    <li><a href="#" data-translate="footer.safety">Safety</a></li>
                    <li><a href="#" data-translate="footer.community">Community</a></li>
                    <li><a href="#" data-translate="footer.blog">Blog</a></li>
                </ul>
            </div>
            <div class="footer-section">
                <h3 data-translate="footer.company">Company</h3>
                <ul>
                    <li><a href="#" data-translate="footer.about">About Us</a></li>
                    <li><a href="#" data-translate="footer.careers">Careers</a></li>
                    <li><a href="#" data-translate="footer.press">Press</a></li>
                    <li><a href="#" data-translate="footer.contact">Contact</a></li>
                    <li><a href="#" data-translate="footer.partners">Partners</a></li>
                </ul>
            </div>
            <div class="footer-section">
                <h3 data-translate="footer.support">Support</h3>
                <ul>
                    <li><a href="#" data-translate="footer.help">Help Center</a></li>
                    <li><a href="#" data-translate="footer.terms">Terms of Service</a></li>
                    <li><a href="#" data-translate="footer.privacy">Privacy Policy</a></li>
                    <li><a href="#" data-translate="footer.guidelines">Guidelines</a></li>
                    <li><a href="#" data-translate="footer.report">Report Issue</a></li>
                </ul>
            </div>
        </div>
        <div class="footer-bottom">
            <p data-translate="footer.copyright">&copy; 2024 {{ $appName }}. All rights reserved. Built for connecting people worldwide.</p>
        </div>
    </footer>

    <script>
        // Language Translations
        const translations = {
            en: {
                nav: {
                    features: "Features",
                    gallery: "Gallery",
                    about: "About",
                    download: "Download Now"
                },
                hero: {
                    btn1: "Download Now",
                    btn2: "Explore Features"
                },
                slide1: {
                    text: "Go Live<br>Stream Instantly"
                },
                slide2: {
                    text: "Chat & Connect<br>With Friends"
                },
                slide3: {
                    text: "Group Parties<br>Up to 9 People"
                },
                slide4: {
                    text: "100+ Countries<br>One Community"
                },
                slideContent: [
                    {
                        titleMain: "Go Live Instantly",
                        titleSub: "Stream Your Talent",
                        description: "Broadcast your moments to millions of viewers worldwide. Share your talents, hobbies, and daily adventures with a global audience. Get real-time reactions, gifts, and build your fan community with our powerful streaming platform."
                    },
                    {
                        titleMain: "Chat & Connect",
                        titleSub: "Make Real Friends",
                        description: "Send messages, voice notes, and video calls to friends around the world. Our real-time translation breaks down language barriers, making it easy to connect with anyone, anywhere. Build meaningful relationships that last."
                    },
                    {
                        titleMain: "Join Group Parties",
                        titleSub: "Fun Together",
                        description: "Host amazing video parties with up to 9 friends simultaneously. Play games, celebrate special moments, or just hang out together. Create private rooms for intimate gatherings or go public to meet new people with similar interests."
                    },
                    {
                        titleMain: "Global Community",
                        titleSub: "100+ Countries",
                        description: "Discover diverse cultures and perspectives from over 100 countries. Learn new languages, explore different traditions, and expand your worldview. Every connection is an opportunity to grow and share experiences across borders."
                    }
                ],
                features: {
                    title: "Amazing Features",
                    subtitle: "Everything you need to connect and share with the world"
                },
                feature1: {
                    title: "Live Streaming",
                    desc: "Go live instantly and share your talents with the world. Watch thousands of exciting broadcasts daily from talented streamers worldwide."
                },
                feature2: {
                    title: "Instant Chat",
                    desc: "Connect through text, voice, and video chat. Real-time translation makes communication seamless across languages."
                },
                feature3: {
                    title: "Group Parties",
                    desc: "Host or join group video calls with up to 9 people. Create unforgettable moments with friends from around the globe."
                },
                feature4: {
                    title: "Global Community",
                    desc: "Meet new friends from over 100 countries. Discover diverse cultures and make meaningful connections worldwide."
                },
                feature5: {
                    title: "Real-Time Translation",
                    desc: "Built-in translation breaks down language barriers, allowing you to communicate effortlessly with anyone, anywhere."
                },
                feature6: {
                    title: "Share Moments",
                    desc: "Post photos and short videos to share your daily life. Build your followers and increase your popularity."
                },
                gallery: {
                    title: "Experience {{ $appName }}",
                    subtitle: "See how millions connect and share every day"
                },
                gallery1: { title: "Live Streaming", desc: "Broadcast to the world" },
                gallery2: { title: "Video Chat", desc: "Face-to-face connections" },
                gallery3: { title: "Group Parties", desc: "Fun with friends" },
                gallery4: { title: "Global Community", desc: "Connect worldwide" },
                stats: { million: "M+" },
                stats1: { desc: "Active Users" },
                stats2: { desc: "Countries" },
                stats3: { desc: "Daily Streams" },
                stats4: { desc: "Support" },
                cta: {
                    title: "Ready to Join {{ $appName }}?",
                    subtitle: "Download now and start connecting with millions of people worldwide"
                },
                store: {
                    apple1: "Download on the",
                    apple2: "App Store",
                    google1: "GET IT ON",
                    google2: "Google Play",
                    huawei1: "EXPLORE IT ON",
                    huawei2: "AppGallery"
                },
                footer: {
                    desc: "Connect with millions worldwide through live streaming and social discovery.",
                    product: "Product",
                    features: "Features",
                    download: "Download",
                    safety: "Safety",
                    community: "Community",
                    blog: "Blog",
                    company: "Company",
                    about: "About Us",
                    careers: "Careers",
                    press: "Press",
                    contact: "Contact",
                    partners: "Partners",
                    support: "Support",
                    help: "Help Center",
                    terms: "Terms of Service",
                    privacy: "Privacy Policy",
                    guidelines: "Guidelines",
                    report: "Report Issue",
                    copyright: "© 2024 {{ $appName }}. All rights reserved. Built for connecting people worldwide."
                }
            },
            ar: {
                nav: {
                    features: "المميزات",
                    gallery: "المعرض",
                    about: "عن التطبيق",
                    download: "حمل الآن"
                },
                hero: {
                    btn1: "حمل الآن",
                    btn2: "استكشف المميزات"
                },
                slide1: {
                    text: "بث مباشر<br>ابدأ البث فوراً"
                },
                slide2: {
                    text: "دردش وتواصل<br>مع الأصدقاء"
                },
                slide3: {
                    text: "حفلات جماعية<br>حتى 9 أشخاص"
                },
                slide4: {
                    text: "أكثر من 100 دولة<br>مجتمع واحد"
                },
                slideContent: [
                    {
                        titleMain: "بث مباشر فوري",
                        titleSub: "اعرض موهبتك",
                        description: "قم ببث لحظاتك لملايين المشاهدين حول العالم. شارك مواهبك وهواياتك ومغامراتك اليومية مع جمهور عالمي. احصل على ردود فعل فورية وهدايا وابن مجتمع معجبيك من خلال منصة البث القوية."
                    },
                    {
                        titleMain: "دردش وتواصل",
                        titleSub: "كوّن صداقات حقيقية",
                        description: "أرسل الرسائل والملاحظات الصوتية ومكالمات الفيديو للأصدقاء حول العالم. تكسر الترجمة الفورية حواجز اللغة، مما يجعل من السهل التواصل مع أي شخص في أي مكان. ابن علاقات ذات مغزى تدوم."
                    },
                    {
                        titleMain: "انضم للحفلات الجماعية",
                        titleSub: "متعة مشتركة",
                        description: "استضف حفلات فيديو رائعة مع ما يصل إلى 9 أصدقاء في وقت واحد. العب الألعاب، احتفل باللحظات الخاصة، أو اقض الوقت معاً. أنشئ غرفاً خاصة للتجمعات الحميمة أو انضم للعامة لمقابلة أشخاص جدد."
                    },
                    {
                        titleMain: "مجتمع عالمي",
                        titleSub: "أكثر من 100 دولة",
                        description: "اكتشف ثقافات ووجهات نظر متنوعة من أكثر من 100 دولة. تعلم لغات جديدة، واستكشف تقاليد مختلفة، ووسع آفاقك. كل اتصال هو فرصة للنمو ومشاركة التجارب عبر الحدود."
                    }
                ],
                features: {
                    title: "مميزات رائعة",
                    subtitle: "كل ما تحتاجه للتواصل والمشاركة مع العالم"
                },
                feature1: {
                    title: "البث المباشر",
                    desc: "اذهب مباشرة على الهواء وشارك مواهبك مع العالم. شاهد آلاف البث المباشر المثير يومياً من مذيعين موهوبين حول العالم."
                },
                feature2: {
                    title: "الدردشة الفورية",
                    desc: "تواصل عبر الرسائل النصية والصوتية ومكالمات الفيديو. الترجمة الفورية تجعل التواصل سلساً عبر اللغات."
                },
                feature3: {
                    title: "حفلات جماعية",
                    desc: "استضف أو انضم لمكالمات فيديو جماعية تضم حتى 9 أشخاص. اخلق لحظات لا تُنسى مع الأصدقاء من جميع أنحاء العالم."
                },
                feature4: {
                    title: "مجتمع عالمي",
                    desc: "قابل أصدقاء جدد من أكثر من 100 دولة. اكتشف ثقافات متنوعة وكوّن روابط ذات مغزى حول العالم."
                },
                feature5: {
                    title: "ترجمة فورية",
                    desc: "الترجمة المدمجة تكسر حواجز اللغة، مما يتيح لك التواصل بسهولة مع أي شخص في أي مكان."
                },
                feature6: {
                    title: "شارك اللحظات",
                    desc: "انشر الصور ومقاطع الفيديو القصيرة لمشاركة حياتك اليومية. ابن متابعيك وزد من شعبيتك."
                },
                gallery: {
                    title: "تجربة {{ $appName }}",
                    subtitle: "شاهد كيف يتواصل ويشارك الملايين كل يوم"
                },
                gallery1: { title: "البث المباشر", desc: "البث للعالم" },
                gallery2: { title: "دردشة الفيديو", desc: "تواصل وجهاً لوجه" },
                gallery3: { title: "حفلات جماعية", desc: "متعة مع الأصدقاء" },
                gallery4: { title: "مجتمع عالمي", desc: "تواصل عالمياً" },
                stats: { million: "م+" },
                stats1: { desc: "مستخدم نشط" },
                stats2: { desc: "دولة" },
                stats3: { desc: "بث يومي" },
                stats4: { desc: "دعم" },
                cta: {
                    title: "جاهز للانضمام إلى {{ $appName }}؟",
                    subtitle: "حمل الآن وابدأ التواصل مع ملايين الأشخاص حول العالم"
                },
                store: {
                    apple1: "حمله من",
                    apple2: "App Store",
                    google1: "احصل عليه من",
                    google2: "Google Play",
                    huawei1: "اكتشفه على",
                    huawei2: "AppGallery"
                },
                footer: {
                    desc: "تواصل مع الملايين حول العالم من خلال البث المباشر والاكتشاف الاجتماعي.",
                    product: "المنتج",
                    features: "المميزات",
                    download: "تحميل",
                    safety: "الأمان",
                    community: "المجتمع",
                    blog: "المدونة",
                    company: "الشركة",
                    about: "من نحن",
                    careers: "الوظائف",
                    press: "الصحافة",
                    contact: "اتصل بنا",
                    partners: "الشركاء",
                    support: "الدعم",
                    help: "مركز المساعدة",
                    terms: "شروط الخدمة",
                    privacy: "سياسة الخصوصية",
                    guidelines: "الإرشادات",
                    report: "الإبلاغ عن مشكلة",
                    copyright: "© 2024 {{ $appName }}. جميع الحقوق محفوظة. صُمم لربط الناس حول العالم."
                }
            }
            // Add more languages here following the same structure
            // Example for adding French:
            // fr: { ... }
        };

        // Current language (default to English)
        let currentLanguage = 'en';

        // Function to update text based on language
        function updateLanguage(lang) {
            currentLanguage = lang;
            const elements = document.querySelectorAll('[data-translate]');
            
            elements.forEach(element => {
                const key = element.getAttribute('data-translate');
                const keys = key.split('.');
                let translation = translations[lang];
                
                for (let k of keys) {
                    if (translation[k]) {
                        translation = translation[k];
                    }
                }
                
                if (typeof translation === 'string') {
                    element.innerHTML = translation;
                }
            });

            // Update document direction
            document.body.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
            document.documentElement.setAttribute('lang', lang === 'ar' ? 'ar' : 'en');
            
            // Update current language display
            document.getElementById('currentLang').textContent = lang.toUpperCase();
            
            // Update active language option
            document.querySelectorAll('.lang-option').forEach(option => {
                option.classList.remove('active');
                if (option.getAttribute('data-lang') === lang) {
                    option.classList.add('active');
                }
            });

            // Store language preference (fallback for non-localStorage environment)
            if (typeof window.currentLang === 'undefined') {
                window.currentLang = lang;
            }
        }

        // Language switcher functionality
        const langSwitcher = document.getElementById('langSwitcher');
        const langOptions = document.querySelectorAll('.lang-option');

        langSwitcher.addEventListener('click', (e) => {
            e.stopPropagation();
            langSwitcher.classList.toggle('active');
        });

        document.addEventListener('click', () => {
            langSwitcher.classList.remove('active');
        });

        langOptions.forEach(option => {
            option.addEventListener('click', (e) => {
                e.stopPropagation();
                const lang = option.getAttribute('data-lang');
                updateLanguage(lang);
                langSwitcher.classList.remove('active');
            });
        });

        // Initialize with default language
        updateLanguage(currentLanguage);

        // Preloader
        window.addEventListener('load', () => {
            setTimeout(() => {
                document.getElementById('preloader').classList.add('fade-out');
            }, 500);
        });

        // Animated Background Bubbles
        function createBubbles() {
            const bg = document.getElementById('animatedBg');
            for (let i = 0; i < 5; i++) {
                const bubble = document.createElement('div');
                bubble.className = 'bg-bubble';
                bubble.style.width = Math.random() * 200 + 100 + 'px';
                bubble.style.height = bubble.style.width;
                bubble.style.left = Math.random() * 100 + '%';
                bubble.style.animationDuration = (Math.random() * 10 + 10) + 's';
                bubble.style.animationDelay = Math.random() * 5 + 's';
                bg.appendChild(bubble);
            }
        }
        createBubbles();

        // Parallax Effect
        document.addEventListener('mousemove', (e) => {
            const shapes = document.querySelectorAll('.shape');
            const x = e.clientX / window.innerWidth;
            const y = e.clientY / window.innerHeight;

            shapes.forEach((shape, index) => {
                const speed = (index + 1) * 20;
                const xPos = (x - 0.5) * speed;
                const yPos = (y - 0.5) * speed;
                shape.style.transform = `translate(${xPos}px, ${yPos}px)`;
            });
        });

        // Custom Cursor
        const cursor = document.getElementById('cursor');
        const cursorFollower = document.getElementById('cursorFollower');

        document.addEventListener('mousemove', (e) => {
            cursor.style.left = e.clientX + 'px';
            cursor.style.top = e.clientY + 'px';
            
            setTimeout(() => {
                cursorFollower.style.left = e.clientX - 10 + 'px';
                cursorFollower.style.top = e.clientY - 10 + 'px';
            }, 100);
        });

        document.querySelectorAll('a, button').forEach(elem => {
            elem.addEventListener('mouseenter', () => {
                cursor.style.transform = 'scale(1.5)';
                cursorFollower.style.transform = 'scale(1.5)';
            });
            elem.addEventListener('mouseleave', () => {
                cursor.style.transform = 'scale(1)';
                cursorFollower.style.transform = 'scale(1)';
            });
        });

        // Scroll Progress Bar
        window.addEventListener('scroll', () => {
            const scrollHeight = document.documentElement.scrollHeight - window.innerHeight;
            const scrollProgress = (window.scrollY / scrollHeight) * 100;
            document.getElementById('scrollProgress').style.width = scrollProgress + '%';
        });

        // Header Scroll Effect
        window.addEventListener('scroll', () => {
            const header = document.getElementById('header');
            if (window.scrollY > 50) {
                header.classList.add('scrolled');
            } else {
                header.classList.remove('scrolled');
            }
        });

        // Mobile Menu
        const mobileMenuBtn = document.getElementById('mobileMenuBtn');
        const nav = document.getElementById('nav');

        mobileMenuBtn.addEventListener('click', () => {
            mobileMenuBtn.classList.toggle('active');
            nav.classList.toggle('active');
        });

        // Slideshow with Dynamic Content
        let currentSlide = 0;
        const slides = document.querySelectorAll('.slide');
        const slideDots = document.querySelectorAll('.slide-dot');
        const totalSlides = slides.length;
        let slideInterval;

        function updateHeroContent(index) {
            const content = translations[currentLanguage].slideContent[index];
            const heroTitleMain = document.getElementById('heroTitleMain');
            const heroTitleSub = document.getElementById('heroTitleSub');
            const heroDescription = document.getElementById('heroDescription');
            
            // Add fade animation class
            heroTitleMain.classList.add('content-fade');
            heroTitleSub.classList.add('content-fade');
            heroDescription.classList.add('content-fade');
            
            // Change content after a short delay
            setTimeout(() => {
                heroTitleMain.textContent = content.titleMain;
                heroTitleSub.textContent = content.titleSub;
                heroDescription.textContent = content.description;
                
                // Remove animation class
                setTimeout(() => {
                    heroTitleMain.classList.remove('content-fade');
                    heroTitleSub.classList.remove('content-fade');
                    heroDescription.classList.remove('content-fade');
                }, 600);
            }, 300);
        }

        function updateDots(index) {
            slideDots.forEach(dot => dot.classList.remove('active'));
            if (slideDots[index]) {
                slideDots[index].classList.add('active');
            }
        }

        function showSlide(index) {
            slides.forEach(slide => slide.classList.remove('active'));
            slides[index].classList.add('active');
            updateHeroContent(index);
            updateDots(index);
        }

        function nextSlide() {
            currentSlide = (currentSlide + 1) % totalSlides;
            showSlide(currentSlide);
        }

        function startSlideshow() {
            slideInterval = setInterval(nextSlide, 5000);
        }

        function stopSlideshow() {
            clearInterval(slideInterval);
        }

        // Start slideshow
        startSlideshow();

        // Dot navigation
        slideDots.forEach((dot, index) => {
            dot.addEventListener('click', () => {
                stopSlideshow();
                currentSlide = index;
                showSlide(currentSlide);
                startSlideshow();
            });
        });

        // Keyboard navigation for slideshow
        document.addEventListener('keydown', (e) => {
            if (e.key === 'ArrowRight') {
                stopSlideshow();
                nextSlide();
                startSlideshow();
            } else if (e.key === 'ArrowLeft') {
                stopSlideshow();
                currentSlide = (currentSlide - 1 + totalSlides) % totalSlides;
                showSlide(currentSlide);
                startSlideshow();
            }
        });

        // Smooth Scroll
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                    // Close mobile menu if open
                    mobileMenuBtn.classList.remove('active');
                    nav.classList.remove('active');
                }
            });
        });

        // Intersection Observer for Animations
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate');
                }
            });
        }, observerOptions);

        // Observe elements
        document.querySelectorAll('.feature-card, .stat-item, .gallery-item').forEach(item => {
            observer.observe(item);
        });

        // Animated Counter for Stats
        function animateCounter(element, target) {
            let current = 0;
            const increment = target / 50;
            const timer = setInterval(() => {
                current += increment;
                if (current >= target) {
                    element.textContent = target;
                    clearInterval(timer);
                } else {
                    element.textContent = Math.floor(current);
                }
            }, 30);
        }

        // Trigger counter animation when stats section is visible
        const statsObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const counters = entry.target.querySelectorAll('.stat-number');
                    counters.forEach(counter => {
                        const target = parseInt(counter.getAttribute('data-target'));
                        if (!counter.classList.contains('counted')) {
                            counter.classList.add('counted');
                            animateCounter(counter, target);
                        }
                    });
                }
            });
        }, observerOptions);

        const statsSection = document.querySelector('.stats');
        if (statsSection) {
            statsObserver.observe(statsSection);
        }

        // Add ripple effect to buttons
        document.querySelectorAll('.btn, .store-badge').forEach(button => {
            button.addEventListener('click', function(e) {
                const ripple = document.createElement('span');
                ripple.style.position = 'absolute';
                ripple.style.width = '0';
                ripple.style.height = '0';
                ripple.style.borderRadius = '50%';
                ripple.style.background = 'rgba(255,255,255,0.5)';
                ripple.style.transform = 'translate(-50%, -50%)';
                ripple.style.pointerEvents = 'none';
                
                const rect = this.getBoundingClientRect();
                ripple.style.left = (e.clientX - rect.left) + 'px';
                ripple.style.top = (e.clientY - rect.top) + 'px';
                
                this.appendChild(ripple);
                
                ripple.animate([
                    { width: '0', height: '0', opacity: 1 },
                    { width: '300px', height: '300px', opacity: 0 }
                ], {
                    duration: 600,
                    easing: 'ease-out'
                });
                
                setTimeout(() => ripple.remove(), 600);
            });
        });

        // Add tilt effect to feature cards
        document.querySelectorAll('.feature-card').forEach(card => {
            card.addEventListener('mousemove', (e) => {
                const rect = card.getBoundingClientRect();
                const x = e.clientX - rect.left;
                const y = e.clientY - rect.top;
                
                const centerX = rect.width / 2;
                const centerY = rect.height / 2;
                
                const rotateX = (y - centerY) / 10;
                const rotateY = (centerX - x) / 10;
                
                card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-5px)`;
            });
            
            card.addEventListener('mouseleave', () => {
                card.style.transform = '';
            });
        });

        // console.log('Tempo Landing Page - Multi-language support initialized!');
    </script>
</body>
</html>