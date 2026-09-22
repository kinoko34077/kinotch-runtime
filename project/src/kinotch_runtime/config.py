"""Explicit Runtime configuration access."""

from dataclasses import dataclass
from typing import Any, Mapping


@dataclass(frozen=True)
class RuntimeConfig:
    _values: Mapping[str, Any]

    def __post_init__(self) -> None:
        object.__setattr__(self, "_values", dict(self._values))

    def get(self, name: str, default: Any = None) -> Any:
        return self._values.get(name, default)

    def require(self, name: str) -> Any:
        if name not in self._values:
            raise KeyError(f"required Runtime config is missing: {name}")
        return self._values[name]

    def to_dict(self) -> dict[str, Any]:
        return dict(self._values)
