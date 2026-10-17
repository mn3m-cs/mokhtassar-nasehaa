"""Print only the rate-limit events from a Claude Code execution file, as JSON.

The execution file is the whole session, tool output included. Hermes needs the limit
readings and the run's cost from it and nothing else, so this keeps the rate-limit events and
the numbers of the final result event (mn3m-cs/hermes-skills#266), and drops the rest.
"""

import json
import os
import sys


def rate_limit_events(node):
    if isinstance(node, dict):
        if node.get("type") == "rate_limit_event":
            yield node
            return
        for value in node.values():
            yield from rate_limit_events(value)
    elif isinstance(node, list):
        for value in node:
            yield from rate_limit_events(value)


RESULT_FIELDS = ("num_turns", "duration_ms", "total_cost_usd", "is_error", "subtype")
USAGE_FIELDS = ("input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens")


def result_summary(documents):
    """Numbers from the last result event, never its text."""
    found = None
    for document in documents:
        for node in document if isinstance(document, list) else [document]:
            if isinstance(node, dict) and node.get("type") == "result":
                found = node
    if found is None:
        return None
    usage = found.get("usage") if isinstance(found.get("usage"), dict) else {}
    summary = {field: found.get(field) for field in RESULT_FIELDS}
    summary["usage"] = {field: usage.get(field) for field in USAGE_FIELDS}
    return summary


def main(path):
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    try:
        documents = [json.loads(text)]
    except json.JSONDecodeError:
        documents = [json.loads(line) for line in text.splitlines() if line.strip()]
    events = [event for document in documents for event in rate_limit_events(document)]
    json.dump(
        {
            "account": os.environ.get("CLAUDE_ACCOUNT") or None,
            "run_id": os.environ.get("GITHUB_RUN_ID"),
            "events": events,
            "result": result_summary(documents),
        },
        sys.stdout,
        ensure_ascii=False,
    )
    sys.stdout.write("\n")


if __name__ == "__main__":
    main(sys.argv[1])
