"""Resource and Artifact value objects."""

from dataclasses import dataclass
from typing import Any


_RESOURCE_KINDS = {
    "file",
    "directory",
    "url",
    "text",
    "binary",
    "object",
}
_RESOURCE_ACCESS = {"read", "write", "read-write"}
_ARTIFACT_KINDS = {
    "file",
    "directory",
    "structured-data",
    "external-reference",
}


@dataclass(frozen=True)
class Resource:
    kind: str
    value: Any = None
    mime: str | None = None
    name: str | None = None
    access: str | None = None

    def __post_init__(self) -> None:
        if self.kind not in _RESOURCE_KINDS:
            raise ValueError(f"unsupported resource kind: {self.kind}")
        if self.access is not None and self.access not in _RESOURCE_ACCESS:
            raise ValueError(f"unsupported resource access: {self.access}")

    def to_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {"kind": self.kind}
        for name in ("value", "mime", "name", "access"):
            value = getattr(self, name)
            if value is not None:
                payload[name] = value
        return payload


@dataclass(frozen=True)
class Artifact:
    kind: str
    path: str | None = None
    url: str | None = None
    mime: str | None = None
    label: str | None = None

    def __post_init__(self) -> None:
        if self.kind not in _ARTIFACT_KINDS:
            raise ValueError(f"unsupported artifact kind: {self.kind}")

    def to_dict(self) -> dict[str, str]:
        payload: dict[str, str] = {"kind": self.kind}
        for name in ("path", "url", "mime", "label"):
            value = getattr(self, name)
            if value is not None:
                payload[name] = value
        return payload
