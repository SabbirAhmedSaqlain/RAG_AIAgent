from langchain.agents import initialize_agent, AgentType, Tool
from langchain_community.llms import Ollama

from agent.embeddings import get_embedding_model
from agent.tools.rag_tool import rag_search
from agent.tools.math_tool import calc
from agent.tools.ocr_tool import run_ocr
from agent.tools.schedule_tool import get_schedule
from agent.tools.local_search_tool import local_search


def safe_tool(func):
    """Prevent any tool from crashing the agent."""
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            return f"[Tool Error] {str(e)}"
    return wrapper


SYSTEM_MESSAGE = """
You are a smart assistant.

TOOL RULES:
- Do NOT use MathTool unless the user provides a numeric math expression.
- Do NOT use RAGSearch unless the user explicitly asks to search private documents.
- Do NOT use OCRTool unless the user mentions images or extraction.
- Do NOT use LocalSearch unless the user asks to search or lookup something.
- Do NOT use ScheduleTool unless the user mentions schedule or events.
- For general knowledge questions (example: 'what is gravity'), answer DIRECTLY without using any tools.
"""


def build_agent():

    tools = [
        Tool(
            name="RAGSearch",
            func=safe_tool(rag_search),
            description="Search private locally stored documents."
        ),
        Tool(
            name="MathTool",
            func=safe_tool(calc),
            description="Evaluate ONLY numeric math expressions."
        ),
        Tool(
            name="OCRTool",
            func=safe_tool(run_ocr),
            description="Extract text from a local image."
        ),
        Tool(
            name="ScheduleTool",
            func=safe_tool(get_schedule),
            description="Get a user's schedule."
        ),
        Tool(
            name="LocalSearch",
            func=safe_tool(local_search),
            description="Local simple search utility."
        )
    ]

    llm = Ollama(model="llama3.1:8b", base_url="http://localhost:11434")

    agent = initialize_agent(
        tools,
        llm,
        agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
        verbose=True,
        system_message=SYSTEM_MESSAGE,
        handle_parsing_errors=True
    )

    return agent
