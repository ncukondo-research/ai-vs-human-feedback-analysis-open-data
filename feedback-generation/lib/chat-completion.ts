export type Message = {
  role: "user" | "system" | "assistant";
  content: string;
};
type CompletionResponse = {
  id: string;
  object: "chat.completion";
  created: number;
  model: Model;
  choices: [
    {
      message: {
        content: string;
      };
    }
  ];
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  }
};


type Model = 
  | "gpt-4o"
  | "gpt-4"
  | "gpt-4-turbo"
  | "gpt-4-0125-preview"
  | "gpt-4-turbo-preview" 
  | "gpt-3.5-turbo-0125" 
  | "gpt-3.5-turbo-0125-turbo";

type chatCompletionOptions = {
  response_format?:{type: "json_object"|"text"};
  temperature?: number;
}

export const chatCompletion = async (
  messages: ReadonlyArray<Message>,
  model: Model = "gpt-4o",
  options: chatCompletionOptions = {}
): Promise<CompletionResponse | undefined> => {
  const body = JSON.stringify({
    messages,
    model,
    ...options
  });

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${process.env.AI_API_KEY}`,
    },
    body,
  });
  const data = await res.json() as CompletionResponse | undefined;
  return data;
};
  
export type { Model, CompletionResponse}
