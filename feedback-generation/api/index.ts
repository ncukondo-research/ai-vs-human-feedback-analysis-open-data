import type { VercelRequest, VercelResponse } from "@vercel/node";
import { handler } from "../services/feedback-generation/post-handler.js";

export default async function (req: VercelRequest, res: VercelResponse) {
  if (req.method === 'POST') {
    res.status(200).json(await handler(req.body));
  } else {
    res.send(`The method ${req.method} is not supported`);
  }
}