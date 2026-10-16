---
name: python-docstrings
description: Format, validate, and write Python docstrings using Google docstring style with comprehensive section requirements, variable docstrings, and zero Sphinx markup. Use when authoring, reviewing, or refactoring Python docstrings.
---

# Python Docstrings Skill

Write clear, structured, and modern Python docstrings. This skill enforces Google docstring style with three core constraints:
1. **Zero Sphinx syntax**: Ban all `:param:`, `:class:`, `:meth:`, `:func:`, and related directives.
2. **Mandatory sections**: Populate `Args:`, `Returns:`, `Yields:`, and `Examples:` on all relevant functions, require `Raises:` for fallible code, and require `Attributes:` and `Methods:` on classes.
3. **Variable docstrings**: Document ambiguous variables, module constants, and type aliases immediately below their assignment.

---

## 1. Core Constraints

### Constraint 1: Zero Sphinx Markup
Never use Sphinx reStructuredText role or field syntax. Use clean Google docstring style section headers and plain text.

- ❌ **Forbidden**: `:param x:`, `:type x: int`, `:return:`, `:rtype:`, `:raises ValueError:`, `:class:`MyClass``, `:meth:`obj.method``, `:func:`helper``
- ✅ **Required**: Use standard Google style section headers (`Args:`, `Returns:`, `Raises:`) and plain prose without Sphinx roles.

### Constraint 2: Mandatory Sections

Every docstring must populate all applicable sections. Do not omit sections that describe the public interface.

#### Functions and Methods
1. **Summary line**: Imperative mood on the first line (e.g., `"Calculate the total score."`, not `"Calculates..."`).
2. **Detailed description** (optional): Additional context separated by a blank line.
3. **`Args:`** (Mandatory when function accepts arguments):
   - Every parameter must be listed with its description.
   - When Python type hints exist in the signature, omit redundant types from the header:
     ```python
     Args:
         user_id: Unique identifier for the account user.
         timeout: Maximum wait time in seconds. Defaults to 30.0.
     ```
   - If the function accepts `*args` or `**kwargs`, document both:
     ```python
     Args:
         *args: Positional arguments forwarded to base_handler().
         **kwargs: Arbitrary keyword options passed to Session.
     ```
4. **`Returns:`** (Mandatory for non-generator functions):
   - State what the function returns and describe special cases (e.g., `None` when not found).
   ```python
   Returns:
       Calculated standard deviation as a float, or None if values is empty.
   ```
5. **`Yields:`** (Mandatory for generator functions):
   - State the value yielded on each iteration.
   ```python
   Yields:
       Next parsed Record instance from the input stream.
   ```
6. **`Raises:`** (Mandatory for any fallible function or method):
   - List every exception that callers should expect and handle.
   - Describe the exact condition that triggers the exception.
   ```python
   Raises:
       ValueError: If channel_count is less than 1.
       FileNotFoundError: If the file specified by config_path does not exist.
   ```
7. **`Examples:`** (Mandatory):
   - Provide runnable, clear examples formatted with doctest prompts (`>>>`) or fenced code blocks.
   ```python
   Examples:
       >>> from math_utils import add
       >>> add(2, 3)
       5
   ```
8. **`Notes:` / `References:`** (Optional):
   - Use for performance characteristics, algorithmic complexity, mathematical formulas, or links to specifications.

#### Classes
1. **Summary line**: Single sentence describing the class purpose.
2. **`Attributes:`** (Mandatory):
   - List all public instance and class attributes with their roles.
   ```python
   Attributes:
       name: Human-readable label for the runner instance.
       is_active: Boolean state indicating whether the worker is running.
       max_retries: Maximum number of retry attempts permitted.
   ```
3. **`Methods:`** (Mandatory):
   - Summarize the public interface and primary methods.
   ```python
   Methods:
       start(): Initialize background threads and begin processing.
       stop(): Gracefully drain active jobs and terminate workers.
       status(): Return current execution statistics.
   ```
4. **`Examples:`** (Mandatory):
   - Show how to instantiate and use the class.

### Constraint 3: Variable and Type Alias Docstrings

Document variables that carry ambiguity, domain-specific conventions, non-obvious units, or custom formatting. Place a triple-quoted string immediately below the assignment.

This applies to:
- Module-level constants
- Type aliases
- Configuration variables
- Class-level attributes with domain constraints

**Format**:
```python
Std = tuple[float, float, float]
"""Standard deviation values for three channels (e.g., RGB).

Represents per-channel normalisation metrics formatted as (R, G, B).
"""

MAX_BATCH_SIZE: int = 128
"""Maximum number of records sent in one network payload.

Values above 128 cause timeout errors in the upstream ingestion service.
"""
```

---

## 2. Formatting Standards

### Indentation and Spacing
- Use 4 spaces for indentation inside sections.
- Keep section names followed immediately by a colon: `Args:`, `Returns:`, `Yields:`, `Raises:`, `Examples:`, `Attributes:`, `Methods:`, `Notes:`, `References:`.
- Wrap multi-line parameter descriptions by indenting continuation lines 4 spaces beyond the parameter name.

### Summary Lines
- First line must be a concise summary ended with a period.
- Use imperative mood: `"Fetch the profile."`, not `"Fetches the profile."` or `"This function fetches..."`.
- Leave one blank line between the summary and the extended explanation or section headers.

---

## 3. Concrete Examples

### Complete Function Docstring

```python
def calculate_moving_average(
    values: list[float],
    window_size: int,
    pad_mode: str = "reflect",
) -> list[float]:
    """Compute the moving average across a numerical sequence.

    Applies a sliding rectangular window over values with length window_size.

    Args:
        values: Ordered sequence of numeric readings to smooth.
        window_size: Width of the sliding window in element counts. Must be
            an odd integer greater than or equal to 1.
        pad_mode: Boundary handling strategy. Allowed options are "reflect",
            "edge", or "zero". Defaults to "reflect".

    Returns:
        New list of floats containing smoothed values matching the input length.

    Raises:
        ValueError: If window_size is less than 1 or is an even integer.
        ValueError: If pad_mode is not one of the allowed options.

    Examples:
        >>> calculate_moving_average([1.0, 2.0, 3.0, 4.0, 5.0], window_size=3)
        [1.3333333333333333, 2.0, 3.0, 4.0, 4.666666666666667]

    Notes:
        Time complexity is O(N) where N is len(values).
    """
    ...
```

### Complete Generator Function Docstring

```python
from collections.abc import Iterator
from pathlib import Path

def stream_log_records(
    file_path: Path,
    min_severity: str = "INFO",
) -> Iterator[dict[str, str]]:
    """Yield log entries from disk that match or exceed the minimum severity.

    Streams lines one at a time from file_path without loading the full
    log file into memory.

    Args:
        file_path: Path pointing to the target .log file on disk.
        min_severity: Severity cutoff. Valid options are "DEBUG", "INFO",
            "WARNING", and "ERROR". Defaults to "INFO".

    Yields:
        Dictionary representing a single log record with keys "timestamp",
        "level", and "message".

    Raises:
        FileNotFoundError: If file_path does not exist on disk.
        ValueError: If min_severity is not a recognized log level.

    Examples:
        >>> logs = list(stream_log_records(Path("app.log"), min_severity="ERROR"))
        >>> all(record["level"] == "ERROR" for record in logs)
        True
    """
    ...
```

### Complete Class Docstring

```python
class TaskQueue:
    """In-memory prioritized task buffer for asynchronous job workers.

    Maintains tasks sorted by priority level and coordinates worker consumption.

    Attributes:
        max_capacity: Maximum number of jobs permitted in queue before backpressure.
        total_enqueued: Monotonically increasing counter of all scheduled jobs.
        is_paused: Flag indicating whether workers should defer dequeuing jobs.

    Methods:
        push(task, priority=0): Add a job item to the priority queue.
        pop(): Remove and return the highest priority pending job.
        clear(): Discard all queued jobs and reset state.

    Examples:
        >>> queue = TaskQueue(max_capacity=100)
        >>> queue.push("send_email", priority=10)
        >>> queue.push("log_metrics", priority=1)
        >>> queue.pop()
        'send_email'
    """

    def __init__(self, max_capacity: int = 1000) -> None:
        """Initialize the task queue buffer.

        Args:
            max_capacity: Upper threshold of queued items. Defaults to 1000.

        Raises:
            ValueError: If max_capacity is less than 1.

        Examples:
            >>> queue = TaskQueue(max_capacity=50)
            >>> queue.max_capacity
            50
        """
        self.max_capacity = max_capacity
        self.total_enqueued = 0
        self.is_paused = False
```

### Complete Variable and Type Alias Docstrings

```python
from typing import TypeAlias

ChannelNorm: TypeAlias = tuple[float, float, float]
"""Mean normalisation values for three image channels.

Represents per-channel mean metrics formatted as (R, G, B) with values
in range [0.0, 1.0].
"""

DEFAULT_RETRIES: int = 3
"""Number of network connection retries before propagating an error.

A value of 0 disables retry logic completely.
"""
```

---

## 4. Verification Checklist

Before accepting a docstring, check off each item:

- [ ] **No Sphinx artifacts**: No `:param:`, `:class:`, `:meth:`, or other `:` roles exist.
- [ ] **Imperative summary**: First sentence starts with an imperative verb and ends with a period.
- [ ] **Mandatory sections included**:
  - [ ] `Args:` is populated for all parameters.
  - [ ] `Returns:` is present and describes return value and edge conditions.
  - [ ] `Yields:` is present for any generator.
  - [ ] `Raises:` documents all exceptions that callers can encounter.
  - [ ] `Examples:` contains runnable, illustrative code.
- [ ] **Class interface visible**: `Attributes:` and `Methods:` describe public members.
- [ ] **Ambiguous variables documented**: Ambiguous variables and type aliases have docstrings underneath their definitions.
