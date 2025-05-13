"""
Logging utility for the Country Currency App.
Provides consistent logging across the application.
"""
import logging
import os
from pathlib import Path

# Define debug mode as an environment variable
# Can be set to "1" to enable debug output
DEBUG_MODE = os.environ.get("DEBUG_MODE", "0") == "1"

# Configure logging
logging.basicConfig(
    level=logging.DEBUG if DEBUG_MODE else logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)

def get_logger(name):
    """Get a logger with the specified name."""
    return logging.getLogger(name)

def debug_print(*args, **kwargs):
    """Print only when in debug mode or log at debug level."""
    if DEBUG_MODE:
        print(*args, **kwargs)
    # Always log at debug level for file logging
    logger = logging.getLogger('app')
    logger.debug(" ".join(str(a) for a in args))
