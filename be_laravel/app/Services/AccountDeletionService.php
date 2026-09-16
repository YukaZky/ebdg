<?php

namespace App\Services;

use App\Models\ManualPaymentConfirmation;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

class AccountDeletionService
{
    public function delete(User $user): void
    {
        $publicFiles = $this->publicFilesFor($user);
        $privateFiles = Schema::hasTable('manual_payment_confirmations')
            ? ManualPaymentConfirmation::query()
                ->where('user_id', $user->id)
                ->pluck('proof_path')
                ->filter()
                ->all()
            : [];

        DB::transaction(function () use ($user): void {
            // Seller references are nullable but were created without a foreign key.
            if (Schema::hasColumn('orders', 'seller_id')) {
                Order::query()->where('seller_id', $user->id)->update(['seller_id' => null]);
            }
            // Shared catalogue/settings records must survive deletion of their creator.
            foreach (['categories', 'brands', 'abouts', 'whatsapp_settings'] as $table) {
                if (Schema::hasTable($table) && Schema::hasColumn($table, 'user_id')) {
                    DB::table($table)->where('user_id', $user->id)->update(['user_id' => null]);
                }
            }
            if (Schema::hasTable('personal_access_tokens')) {
                $user->tokens()->delete();
            }
            $user->delete();
        });

        foreach ($publicFiles as $path) {
            File::delete($path);
        }

        foreach ($privateFiles as $path) {
            Storage::disk('local')->delete($path);
        }
    }

    private function publicFilesFor(User $user): array
    {
        $files = [];

        $this->appendPublicFile($files, 'uploads/profiles', $user->avatar);

        $store = Schema::hasTable('store_profiles') ? $user->storeProfile()->first() : null;
        if ($store) {
            $this->appendPublicFile($files, 'uploads/stores', $store->logo);
            $this->appendPublicFile($files, 'uploads/stores', $store->banner);
        }

        $products = Product::query()
            ->with('variations')
            ->where('user_id', $user->id)
            ->get();

        foreach ($products as $product) {
            $imageNames = [$product->image];
            $additionalImages = is_array($product->images)
                ? $product->images
                : preg_split('/[,|]/', (string) $product->images);

            foreach (array_merge($imageNames, $additionalImages ?: []) as $image) {
                $this->appendPublicFile($files, 'uploads/products', $image);
                $this->appendPublicFile($files, 'uploads/products/thumbnails', $image);
            }

            foreach ($product->variations as $variation) {
                $this->appendPublicFile($files, 'uploads/products', $variation->image);
            }
        }

        return array_values(array_unique($files));
    }

    private function appendPublicFile(array &$files, string $directory, mixed $filename): void
    {
        $safeName = basename(trim((string) $filename));
        if ($safeName !== '' && $safeName !== '.') {
            $files[] = public_path($directory.'/'.$safeName);
        }
    }
}
