import type { VercelRequest, VercelResponse } from '@vercel/node';
import axios, { isAxiosError } from 'axios';

// Vercel будет автоматически загружать эти переменные из настроек проекта
const yandexApiKey = process.env.YANDEX_API_KEY;
const yandexFolderId = process.env.YANDEX_FOLDER_ID;

export default async function handler(
  request: VercelRequest,
  response: VercelResponse,
) {
  // --- НАЧАЛО БЛОКА ДЛЯ РЕШЕНИЯ ПРОБЛЕМЫ CORS ---
  // Устанавливаем заголовки, разрешающие кросс-доменные запросы
  response.setHeader('Access-Control-Allow-Credentials', 'true');
  response.setHeader('Access-Control-Allow-Origin', '*'); // Разрешаем все домены
  response.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  response.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Обрабатываем предварительный запрос OPTIONS от браузера
  if (request.method === 'OPTIONS') {
    return response.status(200).end();
  }
  // --- КОНЕЦ БЛОКА ДЛЯ РЕШЕНИЯ ПРОБЛЕМЫ CORS ---
  // Разрешаем только POST-запросы
  if (request.method !== 'POST') {
    return response.status(405).json({ error: 'Method Not Allowed' });
  }

  // Проверяем, что сервер настроен правильно
  if (!yandexApiKey || !yandexFolderId) {
    console.error("Server configuration error: Missing Yandex API Key or Folder ID.");
    return response.status(500).json({ error: 'Ошибка конфигурации сервера.' });
  }

  try {
    const { summary: dailySummary } = request.body;

    if (!dailySummary || typeof dailySummary !== 'string') {
      return response.status(400).json({ error: "Тело запроса должно содержать 'summary'." });
    }

    console.log("Получена сводка, вызываю YandexGPT API...");

    const modelUri = `gpt://${yandexFolderId}/yandexgpt-lite`;
    const systemPrompt =
      "Ты — вдумчивый и эмпатичный коуч по саморазвитию. " +
      "Проанализируй мои записи за день. " +
      "Определи ключевые темы и паттерны в моих мыслях и действиях. " +
      "Дай 2-3 конкретных, действенных и поддерживающих совета на завтра. " +
      "Сделай акцент на позитивном подкреплении и небольших шагах. " +
      "Отвечай на русском языке.";

    const requestPayload = {
      modelUri,
      completionOptions: { stream: false, temperature: 0.6, maxTokens: "1500" },
      messages: [
        { role: "system", text: systemPrompt },
        { role: "user", text: `Вот мои записи:\n\n${dailySummary}` },
      ],
    };

    const yandexResponse = await axios.post(
      "https://llm.api.cloud.yandex.net/foundationModels/v1/completion",
      requestPayload,
      { headers: { "Authorization": `Api-Key ${yandexApiKey}`, "Content-Type": "application/json" } },
    );

    const recommendation = yandexResponse.data?.result?.alternatives?.[0]?.message?.text;

    if (typeof recommendation === "string" && recommendation.length > 0) {
      console.log("Успешно получена рекомендация от YandexGPT.");
      return response.status(200).json({ recommendation });
    } else {
      console.error("Ответ от YandexGPT пустой или некорректный", { yandexResponse: yandexResponse.data });
      return response.status(500).json({ error: "AI-сервис вернул пустой ответ." });
    }
  } catch (error) {
    const isAnAxiosError = isAxiosError(error);
    const errorDetails = {
      errorMessage: isAnAxiosError ? error.message : String(error),
      responseStatus: isAnAxiosError ? error.response?.status : "N/A",
    };
    console.error("Ошибка при вызове YandexGPT API", errorDetails);
    return response.status(500).json({ error: "Не удалось связаться с AI-сервисом." });
  }
}