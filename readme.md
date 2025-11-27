# 🔒 Local Private AI Agent (Ollama + RAG + FastAPI)

A fully offline, privacy-first AI agent system powered by:

- **Ollama** (local LLM + embeddings)
- **ChromaDB** (private vector store)
- **LangChain** (agent + tools)
- **FastAPI** (backend server)
- **RAG** for document retrieval
- **Multiple tools** (RAGSearch, OCR, MathTool, LocalSearch, Schedule)

Everything runs **locally** — no cloud calls, no external APIs.

---

## 🚀 Features

- 🔐 **100% offline** (LLM + embeddings run on device)
- 📄 **PDF + TXT ingestion** into ChromaDB
- 🧠 **Autonomous agent** with multiple tools
- 🖼 OCR image tool support
- 📱 Ready for iOS/Android/Web app integration
- 🐍 FastAPI backend for easy consumption
- ⚡ Safe tools (no crashes, no misuse)

---

## 📦 Setup Instructions

### 1️⃣ Create & activate virtual environment

```bash
python3 -m venv venv
source venv/bin/activate
2️⃣ Pull Ollama embedding models
ollama pull nomic-embed-text
ollama pull mxbai-embed-large
(Optional — pull your LLM too)
ollama pull llama3
3️⃣ Install Python dependencies
pip install -r requirements.txt
4️⃣ Ingest documents into ChromaDB
Place your .pdf or .txt files inside:
data/docs/
Then run:
python vectordb/ingest.py
5️⃣ Start the FastAPI server
uvicorn main:app --reload --port 8000
Server runs at:
http://localhost:8000
Default endpoints:
POST /ask → ask questions
POST /ask-image → OCR + answer
📁 Folder Structure
backend/
│
├── main.py
├── agent/
│   ├── agent_builder.py
│   ├── embeddings.py
│   ├── tools/
│   │   ├── rag_tool.py
│   │   ├── ocr_tool.py
│   │   ├── math_tool.py
│   │   ├── local_search_tool.py
│   │   └── schedule_tool.py
│   └── __init__.py
│
├── vectordb/
│   ├── ingest.py
│   └── chroma/
│
├── data/
│   └── docs/
└── requirements.txt
📝 Notes
Works entirely offline
Perfect for sensitive use cases
Supports PDF, TXT, OCR
Uses a safe-agent design to prevent tool misuse
Easily extendable with new tools (browser, SQL, custom APIs)
⭐ License
MIT — use freely for personal or commercial projects.

---

If you want, I can also generate:

✅ A matching `requirements.txt`  
✅ A GitHub-friendly project banner  
✅ A diagram for the README  
Just ask!