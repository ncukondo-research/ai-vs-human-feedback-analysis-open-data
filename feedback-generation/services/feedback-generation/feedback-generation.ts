import { chatCompletion, type CompletionResponse, type Message } from "../../lib/chat-completion.js";
import { promptGeneration } from "./prompt-template.js";

type Feedback = {
  status: "success";
  tried: number;
  feedback: string;
  tokens: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  }
} & Omit<CompletionResponse, "choices"|"usage">;
type ErrorFeedback = {
  status: "failure";
  tried: number;
  message: string;
};
type Input = {
  content: string;
  feedback?: string;
}[];

const generateFeedback = async (input: Input,retry=0,tried=0): Promise<Feedback | ErrorFeedback> => {
  const {content} = input.at(-1) ?? {content:""};
  if(content === "") return {status:"failure",message:"No content provided",tried:tried+1};
  const prev = input.slice(0,-1).flatMap(({content,feedback}) => ([
    {
      role: "user",
      content: `# 臨床実習記録\n\n${content}`,
    },
    {
      role: "assistant",
      content: feedback ?? "",
    }
  ] as const satisfies ReadonlyArray<Message>));
  const systemText = promptGeneration(content);

  const messages = [
    {
      role: "system",
      content: systemText,
    },
    ...prev,
    {
      role: "user",
      content: `# 臨床実習記録\n\n${content}`,
    }
  ] as const satisfies ReadonlyArray<Message>;
  const res = await chatCompletion(messages,"gpt-4o",{temperature:1,response_format:{type:"json_object"}});
  if(res === undefined && retry > 0) return await generateFeedback(input,retry-1,tried+1);
  if(res === undefined) return {status:"failure",message:"Failed to generate feedback",tried:tried+1};
  console.log(res)
  const {choices, usage,...rest} = res;
  const message = choices ? choices[0]?.message?.content : "";
  let feedback = "";
  try{
    feedback = message ? JSON.parse(message).Feedback as string ?? "" : "";

  }catch(e){
    console.error(e);
  }
  if(feedback === "" && retry > 0) return await generateFeedback(input,retry-1,tried+1);
  if(feedback === "") return {status:"failure",message:`Failed to extract feedback from response. Response: ${JSON.stringify(res)}`,tried:tried+1};
  return { status:"success",...rest, tokens:usage,feedback,tried:tried+1};
};

export { generateFeedback };