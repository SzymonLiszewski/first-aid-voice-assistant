from app.providers.base import Message


def build_prompt(system_prompt: str, history: list[Message], user_text: str) -> list[Message]:
    return [
        Message(role="system", content=system_prompt),
        *history,
        Message(role="user", content=user_text),
    ]
