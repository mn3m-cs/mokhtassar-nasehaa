"""Print only the rate-limit events from a Claude Code execution file, as JSON.

The execution file is the whole session, tool output included. Hermes needs the limit
readings from it and nothing else, so this keeps the events and drops the rest.
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
        },
        sys.stdout,
        ensure_ascii=False,
    )
    sys.stdout.write("\n")


if __name__ == "__main__":
    main(sys.argv[1])
