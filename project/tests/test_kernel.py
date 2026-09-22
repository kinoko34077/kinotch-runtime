import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from kinotch_runtime.errors import ActionError, ActionErrorException
from kinotch_runtime.kernel import (
    ActionContext,
    ActionRegistry,
    ActionRequest,
    CancellationToken,
)
from kinotch_runtime.result import ActionResult


class KernelTests(unittest.TestCase):
    def test_registered_action_executes_with_request_and_context(self):
        registry = ActionRegistry()
        seen = []

        def handler(request, context):
            seen.append((request.action_id, context.config.get("mode")))
            return ActionResult.success({"ok": True})

        registry.register("sample.echo", handler)
        result = registry.execute(
            ActionRequest("sample.echo", {"value": 1}),
            ActionContext.from_mapping({"mode": "test"}),
        )

        self.assertEqual("success", result.status)
        self.assertEqual([("sample.echo", "test")], seen)

    def test_unknown_action_returns_not_found(self):
        result = ActionRegistry().execute(ActionRequest("missing"))

        self.assertEqual("failed", result.status)
        self.assertEqual("NOT_FOUND", result.error.code)
        self.assertEqual("missing", result.error.details["action_id"])

    def test_expected_action_error_becomes_structured_failure(self):
        registry = ActionRegistry()

        def handler(request, context):
            raise ActionErrorException(
                ActionError(
                    code="INVALID_INPUT", message="bad input", details={"field": "value"}
                )
            )

        registry.register("sample.fail", handler)
        result = registry.execute(ActionRequest("sample.fail"))

        self.assertEqual("failed", result.status)
        self.assertEqual("INVALID_INPUT", result.error.code)
        self.assertEqual({"field": "value"}, result.error.details)

    def test_unexpected_exception_is_redacted_in_result(self):
        registry = ActionRegistry()

        def handler(request, context):
            raise RuntimeError("secret traceback detail")

        registry.register("sample.crash", handler)
        result = registry.execute(ActionRequest("sample.crash"))

        self.assertEqual("failed", result.status)
        self.assertEqual("INTERNAL_ERROR", result.error.code)
        self.assertNotIn("secret traceback detail", str(result.to_dict()))

    def test_cancelled_token_prevents_action_execution(self):
        registry = ActionRegistry()
        token = CancellationToken()
        token.cancel()
        invoked = []

        def handler(request, context):
            invoked.append(True)
            return ActionResult.success()

        registry.register("sample.cancel", handler)
        result = registry.execute(
            ActionRequest("sample.cancel"), ActionContext(cancellation=token)
        )

        self.assertEqual("cancelled", result.status)
        self.assertEqual("CANCELLED", result.error.code)
        self.assertEqual([], invoked)

    def test_action_can_observe_cooperative_cancellation(self):
        registry = ActionRegistry()
        token = CancellationToken()

        def handler(request, context):
            context.cancellation.cancel()
            context.cancellation.throw_if_cancelled()
            return ActionResult.success()

        registry.register("sample.cooperative-cancel", handler)
        result = registry.execute(
            ActionRequest("sample.cooperative-cancel"),
            ActionContext(cancellation=token),
        )

        self.assertEqual("cancelled", result.status)
        self.assertEqual("CANCELLED", result.error.code)


if __name__ == "__main__":
    unittest.main()
