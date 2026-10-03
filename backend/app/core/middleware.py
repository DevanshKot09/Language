import time
from collections import defaultdict
from typing import Dict, List, Tuple
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response, JSONResponse
from app.core.config import settings
from app.core.security import log_security_event


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """
    Injects OWASP-recommended production HTTP security headers into all responses.
    Protects against clickjacking, MIME-sniffing, XSS, and unapproved framing.
    """
    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)

        if settings.ENABLE_SECURITY_HEADERS:
            response.headers["X-Content-Type-Options"] = "nosniff"
            response.headers["X-Frame-Options"] = "DENY"
            response.headers["X-XSS-Protection"] = "1; mode=block"
            response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
            response.headers["Permissions-Policy"] = "camera=(), microphone=(self), geolocation=()"
            response.headers["Content-Security-Policy"] = (
                "default-src 'self'; "
                "frame-ancestors 'none'; "
                "object-src 'none'; "
                "base-uri 'self';"
            )

            # Strict-Transport-Security for production environments
            if settings.ENVIRONMENT.lower() in ("production", "prod"):
                response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"

        return response


class RequestSizeLimitMiddleware(BaseHTTPMiddleware):
    """
    Guards the server against resource exhaustion (DoS) via oversized payload bodies.
    """
    async def dispatch(self, request: Request, call_next) -> Response:
        content_length = request.headers.get("content-length")
        if content_length:
            try:
                length_int = int(content_length)
                if length_int > settings.MAX_REQUEST_BODY_BYTES:
                    log_security_event(
                        "oversized_request_blocked",
                        details=f"bytes={length_int} max={settings.MAX_REQUEST_BODY_BYTES} path={request.url.path}",
                    )
                    return JSONResponse(
                        status_code=413,
                        content={"detail": "Request entity exceeds maximum allowable size (5 MB)."},
                    )
            except ValueError:
                pass

        return await call_next(request)


class InMemoryRateLimiter:
    """
    Thread-safe in-memory sliding window rate limiter.
    Limits request rates for sensitive endpoints (invitations, AI, reports).
    """
    def __init__(self):
        # Maps (client_ip, bucket_name) -> list of timestamp floats
        self._history: Dict[Tuple[str, str], List[float]] = defaultdict(list)

    def is_allowed(self, client_ip: str, bucket: str, limit_per_minute: int) -> Tuple[bool, int]:
        now = time.time()
        window_start = now - 60.0
        key = (client_ip, bucket)

        # Evict timestamps older than 60 seconds
        self._history[key] = [t for t in self._history[key] if t > window_start]

        count = len(self._history[key])
        if count >= limit_per_minute:
            return False, 0

        self._history[key].append(now)
        remaining = max(0, limit_per_minute - (count + 1))
        return True, remaining


rate_limiter = InMemoryRateLimiter()


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Applies endpoint-specific rate limits to protect sensitive collaboration and AI endpoints.
    """
    async def dispatch(self, request: Request, call_next) -> Response:
        if not settings.RATE_LIMIT_ENABLED:
            return await call_next(request)

        client_ip = request.client.host if request.client else "127.0.0.1"
        path = request.url.path

        # Determine rate limit bucket
        bucket = None
        limit = 60

        if "/api/v1/relationships/invitations" in path and request.method == "POST":
            bucket = "invitations"
            limit = settings.RATE_LIMIT_INVITATIONS_PER_MINUTE
        elif "/api/v1/reports" in path and request.method == "POST":
            bucket = "reports"
            limit = settings.RATE_LIMIT_REPORTS_PER_MINUTE
        elif "/api/v1/ai/" in path and request.method == "POST":
            bucket = "ai"
            limit = settings.RATE_LIMIT_AI_PER_MINUTE

        if bucket:
            allowed, remaining = rate_limiter.is_allowed(client_ip, bucket, limit)
            if not allowed:
                log_security_event(
                    "rate_limit_exceeded",
                    details=f"ip={client_ip} bucket={bucket} limit={limit}",
                )
                return JSONResponse(
                    status_code=429,
                    content={"detail": "Too many requests. Please slow down and try again shortly."},
                    headers={"Retry-After": "60"},
                )

        response = await call_next(request)
        return response
