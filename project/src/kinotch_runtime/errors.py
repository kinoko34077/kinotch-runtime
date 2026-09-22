"""Structured Runtime errors."""

from dataclasses import dataclass, field
import re
from typing import Any, Mapping


_ERROR_CODE = re.compile(r"^[A-Z][A-Z0-9_]*$")


@dataclass(frozen=True)
class ActionError:
    code: str
    message: str
    details: Mapping[str, Any] = field(default_factory=dict)
    retryable: bool = False

    def __post_init__(self) -> None:
        if not _ERROR_CODE.fullmatch(self.code):
            raise ValueError("error code must match ^[A-Z][A-Z0-9_]*$")
        if not self.message:
            raise ValueError("error message must not be empty")

    def to_dict(self) -> dict[str, Any]:
        return {
            "code": self.code,
            "message": self.message,
            "details": dict(self.details),
            "retryable": self.retryable,
        }


class ActionErrorException(Exception):
    """Expected Action failure that the kernel converts to a result."""

    def __init__(self, error: ActionError) -> None:
        self.error = error
        super().__init__(error.message)
