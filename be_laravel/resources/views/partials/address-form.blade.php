@php
    $address = $address ?? null;
@endphp

<form action="{{ $address ? route('user.address.update', $address->id) : route('user.address.store') }}" method="POST">
    @csrf
    @if($address)
        @method('PUT')
    @endif

    <div class="col-md-6">
        <div class="form-floating my-3">
            <input type="text" class="form-control" name="name" required
                value="{{ old('name', $address->name ?? '') }}">
            <label for="name">Full Name *</label>
        </div>
    </div>

    <div class="col-md-6">
        <div class="form-floating my-3">
            <input type="text" class="form-control" name="phone" required
                value="{{ old('phone', $address->phone ?? '') }}">
            <label for="phone">Phone Number *</label>
        </div>
    </div>

    <div class="col-md-4">
        <div class="form-floating my-3">
            <input type="text" class="form-control" name="zip" required
                value="{{ old('zip', $address->zip ?? '') }}">
            <label for="zip">Pincode *</label>
        </div>
    </div>

    <div class="col-md-4">
        <div class="form-floating my-3">
            <input type="text" class="form-control" name="state" required
                value="{{ old('state', $address->state ?? '') }}">
            <label for="state">State *</label>
        </div>
    </div>

    <div class="col-md-4">
        <div class="form-floating my-3">
            <input type="text" class="form-control" name="city" required
                value="{{ old('city', $address->city ?? '') }}">
            <label for="city">City *</label>
        </div>
    </div>

    <div class="col-md-6">
        <div class="form-floating my-3">
            <input type="text" class="form-control" name="address" required
                value="{{ old('address', $address->address ?? '') }}">
            <label for="address">House no, Building Name *</label>
        </div>
    </div>

    <div class="col-md-6">
        <div class="form-floating my-3">
            <input type="text" class="form-control" name="locality" required
                value="{{ old('locality', $address->locality ?? '') }}">
            <label for="locality">Road Name, Area, Colony *</label>
        </div>
    </div>

    <div class="col-md-12">
        <div class="form-floating my-3">
            <input type="text" class="form-control" name="landmark" required
                value="{{ old('landmark', $address->landmark ?? '') }}">
            <label for="landmark">Landmark *</label>
        </div>
    </div>

    <div class="col-md-12 text-end">
        <button type="submit" class="btn btn-success">
            {{ $address ? 'Update Alamat' : 'Simpan Alamat' }}
        </button>
    </div>
</form>
