"""Terminal test client: send a ready-made transcript to the dev endpoint and print the answer.

Usage:
    uv run python scripts/chat_client.py "Mój kolega nie oddycha, co mam robić?"
"""

import argparse

import httpx


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("text", help="transcript to send")
    parser.add_argument("--url", default="http://localhost:8000/dev/chat")
    args = parser.parse_args()

    r = httpx.post(args.url, json={"text": args.text}, timeout=120)
    if r.is_error:
        print(f"[error {r.status_code}] If this is an emergency, call 112.")
        raise SystemExit(1)
    data = r.json()
    print(data["answer"])
    print(f"[{data['elapsed_ms']} ms]")


if __name__ == "__main__":
    main()
