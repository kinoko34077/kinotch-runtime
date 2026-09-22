"""JSON-compatible Action results."""

from dataclasses import dataclass, field
from typing import Any, Mapping

from .errors import ActionError
from .resources import Artifact


_STATUSES = {"success", "partial", "failed", "cancelled"}


@dataclass(frozen=True)
class ActionResult:
    status: str
    data: Any = None
    error: ActionError | None = None
    artifacts: tuple[Artifact, ...] = ()
    warnings: tuple[str, ...] = ()
    metrics: Mapping[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if self.status not in _STATUSES:
            raise ValueError(f"unsupported result status: {self.status}")
        if self.status in {"failed", "cancelled"} and self.error is None:
            raise ValueError(f"{self.status} results require an error")

    @classmethod
    def success(
        cls,
        data: Any = None,
        *,
        artifacts: tuple[Artifact, ...] = (),
        warnings: tuple[str, ...] = (),
        metrics: Mapping[str, Any] | None = None,
    ) -> "ActionResult":
        return cls(
            status="success",
            data=data,
            artifacts=artifacts,
            warnings=warnings,
            metrics={} if metrics is None else metrics,
        )

    @classmethod
    def failure(cls, error: ActionError) -> "ActionResult":
        return cls(status="failed", error=error)

    @classmethod
    def cancelled(cls, error: ActionError | None = None) -> "ActionResult":
        return cls(
            status="cancelled",
            error=error
            or ActionError(code="CANCELLED", message="Action was cancelled"),
        )

    def to_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {"status": self.status}
        if self.data is not None:
            payload["data"] = self.data
        if self.error is not None:
            payload["error"] = self.error.to_dict()
        if self.artifacts:
            payload["artifacts"] = [artifact.to_dict() for artifact in self.artifacts]
        if self.warnings:
            payload["warnings"] = list(self.warnings)
        if self.metrics:
            payload["metrics"] = dict(self.metrics)
        return payload
