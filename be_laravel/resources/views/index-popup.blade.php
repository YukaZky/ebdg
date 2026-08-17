@extends('index')

@section('content')
    @parent

    @if (isset($slides) && !$slides->isEmpty())
        <div id="app-download-popup" class="app-download-popup" aria-hidden="true">
            <div class="app-download-popup__backdrop" data-popup-close></div>

            <div class="app-download-popup__dialog" role="dialog" aria-modal="true" aria-labelledby="app-download-popup-title">
                <button type="button" class="app-download-popup__close" data-popup-close aria-label="Tutup popup">
                    &times;
                </button>

                <div class="app-download-popup__slides">
                    @foreach ($slides as $slide)
                        <article class="app-download-popup__slide {{ $loop->first ? 'is-active' : '' }}" data-popup-slide>
                            <div class="app-download-popup__image-wrap">
                                <img
                                    src="{{ asset('uploads/slides/' . $slide->image) }}"
                                    alt="{{ $slide->title }}"
                                    class="app-download-popup__image"
                                >
                            </div>

                            <div class="app-download-popup__content">
                                @if (!empty($slide->tagline))
                                    <span class="app-download-popup__tagline">{{ $slide->tagline }}</span>
                                @endif

                                <h2 id="app-download-popup-title" class="app-download-popup__title">
                                    {{ $slide->title }}
                                </h2>

                                @if (!empty($slide->subtitle))
                                    <p class="app-download-popup__subtitle">{{ $slide->subtitle }}</p>
                                @endif
                            </div>
                        </article>
                    @endforeach
                </div>

                @if ($slides->count() > 1)
                    <div class="app-download-popup__dots" aria-label="Navigasi slide">
                        @foreach ($slides as $slide)
                            <button
                                type="button"
                                class="app-download-popup__dot {{ $loop->first ? 'is-active' : '' }}"
                                data-popup-dot="{{ $loop->index }}"
                                aria-label="Tampilkan slide {{ $loop->iteration }}"
                            ></button>
                        @endforeach
                    </div>
                @endif

                <div class="app-download-popup__footer">
                    <a href="{{ route('app.download.apk') }}" class="app-download-popup__download" download>
                        <span class="app-download-popup__download-icon">&#8681;</span>
                        Download Here
                    </a>
                    <small>Download aplikasi GeoDesaConnect untuk pengalaman yang lebih lengkap.</small>
                </div>
            </div>
        </div>

        <style>
            body.app-download-popup-open {
                overflow: hidden;
            }

            .app-download-popup {
                position: fixed;
                inset: 0;
                z-index: 99999;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 20px;
                opacity: 0;
                visibility: hidden;
                transition: opacity .25s ease, visibility .25s ease;
            }

            .app-download-popup.is-visible {
                opacity: 1;
                visibility: visible;
            }

            .app-download-popup__backdrop {
                position: absolute;
                inset: 0;
                background: rgba(6, 18, 35, .72);
                backdrop-filter: blur(4px);
            }

            .app-download-popup__dialog {
                position: relative;
                z-index: 1;
                width: min(560px, 100%);
                max-height: calc(100vh - 40px);
                overflow: auto;
                background: #ffffff;
                border-radius: 22px;
                box-shadow: 0 26px 70px rgba(0, 0, 0, .28);
                transform: translateY(18px) scale(.98);
                transition: transform .25s ease;
            }

            .app-download-popup.is-visible .app-download-popup__dialog {
                transform: translateY(0) scale(1);
            }

            .app-download-popup__close {
                position: absolute;
                top: 12px;
                right: 12px;
                z-index: 5;
                width: 38px;
                height: 38px;
                border: 0;
                border-radius: 50%;
                background: rgba(255, 255, 255, .94);
                color: #0c2442;
                font-size: 28px;
                line-height: 1;
                cursor: pointer;
                box-shadow: 0 4px 16px rgba(0, 0, 0, .15);
            }

            .app-download-popup__slide {
                display: none;
            }

            .app-download-popup__slide.is-active {
                display: block;
                animation: popupSlideFade .35s ease;
            }

            .app-download-popup__image-wrap {
                width: 100%;
                aspect-ratio: 16 / 10;
                background: #eef3f8;
                overflow: hidden;
                border-radius: 22px 22px 0 0;
            }

            .app-download-popup__image {
                width: 100%;
                height: 100%;
                display: block;
                object-fit: cover;
            }

            .app-download-popup__content {
                padding: 22px 26px 10px;
                text-align: center;
            }

            .app-download-popup__tagline {
                display: inline-block;
                margin-bottom: 7px;
                color: #0c4da2;
                font-size: 12px;
                font-weight: 800;
                letter-spacing: .08em;
                text-transform: uppercase;
            }

            .app-download-popup__title {
                margin: 0;
                color: #0c2442;
                font-size: clamp(24px, 5vw, 34px);
                line-height: 1.12;
                font-weight: 800;
            }

            .app-download-popup__subtitle {
                margin: 10px 0 0;
                color: #607086;
                font-size: 15px;
                line-height: 1.55;
            }

            .app-download-popup__dots {
                display: flex;
                align-items: center;
                justify-content: center;
                gap: 7px;
                padding: 4px 20px 8px;
            }

            .app-download-popup__dot {
                width: 8px;
                height: 8px;
                padding: 0;
                border: 0;
                border-radius: 999px;
                background: #c8d3df;
                cursor: pointer;
                transition: width .2s ease, background .2s ease;
            }

            .app-download-popup__dot.is-active {
                width: 24px;
                background: #0c4da2;
            }

            .app-download-popup__footer {
                padding: 10px 26px 26px;
                text-align: center;
            }

            .app-download-popup__download {
                width: 100%;
                min-height: 52px;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                gap: 9px;
                border-radius: 14px;
                background: #0c4da2;
                color: #fff !important;
                text-decoration: none;
                font-size: 16px;
                font-weight: 800;
                box-shadow: 0 12px 24px rgba(12, 77, 162, .22);
                transition: transform .2s ease, box-shadow .2s ease, background .2s ease;
            }

            .app-download-popup__download:hover {
                background: #083d82;
                transform: translateY(-1px);
                box-shadow: 0 14px 28px rgba(12, 77, 162, .28);
            }

            .app-download-popup__download-icon {
                font-size: 22px;
                line-height: 1;
            }

            .app-download-popup__footer small {
                display: block;
                margin-top: 10px;
                color: #7b8795;
                font-size: 12px;
                line-height: 1.45;
            }

            @keyframes popupSlideFade {
                from { opacity: .35; transform: translateX(8px); }
                to { opacity: 1; transform: translateX(0); }
            }

            @media (max-width: 576px) {
                .app-download-popup {
                    padding: 14px;
                }

                .app-download-popup__dialog {
                    border-radius: 18px;
                    max-height: calc(100vh - 28px);
                }

                .app-download-popup__image-wrap {
                    aspect-ratio: 4 / 3;
                    border-radius: 18px 18px 0 0;
                }

                .app-download-popup__content {
                    padding: 18px 18px 8px;
                }

                .app-download-popup__footer {
                    padding: 8px 18px 20px;
                }
            }
        </style>

        <script>
            document.addEventListener('DOMContentLoaded', function () {
                const popup = document.getElementById('app-download-popup');
                if (!popup) return;

                const slides = Array.from(popup.querySelectorAll('[data-popup-slide]'));
                const dots = Array.from(popup.querySelectorAll('[data-popup-dot]'));
                const closeButtons = popup.querySelectorAll('[data-popup-close]');
                let currentIndex = 0;
                let timer = null;

                const showSlide = function (index) {
                    if (!slides.length) return;

                    currentIndex = (index + slides.length) % slides.length;

                    slides.forEach(function (slide, slideIndex) {
                        slide.classList.toggle('is-active', slideIndex === currentIndex);
                    });

                    dots.forEach(function (dot, dotIndex) {
                        dot.classList.toggle('is-active', dotIndex === currentIndex);
                    });
                };

                const stopAutoSlide = function () {
                    if (timer) {
                        window.clearInterval(timer);
                        timer = null;
                    }
                };

                const startAutoSlide = function () {
                    stopAutoSlide();
                    if (slides.length > 1) {
                        timer = window.setInterval(function () {
                            showSlide(currentIndex + 1);
                        }, 4500);
                    }
                };

                const closePopup = function () {
                    popup.classList.remove('is-visible');
                    popup.setAttribute('aria-hidden', 'true');
                    document.body.classList.remove('app-download-popup-open');
                    stopAutoSlide();
                };

                closeButtons.forEach(function (button) {
                    button.addEventListener('click', closePopup);
                });

                dots.forEach(function (dot) {
                    dot.addEventListener('click', function () {
                        showSlide(Number(dot.dataset.popupDot || 0));
                        startAutoSlide();
                    });
                });

                document.addEventListener('keydown', function (event) {
                    if (event.key === 'Escape' && popup.classList.contains('is-visible')) {
                        closePopup();
                    }
                });

                showSlide(0);
                window.requestAnimationFrame(function () {
                    popup.classList.add('is-visible');
                    popup.setAttribute('aria-hidden', 'false');
                    document.body.classList.add('app-download-popup-open');
                    startAutoSlide();
                });
            });
        </script>
    @endif
@endsection
