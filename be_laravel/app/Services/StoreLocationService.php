<?php

namespace App\Services;

use App\Models\Address;
use App\Models\StoreProfile;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Str;

class StoreLocationService
{
    public function findForUser(int $userId): ?Address
    {
        return Address::where('user_id', $userId)
            ->where('store_owner_id', $userId)
            ->first();
    }

    public function assign(User $user, Address $address): Address
    {
        if ((int) $address->user_id !== (int) $user->id) {
            throw new AuthorizationException('Alamat toko tidak dimiliki oleh akun ini.');
        }

        Address::where('user_id', $user->id)
            ->where('id', '!=', $address->id)
            ->update([
                'is_store_address' => false,
                'store_owner_id' => null,
            ]);

        $address->is_store_address = true;
        $address->store_owner_id = $user->id;
        $address->save();

        $this->syncStoreProfile($user, $address);

        return $address->refresh();
    }

    public function clear(User $user, Address $address): void
    {
        if ((int) $address->user_id !== (int) $user->id) {
            throw new AuthorizationException('Alamat toko tidak dimiliki oleh akun ini.');
        }

        $wasStoreLocation = (int) $address->store_owner_id === (int) $user->id;

        $address->is_store_address = false;
        $address->store_owner_id = null;
        $address->save();

        if ($wasStoreLocation) {
            $this->clearStoreProfileLocation($user);
        }
    }

    public function clearStoreProfileLocation(User $user): void
    {
        StoreProfile::where('user_id', $user->id)->update([
            'address' => null,
            'maps_url' => null,
            'province_name' => null,
            'city_name' => null,
        ]);
    }

    private function syncStoreProfile(User $user, Address $address): void
    {
        $store = StoreProfile::firstOrCreate(
            ['user_id' => $user->id],
            [
                'name' => $user->name.' Store',
                'slug' => Str::slug($user->name.'-'.$user->id),
                'status' => 'active',
            ]
        );

        $area = collect([$address->locality, $address->city_name, $address->province_name])
            ->filter(fn ($item) => ! empty($item) && $item !== '-')
            ->implode(', ');

        $store->address = trim($address->address.($area ? ', '.$area : ''));
        $store->phone = $address->phone ?: $store->phone;
        $store->province_name = $address->province_name ?: null;
        $store->city_name = $address->city_name ?: null;
        $store->maps_url = $address->latitude && $address->longitude
            ? 'https://www.google.com/maps/search/?api=1&query='.$address->latitude.','.$address->longitude
            : null;
        $store->save();
    }
}
