import {z} from 'zod';

const apiKey = process.env.API_KEY ?? "";

const inputSchema = z.object({
  key: z.literal(apiKey),
  data: z.array(z.object({
    id:z.string(),
    contents: z.array(z.object({
      content: z.string(),
      feedback: z.string().optional(),
    }))
  }))
});

type Input = z.infer<typeof inputSchema>;

const successResponseSchema = z.object({
  status: z.literal("success"),
  id: z.string(),
  feedback: z.string(),
  tokens: z.object({
    total: z.number(),
    prompt: z.number(),
    completion: z.number(),
  }),
});

const failureResponseSchema = z.object({
  status: z.literal("failure"),
  id: z.string(),
  message: z.string(),
});

const responseSchema = z.discriminatedUnion('status',[
  successResponseSchema,
  failureResponseSchema,
]);

const successOutputSchema = z.object({
  status: z.literal("success"),
  key: z.literal(apiKey),
  data: z.array(responseSchema)
});

const failureOutputSchema = z.object({
  status: z.literal("failure"),
  message: z.string(),
});

const outputSchema = z.discriminatedUnion('status',[
  successOutputSchema,
  failureOutputSchema,
]);

type Response = z.infer<typeof responseSchema>;
type SuccessResponse = z.infer<typeof successResponseSchema>;
type FailureResponse = z.infer<typeof failureResponseSchema>;
type Output = z.infer<typeof outputSchema>;

const parseInput = (input: unknown) => {
  return inputSchema.safeParse(input);
}

const parseOutput = (output: unknown) => {
  return outputSchema.safeParse(output);
}

export {
  type Input,
  type Output,
  type Response,
  type SuccessResponse,
  type FailureResponse,
  inputSchema,
  outputSchema,
  parseInput,
  parseOutput
}