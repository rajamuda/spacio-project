<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\Auth;

class CheckAccountActivation
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle($request, Closure $next, $guard = null)
    {
        if (!Auth::user()->activation) {
            // return response()->json(['error' => 'Access not permitted. Reason: Account is not activated yet'], 403);
            return abort(403, 'Access is not permitted. Reason: Your account is not activated yet');
        }
        return $next($request);
    }
}
