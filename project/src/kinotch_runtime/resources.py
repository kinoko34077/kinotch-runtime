"""Resource and Artifact value objects."""

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class Resource:
    kind: str
    value: Any = None
    mime: str | None = None
    name: str | None = None
    access: str | None = None

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

    def to_dict(self) -> dict[str, str]:
        payload: dict[str, str] = {"kind": self.kind}
        for name in ("path", "url", "mime", "label"):
            value = getattr(self, name)
            if value is not None:
                payload[name] = value
        return payload
