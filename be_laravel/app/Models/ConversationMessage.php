<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ConversationMessage extends Model
{
    protected $table = 'chat_messages';
    protected $guarded = [];

    public function conversation()
    {
        return $this->belongsTo(Conversation::class, 'conversation_id');
    }

    public function author()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
