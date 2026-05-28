from typing import Any


def success_response(data: Any = None, message: str = "Success") -> dict[str, Any]:
    """Return a consistent success payload."""
    return {"success": True, "message": message, "data": data}


def error_response(message: str, details: Any = None) -> dict[str, Any]:
    """Return a consistent error payload."""
    return {"success": False, "message": message, "details": details}
