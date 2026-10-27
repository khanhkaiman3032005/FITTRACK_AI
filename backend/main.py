import os
import base64
import json

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

load_dotenv()

app = FastAPI(title="FITTRACK AI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3.8-flash")
GEMINI_FALLBACK_MODEL = os.getenv(
    "GEMINI_FALLBACK_MODEL",
    "gemini-3.5-flash-lite",
)


class ChatRequest(BaseModel):
    prompt: str


class FoodImageRequest(BaseModel):
    image_base64: str
    mime_type: str = "image/jpeg"


@app.get("/")
async def root():
    return {
        "status": "ok",
        "message": "FITTRACK AI Backend đang hoạt động",
    }


@app.post("/api/gemini")
async def gemini(request: ChatRequest):
    if not GEMINI_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Chưa cấu hình GEMINI_API_KEY",
        )

    if not request.prompt.strip():
        raise HTTPException(
            status_code=400,
            detail="Prompt không được để trống",
        )

    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "text": request.prompt,
                    }
                ]
            }
        ]
    }

    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY,
    }

    models = [
        GEMINI_MODEL,
        GEMINI_FALLBACK_MODEL,
    ]

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            for model in models:
                url = (
                    "https://generativelanguage.googleapis.com/v1beta/"
                    f"models/{model}:generateContent"
                )

                print(f"Đang gọi Gemini model: {model}")

                response = await client.post(
                    url,
                    headers=headers,
                    json=payload,
                )

                if response.status_code == 503:
                    print(f"Model {model} đang quá tải.")
                    continue

                if response.status_code == 429:
                    print(f"Model {model} đã đạt giới hạn quota.")
                    continue

                if response.status_code != 200:
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"Gemini API lỗi: {response.text}",
                    )

                data = response.json()
                candidates = data.get("candidates")

                if not candidates:
                    continue

                parts = candidates[0].get(
                    "content",
                    {},
                ).get("parts", [])

                if not parts:
                    continue

                text = parts[0].get("text", "").strip()

                if not text:
                    continue

                return {
                    "success": True,
                    "text": text,
                    "model": model,
                }

        raise HTTPException(
            status_code=503,
            detail="Tất cả model Gemini hiện không khả dụng.",
        )

    except HTTPException:
        raise

    except httpx.RequestError as e:
        print(f"GEMINI REQUEST ERROR: {repr(e)}")

        raise HTTPException(
            status_code=503,
            detail=f"Không thể kết nối Gemini: {str(e)}",
        )
    
@app.post("/api/analyze-food")
async def analyze_food(request: FoodImageRequest):
    if not GEMINI_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Chưa cấu hình GEMINI_API_KEY",
        )

    if not request.image_base64.strip():
        raise HTTPException(
            status_code=400,
            detail="Ảnh không được để trống",
        )

    prompt = """
Bạn là FITTRACK AI chuyên phân tích dinh dưỡng từ hình ảnh món ăn.

Hãy quan sát ảnh và ước tính món ăn trong ảnh.

Chỉ trả về JSON hợp lệ, tuyệt đối không dùng Markdown, không dùng ```json.

Cấu trúc bắt buộc:

{
  "food_name": "Tên món ăn bằng tiếng Việt",
  "portion": "Khẩu phần ước tính",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "confidence": 0
}

Quy tắc:
- calories là kcal ước tính của toàn bộ khẩu phần nhìn thấy.
- protein, carbs, fat tính bằng gram.
- confidence là số nguyên từ 0 đến 100.
- Nếu có nhiều thành phần, hãy ước tính tổng toàn bộ món ăn.
- Không được bịa độ chính xác tuyệt đối.
- Nếu ảnh không phải món ăn, đặt food_name là "Không nhận diện được món ăn" và confidence là 0.
"""

    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "text": prompt,
                    },
                    {
                        "inline_data": {
                            "mime_type": request.mime_type,
                            "data": request.image_base64,
                        }
                    },
                ]
            }
        ],
        "generationConfig": {
            "responseMimeType": "application/json",
            "temperature": 0.2,
        },
    }

    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY,
    }

    models = [
        GEMINI_MODEL,
        GEMINI_FALLBACK_MODEL,
    ]

    try:
        async with httpx.AsyncClient(timeout=90.0) as client:
            for model in models:
                url = (
                    "https://generativelanguage.googleapis.com/v1beta/"
                    f"models/{model}:generateContent"
                )

                print(f"Đang phân tích món ăn bằng: {model}")

                try:
                    response = await client.post(
                        url,
                        headers=headers,
                        json=payload,
                        timeout=45.0 if model == GEMINI_MODEL else 60.0,
                    )
                except httpx.TimeoutException as e:
                    print(f"Gemini Vision timeout [{model}]: {repr(e)}")
                    continue
                except httpx.RequestError as e:
                    print(f"Gemini Vision connection error [{model}]: {repr(e)}")
                    continue

                if response.status_code == 503:
                    print(f"Model {model} đang quá tải.")
                    continue

                if response.status_code == 429:
                    print(f"Model {model} đã đạt giới hạn quota.")
                    continue

                if response.status_code != 200:
                    print(
                        f"Gemini Vision lỗi {response.status_code}: "
                        f"{response.text}"
                    )
                    continue

                data = response.json()
                candidates = data.get("candidates")

                if not candidates:
                    continue

                parts = candidates[0].get(
                    "content",
                    {},
                ).get("parts", [])

                if not parts:
                    continue

                raw_text = parts[0].get("text", "").strip()

                if not raw_text:
                    continue

                raw_text = raw_text.replace("```json", "")
                raw_text = raw_text.replace("```", "")
                raw_text = raw_text.strip()

                try:
                    food = json.loads(raw_text)
                except json.JSONDecodeError:
                    print(f"JSON món ăn không hợp lệ: {raw_text}")
                    continue

                return {
                    "success": True,
                    "food": food,
                    "model": model,
                }

        raise HTTPException(
            status_code=503,
            detail="Không thể phân tích ảnh bằng các model Gemini hiện tại.",
        )

    except HTTPException:
        raise

    except httpx.RequestError as e:
        print(f"GEMINI VISION REQUEST ERROR: {repr(e)}")

        raise HTTPException(
            status_code=503,
            detail=f"Không thể kết nối Gemini: {str(e)}",
        )