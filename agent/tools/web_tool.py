# 1. REMOVE the redundant "import duckduckgo_search" line.
# 2. MOVE the "from ... import DDGS" to the top.

def local_search(query: str):
    """Simple private search for your local docs or fallback text."""
    return f"No internet search allowed. Received query: {query}"
