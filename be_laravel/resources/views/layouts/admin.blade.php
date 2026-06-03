<!doctype html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ config('app.name', 'Laravel') }}</title>

    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <meta name="author" content="surfside media" />
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
    <link rel="stylesheet" type="text/css" href="{{ asset('css/animate.min.css') }}">
    <link rel="stylesheet" type="text/css" href="{{ asset('css/animation.css') }}">
    <link rel="stylesheet" type="text/css" href="{{ asset('css/bootstrap.css') }}">
    <link rel="stylesheet" type="text/css" href="{{ asset('css/bootstrap-select.min.css') }}">
    <link rel="stylesheet" type="text/css" href="{{ asset('css/style.css') }}">
    <link rel="stylesheet" href="{{ asset('font/fonts.css') }}">
    <link rel="stylesheet" href="{{ asset('icon/style.css') }}">
    <link rel="shortcut icon" href="{{ asset('images/favicon.ico') }}">
    <link rel="apple-touch-icon-precomposed" href="{{ asset('images/favicon.ico') }}">
    <link rel="stylesheet" type="text/css" href="{{ asset('css/sweetalert.min.css') }}">
    <link rel="stylesheet" type="text/css" href="{{ asset('css/custom.css') }}">
    @stack('styles')

</head>
<style>

</style>
</style>

<body class="body">
    <div id="wrapper">
        <div id="page" class="">
            <div class="layout-wrap">

                <div class="section-menu-left">
                    <div class="box-logo">
                        <a href="{{ route('home.index') }}" id="site-logo-inner">
                            <img src="{{ $about_us_data && $about_us_data->logo_image ? asset('uploads/about/' . $about_us_data->logo_image) : asset('assets/images/logo.png') }}" 
                                alt="Logo Usaha"
                                class="logo__image d-block" />
                        </a>
                        <div class="button-show-hide">
                            <i class="icon-menu-left"></i>
                        </div>
                    </div>
                    <div class="center">

                        <div class="center-item">
                            <ul class="menu-list">
                                <li class="menu-item">
                                    <a href="{{ route('home.index') }}" class="">
                                        <div class="icon"><i class="icon-arrow-left"></i></div>
                                        <div class="text">Kembali</div>
                                    </a>
                                </li>
                            </ul>
                            <div class="center-heading">Daftar Fitur Admin</div>

                            <ul class="menu-list">
                                <li class="menu-item">
                                    <a href="{{ route('admin.index') }}" class="">
                                        <div class="icon"><i class="icon-grid"></i></div>
                                        <div class="text">Menu Utama</div>
                                    </a>
                                </li>
                            </ul>
                        </div>
                        <div class="center-item">
                            <ul class="menu-list">
                                <li class="menu-item has-children">
                                    <a href="javascript:void(0);" class="menu-item-button">
                                        <div class="icon"><i class="icon-shopping-cart"></i></div>
                                        <div class="text">Produk</div>
                                    </a>
                                    <ul class="sub-menu">
                                        <li class="sub-menu-item">
                                            <a href="{{ route('admin.product.add') }}" class="">
                                                <div class="text">Tambah Produk</div>
                                            </a>
                                        </li>
                                        <li class="sub-menu-item">
                                            <a href="{{ route('admin.products') }}" class="">
                                                <div class="text">Daftar Produk</div>
                                            </a>
                                        </li>
                                    </ul>
                                </li>
                                <li class="menu-item has-children">
                                    <a href="javascript:void(0);" class="menu-item-button">
                                        <div class="icon"><i class="icon-layers"></i></div>
                                        <div class="text">Merek</div>
                                    </a>
                                    <ul class="sub-menu">
                                        <li class="sub-menu-item">
                                            <a href="{{ route('admin.brand.add') }}" class="">
                                                <div class="text">Tambah Merek</div>
                                            </a>
                                        </li>
                                        <li class="sub-menu-item">
                                            <a href="{{ route('admin.brands') }}" class="">
                                                <div class="text">Daftar Merek</div>
                                            </a>
                                        </li>
                                    </ul>
                                </li>
                                <li class="menu-item has-children">
                                    <a href="javascript:void(0);" class="menu-item-button">
                                        <div class="icon"><i class="icon-layers"></i></div>
                                        <div class="text">Kategori</div>
                                    </a>
                                    <ul class="sub-menu">
                                        <li class="sub-menu-item">
                                            <a href="{{ route('admin.category.add') }}" class="">
                                                <div class="text">Tambah Kategori</div>
                                            </a>
                                        </li>
                                        <li class="sub-menu-item">
                                            <a href="{{ route('admin.categories') }}" class="">
                                                <div class="text">Daftar Kategori</div>
                                            </a>
                                        </li>
                                    </ul>
                                </li>

                                <li class="menu-item has-children">
                                    <a href="javascript:void(0);" class="menu-item-button">
                                        <div class="icon"><i class="icon-file-plus"></i></div>
                                        <div class="text">Pesanan</div>
                                    </a>
                                    <ul class="sub-menu">
                                        <li class="sub-menu-item">
                                            <a href="{{ route('admin.orders') }}" class="">
                                                <div class="text">Daftar Pesanan</div>
                                            </a>
                                        </li>
                                        {{-- Menu Laporan Pesanan ditambahkan di sini --}}
                                        <li class="sub-menu-item">
                                            <a href="{{ route('admin.orders.report') }}" class="">
                                                <div class="text">Laporan Pesanan</div>
                                            </a>
                                        </li>
                                    </ul>
                                </li>
                                <li class="menu-item">
                                    <a href="{{ route('admin.slides') }}" class="">
                                        <div class="icon"><i class="icon-image"></i></div>
                                        <div class="text">Produk Sorotan</div>
                                    </a>
                                </li>
                                <li class="menu-item">
                                    <a href="{{ route('admin.coupons') }}" class="">
                                        <div class="icon"><i class="icon-grid"></i></div>
                                        <div class="text">Kupon Diskon</div>
                                    </a>
                                </li>
                                <li class="menu-item">
                                    <a href="{{ route('admin.contacts') }}" class="">
                                        <div class="icon"><i class="icon-mail"></i></div>
                                        <div class="text">Pesan</div>
                                    </a>
                                </li>
                                <li class="menu-item">
                                    <a href="{{ route('admin.about.edit') }}" class="">
                                        <div class="icon"><i class="icon-info"></i></div>
                                        <div class="text">Profil Usaha</div>
                                    </a>
                                </li>
                                <li class="menu-item">
                                    <a href="{{ route('admin.whatsapp.edit') }}" class="">
                                        <div class="icon"><i class="icon-settings"></i></div>
                                        <div class="text">Pengaturan WA</div>
                                    </a>
                                </li>
                                <li class="menu-item has-children">
                                    <a href="javascript:void(0);" class="menu-item-button">
                                        <div class="icon"><i class="icon-user"></i></div>
                                        <div class="text">Pengguna</div>
                                    </a>
                                    <ul class="sub-menu">
                                        <li class="sub-menu-item">
                                            <a href="{{ route('admin.user.add') }}" class="">
                                                <div class="text">Tambah Pengguna</div>
                                            </a>
                                        </li>
                                        <li class="sub-menu-item">
                                            <a href="{{ route('admin.users') }}" class="">
                                                <div class="text">Daftar Pengguna</div>
                                            </a>
                                        </li>
                                    </ul>
                                </li>

                                <li class="menu-item">
                                    <form method="POST" action="{{ route('logout') }}" id="logout-form">
                                        @csrf
                                        <a href="{{ route('logout') }}" class=""
                                            onclick="event.preventDefault();document.getElementById('logout-form').submit();">
                                            <div class="icon"><i class="icon-log-out"></i></div>
                                            <div class="text">Keluar</div>
                                        </a>
                                    </form>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
                <div class="section-content-right">

                    <div class="header-dashboard">
                        <div class="wrap">
                            <div class="header-left">
                                <a href="index-2.html">
                                    <img class="" id="logo_header_mobile" alt="Logo Mobile"
                                        src="{{ $about_us_data && $about_us_data->logo_image ? asset('uploads/about/' . $about_us_data->logo_image) : asset('assets/images/logo.png') }}"
                                        data-light="{{ $about_us_data && $about_us_data->logo_image ? asset('uploads/about/' . $about_us_data->logo_image) : asset('assets/images/logo.png') }}"
                                        data-dark="{{ $about_us_data && $about_us_data->logo_image ? asset('uploads/about/' . $about_us_data->logo_image) : asset('assets/images/logo.png') }}" data-width="154px"
                                        data-height="52px" data-retina="{{ $about_us_data && $about_us_data->logo_image ? asset('uploads/about/' . $about_us_data->logo_image) : asset('assets/images/logo.png') }}">
                                </a>
                                <div class="button-show-hide">
                                    <i class="icon-menu-left"></i>
                                </div>

                                {{-- <form class="form-search flex-grow">
                                    <fieldset class="name">
                                        <input type="text" placeholder="Search here..." class="show-search"
                                            name="name" id="search-input" tabindex="2" value=""
                                            aria-required="true" required="" autocomplete="off">
                                    </fieldset>
                                    <div class="button-submit">
                                        <button class="" type="submit"><i class="icon-search"></i></button>
                                    </div>
                                    <div class="box-content-search">
                                        <ul id="box-content-search"></ul>
                                    </div>
                                </form> --}}

                            </div>
                            <div class="header-grid">

                                <div class="popup-wrap message type-header">
                                    <div class="dropdown">
                                        <button class="btn btn-secondary dropdown-toggle" type="button"
                                            id="dropdownMenuButton2" data-bs-toggle="dropdown" aria-expanded="false">
                                            <span class="header-item">

                                                {{-- Angka notifikasi HANYA TAMPIL jika totalnya lebih dari 0 --}}
                                                @if ($totalContacts + $dashboardDatas[0]->TotalOrdered > 0)
                                                    <span
                                                        class="text-tiny">{{ $totalContacts + $dashboardDatas[0]->TotalOrdered }}</span>
                                                @endif

                                                <i class="icon-bell"></i>
                                            </span>
                                        </button>
                                        <ul class="dropdown-menu dropdown-menu-end has-content"
                                            aria-labelledby="dropdownMenuButton2">
                                            <li>
                                                <h6>Notifikasi</h6>
                                            </li>

                                            {{-- Cek jika ada pesan baru --}}
                                            @if ($totalContacts > 0)
                                                <li>
                                                    <div class="message-item item-3">
                                                        <div class="image">
                                                            <i class="icon-mail"></i>
                                                        </div>
                                                        <div>
                                                            <div class="body-title-2">Pesan belum terbaca:
                                                                <span>{{ $totalContacts }}</span>
                                                            </div>
                                                            <div class="text-tiny">Anda memiliki pesan yang belum
                                                                dibaca.
                                                                <a href="{{ route('admin.contacts') }}"
                                                                    class="tf-color">Lihat</a>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </li>
                                            @endif

                                            {{-- Cek jika ada pesanan tertunda --}}
                                            @if ($dashboardDatas[0]->TotalOrdered > 0)
                                                <li>
                                                    <div class="message-item item-4">
                                                        <div class="image">
                                                            <i class="icon-noti-4"></i>
                                                        </div>
                                                        <div>
                                                            <div class="body-title-2">Pesanan tertunda:
                                                                <span>{{ $dashboardDatas[0]->TotalOrdered }}</span>
                                                            </div>
                                                            <div class="text-tiny">Lihat daftar pesanan yang tertunda.
                                                                <a href="{{ route('admin.orders') }}"
                                                                    class="tf-color">Lihat</a>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </li>
                                            @endif

                                            {{-- Tampilkan pesan jika tidak ada notifikasi sama sekali --}}
                                            @if ($totalContacts + $dashboardDatas[0]->TotalOrdered == 0)
                                                <li>
                                                    <div class="message-item">
                                                        <div class="text-tiny" style="padding: 10px 20px;">
                                                            Tidak ada notifikasi baru.
                                                        </div>
                                                    </div>
                                                </li>
                                            @endif

                                        </ul>
                                    </div>
                                </div>




                                <div class="popup-wrap user type-header">
                                    <div class="dropdown">
                                        <button class="btn btn-secondary dropdown-toggle" type="button"
                                            id="dropdownMenuButton3" data-bs-toggle="dropdown" aria-expanded="false">
                                            <span class="header-user wg-user">
                                                <span class="image">
                                                    <img src="{{ asset('images/avatar/user.png') }}" alt="">
                                                </span>
                                                <span class="flex flex-column">
                                                    <span class=" "
                                                        style="color: black; font-size:12px;">{{ Auth::user()->name }}</span>
                                                    <span class="text-tiny" style="font-size: 8px">Admin</span>
                                                </span>
                                            </span>
                                        </button>

                                    </div>
                                </div>

                            </div>
                        </div>
                    </div>
                    <div class="main-content">
                        @yield('content')

                        <div class="bottom-page">
                            <div class="body-text">©2025 Teknik Informatika Universitas Ngudi Waluyo. All Rights
                                Reserved.</div>
                        </div>
                    </div>

                </div>
            </div>
        </div>
    </div>

    <script src="{{ asset('js/jquery.min.js') }}"></script>
    <script src="{{ asset('js/bootstrap.min.js') }}"></script>
    <script src="{{ asset('js/bootstrap-select.min.js') }}"></script>
    <script src="{{ asset('js/sweetalert.min.js') }}"></script>
    <script src="{{ asset('js/apexcharts/apexcharts.js') }}"></script>
    <script src="{{ asset('js/main.js') }}"></script>
    <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
    <script>
        $(function() {
            $("#search-input").on("keyup", function() {
                var searchQuery = $(this).val();
                if (searchQuery.length > 2) {
                    $.ajax({
                        type: "GET",
                        url: "{{ route('admin.search') }}",
                        data: {
                            query: searchQuery
                        },
                        dataType: 'json',
                        success: function(data) {
                            $("#box-content-search").html('');
                            $.each(data, function(index, item) {
                                var url =
                                    "{{ route('admin.product.edit', ['id' => 'product_id']) }}";
                                var link = url.replace('product_id', item.id);

                                $("#box-content-search").append(`
                                <li>
                                    <ul>
                                        <li class="product-item gap14 mb-10" style="justify-content:flex-start;">
                                            <a href="${link}" style="display: flex; align-items: center; gap: 15px;">
                                                <div class="image no-bg">
                                                    <img src="{{ asset('uploads/products/thumbnails') }}/${item.image}" alt="${item.name }">
                                                </div>
                                                <div class="flex items-center justify-between gap20 flex-grow">
                                                    <div class="name">
                                                        ${item.name }
                                                    </div>
                                                </div>
                                            </a>
                                        </li>
                                        <li class="mb-10">
                                            <div class="divider"></div>
                                        </li>
                                    </ul>
                                </li>
                                `)
                            })
                        }
                    })
                }
            })
        })
    </script>
    @stack('scripts')
</body>

</html>