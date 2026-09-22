"""Minimal Action execution kernel."""

from dataclasses import dataclass, field
import logging
import re
from typing import Any, Callable

from .config import RuntimeConfig
from .errors import ActionError, ActionErrorException
from .logging import get_logger
from .progress import ProgressReporter
from .result import ActionResult


@dataclass(frozen=True)
class ActionRequest:
    action_id: str
    input: Any = None
    request_id: str | None = None


class CancellationToken:
    def __init__(self) -> None:
        self._cancelled = False

    @property
    def is_cancelled(self) -> bool:
        return self._cancelled

    def cancel(self) -> None:
        self._cancelled = True

    def throw_if_cancelled(self) -> None:
        if self._cancelled:
            raise ActionErrorException(
                ActionError(code="CANCELLED", message="Action was cancelled")
            )


@dataclass
class ActionContext:
    config: RuntimeConfig = field(default_factory=lambda: RuntimeConfig({}))
    progress: ProgressReporter = field(default_factory=ProgressReporter)
    cancellation: CancellationToken = field(default_factory=CancellationToken)
    logger: logging.Logger = field(default_factory=get_logger)

    @classmethod
    def from_mapping(cls, values: dict[str, Any]) -> "ActionContext":
        return cls(config=RuntimeConfig(values))


ActionHandler = Callable[[ActionRequest, ActionContext], ActionResult]
_ACTION_ID = re.compile(r"^[a-z0-9_.-]+$")


class ActionRegistry:
    def __init__(self) -> None:
        self._handlers: dict[str, ActionHandler] = {}

    def register(self, action_id: str, handler: ActionHandler) -> None:
        if not isinstance(action_id, str) or not _ACTION_ID.fullmatch(action_id):
            raise ValueError("action_id must match ^[a-z0-9_.-]+$")
        if action_id in self._handlers:
            raise ValueError(f"Action is already registered: {action_id}")
        self._handlers[action_id] = handler

    def execute(
        self, request: ActionRequest, context: ActionContext | None = None
    ) -> ActionResult:
        context = context or ActionContext()
        handler = self._handlers.get(request.action_id)
        if handler is None:
            return ActionResult.failure(
                ActionError(
                    code="NOT_FOUND",
                    message="Action is not registered",
                    details={"action_id": request.action_id},
                )
            )

        try:
            context.cancellation.throw_if_cancelled()
            result = handler(request, context)
            if not isinstance(result, ActionResult):
                raise ActionErrorException(
                    ActionError(
                        code="INTERNAL_ERROR",
                        message="Action returned an invalid result",
                        details={"action_id": request.action_id},
                    )
                )
            return result
        except ActionErrorException as exception:
            if exception.error.code == "CANCELLED":
                return ActionResult.cancelled(exception.error)
            return ActionResult.failure(exception.error)
        except Exception:
            context.logger.error("Action execution failed: %s", request.action_id)
            return ActionResult.failure(
                ActionError(
                    code="INTERNAL_ERROR",
                    message="Action execution failed",
                    details={"action_id": request.action_id},
                )
            )
