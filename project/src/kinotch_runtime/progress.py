"""Progress events and host callbacks."""

from dataclasses import dataclass
from typing import Callable


_EVENT_TYPES = {
    "started",
    "progress",
    "message",
    "artifact_created",
    "completed",
    "failed",
    "cancelled",
}


@dataclass(frozen=True)
class ProgressEvent:
    type: str
    current: float | None = None
    total: float | None = None
    message: str | None = None

    def __post_init__(self) -> None:
        if self.type not in _EVENT_TYPES:
            raise ValueError(f"unsupported progress event type: {self.type}")

    def to_dict(self) -> dict[str, object]:
        payload: dict[str, object] = {"type": self.type}
        if self.current is not None:
            payload["current"] = self.current
        if self.total is not None:
            payload["total"] = self.total
        if self.message is not None:
            payload["message"] = self.message
        return payload


class ProgressReporter:
    def __init__(self, callback: Callable[[ProgressEvent], None] | None = None) -> None:
        self._callback = callback

    def emit(self, event: ProgressEvent) -> None:
        if self._callback is not None:
            self._callback(event)
