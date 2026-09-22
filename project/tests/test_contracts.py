import json
import logging
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from kinotch_runtime.config import RuntimeConfig
from kinotch_runtime.errors import ActionError
from kinotch_runtime.kernel import ActionRegistry
from kinotch_runtime.logging import get_logger
from kinotch_runtime.progress import ProgressEvent, ProgressReporter
from kinotch_runtime.resources import Artifact, Resource
from kinotch_runtime.result import ActionResult


class ContractValueTests(unittest.TestCase):
    def test_action_error_rejects_invalid_code_and_serializes(self):
        with self.assertRaises(ValueError):
            ActionError(code="not-valid", message="bad")

        error = ActionError(
            code="INVALID_INPUT",
            message="name is required",
            details={"field": "name"},
            retryable=False,
        )
        self.assertEqual(
            {
                "code": "INVALID_INPUT",
                "message": "name is required",
                "details": {"field": "name"},
                "retryable": False,
            },
            error.to_dict(),
        )

    def test_result_serializes_success_and_failure(self):
        success = ActionResult.success(data={"count": 2}, warnings=("sample",))
        self.assertEqual("success", success.status)
        self.assertEqual({"count": 2}, success.to_dict()["data"])
        json.dumps(success.to_dict())

        failure = ActionResult.failure(
            ActionError(code="NOT_FOUND", message="action missing")
        )
        self.assertEqual("failed", failure.status)
        self.assertEqual("NOT_FOUND", failure.to_dict()["error"]["code"])

    def test_failed_and_cancelled_results_require_errors(self):
        with self.assertRaises(ValueError):
            ActionResult(status="failed")
        with self.assertRaises(ValueError):
            ActionResult(status="cancelled")

    def test_artifact_integrates_with_result_and_json_serialization(self):
        artifact = Artifact(kind="file", path="out/report.json")
        result = ActionResult.success(artifacts=(artifact,))

        self.assertEqual(
            {"kind": "file", "path": "out/report.json"},
            result.to_dict()["artifacts"][0],
        )
        json.dumps(result.to_dict())

    def test_progress_reporter_delivers_json_compatible_event(self):
        received = []
        reporter = ProgressReporter(received.append)
        event = ProgressEvent(
            type="progress", current=2, total=4, message="reading"
        )

        reporter.emit(event)

        self.assertEqual([event], received)
        self.assertEqual(
            {
                "type": "progress",
                "current": 2,
                "total": 4,
                "message": "reading",
            },
            event.to_dict(),
        )

    def test_resource_and_artifact_serialize(self):
        resource = Resource(
            kind="text", value="hello", mime="text/plain", name="greeting"
        )
        artifact = Artifact(
            kind="file", path="out/report.json", mime="application/json"
        )

        self.assertEqual("text", resource.to_dict()["kind"])
        self.assertEqual("out/report.json", artifact.to_dict()["path"])
        json.dumps({"resource": resource.to_dict(), "artifact": artifact.to_dict()})

    def test_resource_rejects_unknown_kind_and_access(self):
        with self.assertRaises(ValueError):
            Resource(kind="banana")
        with self.assertRaises(ValueError):
            Resource(kind="file", access="banana")

    def test_artifact_rejects_unknown_kind(self):
        with self.assertRaises(ValueError):
            Artifact(kind="banana")

    def test_action_registry_validates_ids_and_duplicates(self):
        registry = ActionRegistry()
        registry.register("sample.echo", lambda request, context: ActionResult.success())

        with self.assertRaises(ValueError):
            registry.register("!!!", lambda request, context: ActionResult.success())
        with self.assertRaises(ValueError):
            registry.register("Hello World", lambda request, context: ActionResult.success())
        with self.assertRaises(ValueError):
            registry.register("sample.echo", lambda request, context: ActionResult.success())

    def test_runtime_result_schema_declares_error(self):
        schema_path = (
            Path(__file__).resolve().parents[1]
            / "contracts"
            / "execution"
            / "result.schema.json"
        )
        schema = json.loads(schema_path.read_text(encoding="utf-8"))

        self.assertEqual(
            {"$ref": "error.schema.json"},
            schema["properties"]["error"],
        )

    def test_config_requires_explicit_reads(self):
        config = RuntimeConfig({"workers": 2})

        self.assertEqual(2, config.get("workers"))
        self.assertIsNone(config.get("missing"))
        with self.assertRaises(KeyError):
            config.require("missing")
        self.assertEqual({"workers": 2}, config.to_dict())

    def test_logging_adapter_returns_standard_logger(self):
        logger = get_logger("kinotch-runtime.test")

        self.assertIsInstance(logger, logging.Logger)
        self.assertEqual("kinotch-runtime.test", logger.name)


if __name__ == "__main__":
    unittest.main()
