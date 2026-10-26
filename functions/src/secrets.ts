import { defineSecret } from "firebase-functions/params";

export const contactEmail = defineSecret("CONTACT_EMAIL");
export const llmApiKey = defineSecret("LLM_API_KEY");
export const youtubeApiKey = defineSecret("YOUTUBE_API_KEY");

export function enforceAppCheck(): boolean {
  return process.env.FUNCTIONS_EMULATOR !== "true";
}
