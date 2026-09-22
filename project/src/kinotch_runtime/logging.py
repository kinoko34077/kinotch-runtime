"""Standard-library logging boundary."""

import logging


def get_logger(name: str = "kinotch-runtime") -> logging.Logger:
    return logging.getLogger(name)
