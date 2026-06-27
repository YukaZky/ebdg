<?php

/**
 * Helper khusus IDE untuk Intelephense.
 *
 * File ini tidak dipakai runtime Laravel. Tujuannya hanya membantu VS Code/Intelephense
 * mengenali bahwa helper auth() bisa memanggil method user() dan id().
 */
if (! function_exists('auth')) {
    /**
     * @param string|null $guard
     * @return \Illuminate\Contracts\Auth\StatefulGuard
     */
    function auth($guard = null)
    {
        /** @var \Illuminate\Contracts\Auth\StatefulGuard $guardInstance */
        $guardInstance = app('auth')->guard($guard);
        return $guardInstance;
    }
}
