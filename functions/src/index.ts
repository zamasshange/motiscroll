import { initializeApp } from "firebase-admin/app";

initializeApp();

export { approveItem, approveBatch, previewApproval, rejectItem, retireItem } from "./approve.js";
export { resolveAuthors } from "./resolveAuthors.js";
export { deleteAccount, recordView } from "./account.js";
export { onItemWritten, onCandidateCreated, onSourceWritten, onReportCreated } from "./checks.js";
export { draftDeeper } from "./deeper.js";
export {
  discoverWikiquote,
  discoverWikiquoteNightly,
  importPublicDomain,
  discoverFeeds,
  importItems,
} from "./discover.js";
export { fetchAuthorImage } from "./images.js";
export { sendReminderBucket, syncReminderBucket, writeDaily } from "./notify.js";
