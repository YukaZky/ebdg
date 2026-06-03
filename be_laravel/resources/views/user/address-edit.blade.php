@extends('layouts.app')
@section('content')
    <main >
        <section class="my-account container">
            <h2 class="page-title">Alamat</h2>
            <div class="row">
                <div class="col-lg-3">
                    @include('user.account-nav')
                </div>
                <div class="col-lg-9">
                    <div class="page-content my-account__address">
                        <div class="row">
                            <div class="col-12 text-right mb-3">
                                <a href="{{ route('user.address.index') }}" class="btn btn-sm btn-danger">Kembali</a>
                            </div>
                        </div>

                        <div class="row">
                            <div class="col-12">
                                <div class="card mb-5">
                                    <div class="card-header">
                                        <h5>Ubah Alamat</h5>
                                    </div>
                                    <div class="card-body">
                                        <form action="{{ route('user.address.update', $address->id) }}" method="POST">
                                            @csrf
                                            @method('PUT')
                                            <div class="row">
                                                <div class="col-md-6">
                                                    <div class="form-floating my-3">
                                                        <input type="text" class="form-control" name="name"
                                                            value="{{ old('name', $address->name) }}">
                                                        <label for="name">Nama Lengkap *</label>
                                                        @error('name')
                                                            <span class="text-red">{{ $message }}</span>
                                                        @enderror
                                                    </div>
                                                </div>
                                                <div class="col-md-6">
                                                    <div class="form-floating my-3">
                                                        <input type="text" class="form-control" name="phone"
                                                            value="{{ old('phone', $address->phone) }}">
                                                        <label for="phone">Nomor Handphone *</label>
                                                        @error('phone')
                                                            <span class="text-red">{{ $message }}</span>
                                                        @enderror
                                                    </div>
                                                </div>
                                                <div class="row">
  <div class="col-md-4 mb-3">
    <label for="province_select">Provinsi <span class="text-danger">*</span></label>
    <select id="province_select" class="form-control" required></select>
    <input type="hidden" name="province_id" id="province_id">
    <input type="hidden" name="state" id="province_name">   {{-- nama provinsi --}}
    @error('province_id')<div class="text-danger mt-1">{{ $message }}</div>@enderror
  </div>

  <div class="col-md-4 mb-3">
    <label for="city_select">Kota/Kabupaten <span class="text-danger">*</span></label>
    <select id="city_select" class="form-control" required disabled></select>
    <input type="hidden" name="city_id" id="city_id">
    <input type="hidden" name="city"  id="city_name">       {{-- nama kota --}}
    @error('city_id')<div class="text-danger mt-1">{{ $message }}</div>@enderror
  </div>

  <div class="col-md-4 mb-3">
    <label for="district_select">Kecamatan <span class="text-danger">*</span></label>
    <select id="district_select" class="form-control" required disabled></select>
    <input type="hidden" name="district_id" id="district_id">
    <input type="hidden" name="district_name" id="district_name">
    @error('district_id')<div class="text-danger mt-1">{{ $message }}</div>@enderror
  </div>
</div>

<div class="row">
  <div class="col-md-6 mb-3">
    <label for="postal_code">Kode Pos</label>
    <input type="text" class="form-control" id="zip" name="zip" value="{{ old('zip', $address->zip ?? $address->postal_code ?? '') }}">
  </div>                                                <div class="col-md-6">
                                                    <div class="form-floating my-3">
                                                        <input type="text" class="form-control" name="address"
                                                            value="{{ old('street', $address->street) }}">
                                                        <label for="address">Nomor Rumah, Desa *</label>
                                                        @error('address')
                                                            <span class="text-red">{{ $message }}</span>
                                                        @enderror
                                                    </div>
                                                </div>
                                                <div class="col-md-6">
                                                    <div class="form-floating my-3">
                                                        <input type="text" class="form-control" name="locality"
                                                            value="{{ $address->locality }}">
                                                        <label for="locality">Nama Jalan *</label>
                                                        @error('locality')
                                                            <span class="text-red">{{ $message }}</span>
                                                        @enderror
                                                    </div>
                                                </div>
                                                <div class="col-md-12">
                                                    <div class="form-floating my-3">
                                                        <input type="text" class="form-control" name="landmark"
                                                            value="{{ $address->landmark }}">
                                                        <label for="landmark">Petunjuk</label>
                                                        @error('landmark')
                                                            <span class="text-red">{{ $message }}</span>
                                                        @enderror
                                                    </div>
                                                </div>
                                                <div class="col-md-12">
                                                    <div class="form-floating my-3">
                                                        <select class="form-select py-0 px-4" name="type">
                                                            <option value="">Pilih Tipe Alamat</option>
                                                            <option value="Rumah"
                                                                {{ $address->type == 'Rumah' ? 'selected' : '' }}>Rumah
                                                            </option>
                                                            <option value="Kantor"
                                                                {{ $address->type == 'Kantor' ? 'selected' : '' }}>Kantor
                                                            </option>
                                                            <option value="Lainnya"
                                                                {{ $address->type == 'Lainnya' ? 'selected' : '' }}>Lainnya
                                                            </option>
                                                        </select>
                                                        <label for="type">Tipe Alamat</label>
                                                        @error('type')
                                                            <span class="text-red">{{ $message }}</span>
                                                        @enderror
                                                    </div>
                                                </div>
                                                <div class="col-md-6">
                                                    <div class="form-check">
                                                        <input type="checkbox" class="form-check-input" id="isdefault"
                                                            name="isdefault" value="1"
                                                            {{ $address->isdefault ? 'checked' : '' }}>
                                                        <label class="form-check-label" for="isdefault">
                                                            Jadikan Alamat Utama
                                                        </label>
                                                        @error('isdefault')
                                                            <span class="text-red">{{ $message }}</span>
                                                        @enderror
                                                    </div>
                                                </div>
                                                <div class="col-md-12 text-right">
                                                    <button type="submit" class="btn btn-success">Perbarui</button>
                                                </div>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <hr>
                    </div>
                </div>
            </div>
        </section>
    </main>
    <script>
document.addEventListener('DOMContentLoaded', function () {
  const $provinceSel = document.getElementById('province_select');
  const $citySel     = document.getElementById('city_select');
  const $distSel     = document.getElementById('district_select');

  const $provinceId   = document.getElementById('province_id');
  const $provinceName = document.getElementById('province_name');
  const $cityId       = document.getElementById('city_id');
  const $cityName     = document.getElementById('city_name');
  const $districtId   = document.getElementById('district_id');
  const $districtName = document.getElementById('district_name');

  const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  // helper buat ambil field dengan nama bervariasi
  function pick(val, ...keys){
    for (const k of keys){
      if (val && val[k] != null && val[k] !== '') return val[k];
    }
    return '';
  }

  function option(tagValue, tagText) {
    const opt = document.createElement('option');
    opt.value = tagValue;
    opt.textContent = tagText;
    return opt;
  }

  function resetSelect(sel, placeholder) {
    sel.innerHTML = '';
    sel.appendChild(option('', placeholder));
    sel.value = '';
  }

  function disable(sel, yes=true){ sel.disabled = yes; }

  async function fetchJSON(url) {
    const res = await fetch(url, { 
      headers: { 
        'X-CSRF-TOKEN': token, 
        'Accept': 'application/json' 
      }
    });
    if (!res.ok) throw new Error('Network error');
    return res.json();
  }

  async function loadProvinces(selectedId=null) {
    resetSelect($provinceSel, 'Pilih Provinsi');
    disable($provinceSel, true);
    const list = await fetchJSON(ROUTES.provinces);

    console.log("Provinces:", list); // debug
    list.forEach(p => {
      const id   = pick(p, 'province_id', 'id', 'provinceId');
      const name = pick(p, 'province_name', 'name', 'province');
      $provinceSel.appendChild(option(id, name));
    });

    disable($provinceSel, false);
    if (selectedId) $provinceSel.value = String(selectedId);
    setProvinceHidden();
  }

  async function loadCities(provinceId, selectedId=null) {
    resetSelect($citySel, 'Pilih Kota/Kabupaten');
    resetSelect($distSel, 'Pilih Kecamatan');
    disable($citySel, true); disable($distSel, true);
    if (!provinceId) return;

    const url = ROUTES.cities.replace('PROVINCE_ID', provinceId);
    const list = await fetchJSON(url);

    console.log("Cities:", list); // debug
    list.forEach(c => {
      const id   = pick(c, 'city_id', 'id', 'cityId');
      const name = pick(c, 'city_name', 'name', 'city');
      $citySel.appendChild(option(id, name));
    });

    disable($citySel, false);
    if (selectedId) $citySel.value = String(selectedId);
    setCityHidden();
  }

  async function loadDistricts(cityId, selectedId=null) {
    resetSelect($distSel, 'Pilih Kecamatan');
    disable($distSel, true);
    if (!cityId) return;

    const url = ROUTES.districts.replace('CITY_ID', cityId);
    const list = await fetchJSON(url);

    console.log("Districts:", list); // debug
    list.forEach(d => {
      const id   = pick(d, 'subdistrict_id', 'id', 'district_id', 'subdistrictId');
      const name = pick(d, 'subdistrict_name', 'name', 'district_name', 'subdistrict');
      $distSel.appendChild(option(id, name));
    });

    disable($distSel, false);
    if (selectedId) $distSel.value = String(selectedId);
    setDistrictHidden();
  }

  function setProvinceHidden() {
    const opt = $provinceSel.options[$provinceSel.selectedIndex];
    $provinceId.value   = opt?.value || '';
    $provinceName.value = opt?.text || '';
  }

  function setCityHidden() {
    const opt = $citySel.options[$citySel.selectedIndex];
    $cityId.value   = opt?.value || '';
    $cityName.value = opt?.text || '';
  }

  function setDistrictHidden() {
    const opt = $distSel.options[$distSel.selectedIndex];
    $districtId.value   = opt?.value || '';
    $districtName.value = opt?.text || '';
  }

  // Events
  $provinceSel.addEventListener('change', async (e) => {
    setProvinceHidden();
    await loadCities(e.target.value, null);
  });

  $citySel.addEventListener('change', async (e) => {
    setCityHidden();
    await loadDistricts(e.target.value, null);
  });

  $distSel.addEventListener('change', setDistrictHidden);

  // Prefill saat edit / old value
  const prefProvinceId = "{{ old('province_id', $address->province_id ?? '') }}";
  const prefCityId     = "{{ old('city_id', $address->city_id ?? '') }}";
  const prefDistrictId = "{{ old('district_id', $address->district_id ?? '') }}";

  (async function init(){
    try {
      await loadProvinces(prefProvinceId || null);
      if (prefProvinceId) await loadCities(prefProvinceId, prefCityId || null);
      if (prefCityId)     await loadDistricts(prefCityId, prefDistrictId || null);
    } catch(e) {
      console.error(e);
    }
  })();
});
</script>
<script>
  window.ROUTES = {
    provinces: "{{ url('/ro/provinces') }}",
    cities:    "{{ url('/ro/cities') }}/PROVINCE_ID",
    districts: "{{ url('/ro/districts') }}/CITY_ID",
  };
</script>


@endsection
