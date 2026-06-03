<?php

use Illuminate\Support\Facades\Schema;
if (!function_exists('schema_has_column')) {
    function schema_has_column(string $table, string $column): bool {
        try { return Schema::hasColumn($table, $column); } catch (\Throwable $e) { return false; }
    }
}
