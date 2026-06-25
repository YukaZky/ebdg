<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\ConversationMessage;
use App\Models\Product;
use App\Models\StoreProfile;
use App\Models\User;
use Illuminate\Http\Request;

class ApiMarketplaceChatController extends Controller
{
    private function conversationQueryForUser(Request $request, ?string $role = null)
    {
        $userId = (int) $request->user()->id;
        $query = Conversation::with([
            'customer:id,name,email,phone',
            'merchant:id,name,email,phone',
            'store:id,user_id,name,slug,logo,phone,status',
            'product:id,user_id,name,slug,image',
        ]);

        if ($role === 'seller') {
            return $query->where('seller_id', $userId);
        }

        if ($role === 'buyer') {
            return $query->where('buyer_id', $userId);
        }

        return $query->where(function ($query) use ($userId) {
            $query->where('buyer_id', $userId)
                ->orWhere('seller_id', $userId);
        });
    }

    private function userPayload(?User $user, string $type = 'user'): ?array
    {
        if (! $user) {
            return null;
        }

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'type' => $type,
        ];
    }

    private function storePayload(?StoreProfile $store, ?User $merchant): ?array
    {
        if (! $store && ! $merchant) {
            return null;
        }

        return [
            'id' => $store?->id,
            'user_id' => $store?->user_id ?? $merchant?->id,
            'name' => $store?->name ?: trim(($merchant?->name ?? 'Toko') . ' Store'),
            'slug' => $store?->slug,
            'logo' => $store?->logo,
            'phone' => $store?->phone ?? $merchant?->phone,
            'email' => $merchant?->email,
            'status' => $store?->status ?? 'active',
            'type' => 'store',
        ];
    }

    private function productPayload(?Product $product): ?array
    {
        if (! $product) {
            return null;
        }

        return [
            'id' => $product->id,
            'user_id' => $product->user_id,
            'name' => $product->name,
            'slug' => $product->slug,
            'image' => $product->image,
        ];
    }

    private function conversationPayload(Conversation $conversation, int $userId): array
    {
        $conversation->loadMissing([
            'customer:id,name,email,phone',
            'merchant:id,name,email,phone',
            'store:id,user_id,name,slug,logo,phone,status',
            'product:id,user_id,name,slug,image',
        ]);

        $isSeller = (int) $conversation->seller_id === $userId;
        $buyer = $this->userPayload($conversation->customer, 'buyer');
        $seller = $this->userPayload($conversation->merchant, 'seller');
        $store = $this->storePayload($conversation->store, $conversation->merchant);
        $product = $this->productPayload($conversation->product);
        $counterpart = $isSeller ? $buyer : $store;
        $displayName = $counterpart['name'] ?? ($isSeller ? 'Pembeli' : 'Toko');

        $payload = $conversation->toArray();
        $payload['role'] = $isSeller ? 'seller' : 'buyer';
        $payload['buyer'] = $buyer;
        $payload['seller'] = $seller;
        $payload['store'] = $store;
        $payload['product'] = $product;
        $payload['product_context'] = $product;
        $payload['counterpart'] = $counterpart;
        $payload['display_name'] = $displayName;
        $payload['display_subtitle'] = $isSeller ? 'Pembeli' : 'Toko';
        $payload['last_message_text'] = $conversation->last_message ?: 'Belum ada pesan.';

        return $payload;
    }

    private function existingStoreConversation(int $buyerId, int $sellerId): ?Conversation
    {
        return Conversation::where('buyer_id', $buyerId)
            ->where('seller_id', $sellerId)
            ->orderByRaw('COALESCE(last_message_at, updated_at, created_at) DESC')
            ->orderByDesc('id')
            ->first();
    }

    private function messagePayload(ConversationMessage $message): array
    {
        $message->loadMissing('author:id,name,email,phone');
        $payload = $message->toArray();
        $payload['sender'] = $this->userPayload($message->author, 'user');

        return $payload;
    }

    public function conversations(Request $request)
    {
        $userId = (int) $request->user()->id;
        $role = $request->query('role') ?: $request->query('scope');
        $role = in_array($role, ['seller', 'buyer', 'all'], true) ? $role : 'buyer';
        $queryRole = $role === 'all' ? null : $role;

        $data = $this->conversationQueryForUser($request, $queryRole)
            ->withCount(['chatItems as unread_count' => function ($query) use ($userId) {
                $query->where('sender_id', '!=', $userId)->whereNull('read_at');
            }])
            ->orderByRaw('COALESCE(last_message_at, updated_at, created_at) DESC')
            ->orderByDesc('id')
            ->get()
            ->map(fn ($conversation) => $this->conversationPayload($conversation, $userId))
            ->values();

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function startConversation(Request $request)
    {
        $request->validate([
            'seller_id' => 'nullable|required_without:product_id|exists:users,id',
            'product_id' => 'nullable|exists:products,id',
        ]);

        $buyerId = (int) $request->user()->id;
        $product = $request->filled('product_id')
            ? Product::select('id', 'user_id', 'name', 'slug', 'image')->findOrFail($request->product_id)
            : null;
        $sellerId = $product ? (int) $product->user_id : (int) $request->seller_id;

        if ($sellerId <= 0) {
            return response()->json(['success' => false, 'message' => 'Data toko belum tersedia.'], 422);
        }

        if ($sellerId === $buyerId) {
            return response()->json(['success' => false, 'message' => 'Tidak bisa chat toko sendiri.'], 422);
        }

        $seller = User::select('id', 'name', 'email', 'phone')->find($sellerId);
        if (! $seller) {
            return response()->json(['success' => false, 'message' => 'Akun toko tidak ditemukan.'], 404);
        }

        $conversation = $this->existingStoreConversation($buyerId, $sellerId);

        if (! $conversation) {
            $conversation = Conversation::create([
                'buyer_id' => $buyerId,
                'seller_id' => $sellerId,
                'product_id' => $product?->id,
                'last_message_at' => now(),
            ]);
        } elseif (! $conversation->product_id && $product) {
            $conversation->product_id = $product->id;
            $conversation->save();
        }

        $conversation->load([
            'customer:id,name,email,phone',
            'merchant:id,name,email,phone',
            'store:id,user_id,name,slug,logo,phone,status',
            'product:id,user_id,name,slug,image',
        ]);

        return response()->json([
            'success' => true,
            'data' => $this->conversationPayload($conversation, $buyerId),
        ]);
    }

    public function messages(Request $request, $conversationId)
    {
        $userId = (int) $request->user()->id;
        $conversation = $this->conversationQueryForUser($request)->findOrFail($conversationId);

        ConversationMessage::where('conversation_id', $conversation->id)
            ->where('sender_id', '!=', $userId)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        $messages = ConversationMessage::with('author:id,name,email,phone')
            ->where('conversation_id', $conversation->id)
            ->orderBy('id')
            ->get()
            ->map(fn ($item) => $this->messagePayload($item));

        return response()->json([
            'success' => true,
            'conversation' => $this->conversationPayload($conversation, $userId),
            'data' => $messages,
        ]);
    }

    public function sendMessage(Request $request, $conversationId)
    {
        $request->validate(['message' => 'required|string|max:5000']);

        $text = trim((string) $request->message);
        if ($text === '') {
            return response()->json(['success' => false, 'message' => 'Pesan tidak boleh kosong.'], 422);
        }

        $conversation = $this->conversationQueryForUser($request)->findOrFail($conversationId);

        $message = ConversationMessage::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $request->user()->id,
            'message' => $text,
        ]);

        $conversation->last_message = $text;
        $conversation->last_message_at = now();
        $conversation->save();

        return response()->json([
            'success' => true,
            'conversation' => $this->conversationPayload($conversation->fresh(), (int) $request->user()->id),
            'data' => $this->messagePayload($message),
        ]);
    }
}
