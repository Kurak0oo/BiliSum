def normalize_openai_compatible_model_name(model: str) -> str:
    normalized = str(model or "").strip()
    if normalized.lower().startswith("mimo-"):
        return normalized.lower()
    return normalized
