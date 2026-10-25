"""Pull the Ollama model named in the app config, so `docker compose up` needs no manual step.

Run as `python -m app.tools.pull_model`. Does nothing if the configured LLM is not an Ollama model.
"""

import json

import httpx

from app.core.config import ProviderConfig, Settings, load_config

OLLAMA_PREFIXES = ("ollama/", "ollama_chat/")


def ollama_model_name(cfg: ProviderConfig) -> str | None:
    """Return the name Ollama knows (e.g. "qwen3:4b"), or None if cfg is not an Ollama model."""
    model = str(cfg.params.get("model", ""))
    if cfg.provider != "litellm" or not model.startswith(OLLAMA_PREFIXES):
        return None
    return model.split("/", 1)[1]


def pull(client: httpx.Client, name: str) -> None:
    with client.stream("POST", "/api/pull", json={"model": name}) as response:
        response.raise_for_status()
        last_status = None
        for line in response.iter_lines():
            if not line:
                continue
            message = json.loads(line)
            if "error" in message:
                raise RuntimeError(message["error"])
            status = message.get("status", "")
            if status != last_status:
                print(status, flush=True)
                last_status = status


def main() -> None:
    cfg = load_config(Settings().app_config)
    name = ollama_model_name(cfg.llm)
    if name is None:
        print("The configured LLM is not an Ollama model; nothing to pull.")
        return
    api_base = str(cfg.llm.params["api_base"])
    print(f"Pulling {name} from {api_base}", flush=True)
    with httpx.Client(base_url=api_base, timeout=None) as client:
        pull(client, name)
    print("Model ready.")


if __name__ == "__main__":
    main()
