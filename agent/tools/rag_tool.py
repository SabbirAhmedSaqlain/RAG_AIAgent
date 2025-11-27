from langchain_community.vectorstores import Chroma
from agent.embeddings import get_embedding_model

CHROMA_DIR = "vectordb/chroma"

emb = get_embedding_model()

db = Chroma(
    persist_directory=CHROMA_DIR,
    embedding_function=emb
)

def rag_search(query: str):
    try:
        results = db.similarity_search(query, k=4)

        if not results:
            return "No relevant documents found."

        return "\n\n".join([doc.page_content for doc in results])
    except Exception as e:
        return f"[RAG ERROR] {str(e)}"
