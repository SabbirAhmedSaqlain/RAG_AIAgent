import os
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader, TextLoader
from langchain_community.vectorstores import Chroma
from agent.embeddings import get_embedding_model


DATA_DIR = "data/"
CHROMA_DIR = "vectordb/chroma"


def load_documents():
    docs = []
    for file in os.listdir(DATA_DIR):
        path = os.path.join(DATA_DIR, file)

        # ------------ PDF ------------
        if file.lower().endswith(".pdf"):
            print(f"[INGEST] Loading PDF: {file}")
            loader = PyPDFLoader(path)
            docs.extend(loader.load())

        # ------------ TEXT ------------
        elif file.lower().endswith(".txt"):
            print(f"[INGEST] Loading TXT: {file}")
            loader = TextLoader(path, encoding="utf-8")
            docs.extend(loader.load())

        else:
            print(f"[SKIP] Unknown file type: {file}")

    return docs


def ingest():
    print("\n=== Starting Ingestion ===")

    raw_docs = load_documents()
    if not raw_docs:
        print("❌ No documents loaded. Check data/docs folder.")
        return

    print(f"Loaded {len(raw_docs)} raw documents.")

    splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
    split_docs = splitter.split_documents(raw_docs)

    print(f"Split into {len(split_docs)} chunks.")

    embeddings = get_embedding_model()

    print(f"Saving to Chroma at {CHROMA_DIR} ...")
    
    db = Chroma.from_documents(
        split_docs,
        embedding=embeddings,
        persist_directory=CHROMA_DIR
    )

    db.persist()
    print("✅ Ingestion complete. Vector DB saved.\n")


if __name__ == "__main__":
    ingest()
