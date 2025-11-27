from fastapi import FastAPI, Form, UploadFile
from agent.agent_builder import build_agent

app = FastAPI()
agent = build_agent()

@app.post("/ask")
async def ask_agent(query: str = Form(...)):
    reply = agent.run(query)
    return {"answer": reply}

@app.post("/ask-image")
async def ask_with_image(file: UploadFile, query: str = Form(...)):
    path = f"temp/{file.filename}"
    with open(path, "wb") as f:
        f.write(await file.read())

    full_query = f"Use OCRTool on '{path}', then answer: {query}"
    reply = agent.run(full_query)
    return {"answer": reply}
