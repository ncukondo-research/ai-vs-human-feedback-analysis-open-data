import { type Output,parseInput,type SuccessResponse } from "../../lib/types.js";
import { generateFeedback } from "./feedback-generation.js";

const handler = async (input: unknown): Promise<Output> => {
  const parseResult = parseInput(input);
  if(!parseResult.success){
    return {
      status: "failure",
      message: `Invalid input structure : ${parseResult.error}`
    }
  }
  try{
    const {key, data} = parseResult.data;
    const responses = await Promise.all(data.map(async ({id,contents}) => {
      const res = await generateFeedback(contents);
      if(res.status === "success") {
        return {
          status: "success",
          feedback: res.feedback,
          tokens:{
            total:res.tokens.total_tokens,
            prompt:res.tokens.prompt_tokens,
            completion:res.tokens.completion_tokens,
          },
          id,
        } as const satisfies SuccessResponse;
      }
      return {id,...res};
    }));
    return {
      status: "success",
      key,
      data: responses
    };
  }catch(e){
    const message = e instanceof Error ? e.message : "An error occurred";
    return {
      status: "failure",
      message: message
    }
  }
}

const dummyHandler = async (input: unknown): Promise<Output> => {
  const parseResult = parseInput(input);
  if(!parseResult.success){
    return {
      status: "failure",
      message: `Invalid input structure : ${parseResult.error}`
    }
  }
  const {key, data} = parseResult.data;
  try{
    const responses = await Promise.all(data.map(async ({id,contents}) => {
      return {
        status: "success",
        feedback: "feedback sample",
        tokens:{
          total:0,
          prompt:0,
          completion:0,
        },
        id,
      } as const satisfies SuccessResponse;
    }
    ));
    return {
      status: "success",
      key,
      data: responses
    }
  }catch(e){
    const message = e instanceof Error ? e.message : "An error occurred";
    return {
      status: "failure",
      message: message
    }
  }
}

export {handler,dummyHandler}