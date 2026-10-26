import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { initializeApp } from "firebase-admin/app";

import { wordCount } from "./gate.js";

initializeApp();

interface SeedItem {
  id: string;
  type: "quote" | "speech";
  text: string;
  authorId: string;
  field: string;
  moods: string[];
  verified: boolean;
  source: { title: string; year?: number; url?: string; sourceType: "primary" | "secondary" };
  deeper: { context: string; didYouKnow: string; takeaway: string };
  related: string[];
  speech?: { durationSec: number; watchUrl: string; rightsStatus: string; rightsNotes: string };
}

const authors = [
  ["theodore-roosevelt", "Theodore Roosevelt", "26th President of the United States", 1858, 1919, "Q33866", "Theodore Roosevelt"],
  ["abraham-lincoln", "Abraham Lincoln", "16th President of the United States", 1809, 1865, "Q91", "Abraham Lincoln"],
  ["franklin-d-roosevelt", "Franklin D. Roosevelt", "32nd President of the United States", 1882, 1945, "Q8007", "Franklin D. Roosevelt"],
  ["frederick-douglass", "Frederick Douglass", "Abolitionist and orator", 1818, 1895, "Q34913", "Frederick Douglass"],
  ["patrick-henry", "Patrick Henry", "Virginia statesman", 1736, 1799, "Q318955", "Patrick Henry"],
  ["ralph-waldo-emerson", "Ralph Waldo Emerson", "Essayist", 1803, 1882, "Q48226", "Ralph Waldo Emerson"],
  ["henry-david-thoreau", "Henry David Thoreau", "Essayist", 1817, 1862, "Q131149", "Henry David Thoreau"],
  ["william-shakespeare", "William Shakespeare", "Playwright", 1564, 1616, "Q692", "William Shakespeare"],
  ["walt-whitman", "Walt Whitman", "Poet", 1819, 1892, "Q43413", "Walt Whitman"],
  ["isaac-newton", "Isaac Newton", "Natural philosopher", 1643, 1727, "Q935", "Isaac Newton"],
  ["placeholder", "Placeholder", "Not a real person", null, null, "", ""],
] as const;

const watchlist = [
  ["albert-einstein", "Einstein quotations are widely misattributed."],
  ["mark-twain", "Twain quotations are widely misattributed."],
  ["winston-churchill", "Churchill quotations are widely misattributed."],
  ["mahatma-gandhi", "Gandhi quotations are widely misattributed."],
  ["abraham-lincoln", "Lincoln quotations need a confirmed primary text."],
  ["marilyn-monroe", "Monroe quotations are widely misattributed."],
  ["buddha", "Buddha quotations are widely misattributed."],
  ["nelson-mandela", "Mandela quotations are widely misattributed."],
  ["maya-angelou", "Angelou quotations are widely misattributed."],
  ["steve-jobs", "Jobs quotations are widely misattributed."],
] as const;

const items: SeedItem[] = [
  {
    id: "tr-arena",
    type: "speech",
    text: "It is not the critic who counts; not the man who points out how the strong man stumbles, or where the doer of deeds could have done them better. The credit belongs to the man who is actually in the arena, whose face is marred by dust and sweat and blood…",
    authorId: "theodore-roosevelt",
    field: "leadership",
    moods: ["startingOver", "feelingStuck", "preWorkout"],
    verified: false,
    source: {
      title: "Citizenship in a Republic",
      year: 1910,
      url: "https://en.wikisource.org/wiki/Citizenship_in_a_Republic",
      sourceType: "primary",
    },
    deeper: {
      context: "Roosevelt gave this lecture at the Sorbonne in Paris on April 23, 1910.",
      didYouKnow: "The lecture is titled Citizenship in a Republic. The nickname The Man in the Arena came later.",
      takeaway: "Do one concrete thing today that you have been postponing because someone might judge it.",
    },
    related: ["douglass-struggle", "thoreau-dreams", "henry-liberty"],
    speech: {
      durationSec: 2700,
      watchUrl: "https://en.wikisource.org/wiki/Citizenship_in_a_Republic",
      rightsStatus: "public_domain",
      rightsNotes: "US government-era public-domain speech. Approving source must be a non-wiki edition before publish. TODO.",
    },
  },
  {
    id: "lincoln-gettysburg",
    type: "speech",
    text: "The world will little note, nor long remember what we say here; while it can never forget what they did here.",
    authorId: "abraham-lincoln",
    field: "leadership",
    moods: ["feelingStuck", "needFocus"],
    verified: false,
    source: {
      title: "Gettysburg Address (Nicolay draft)",
      year: 1863,
      url: "https://en.wikisource.org/wiki/Gettysburg_Address_(Nicolay_draft)",
      sourceType: "primary",
    },
    deeper: {
      context: "Lincoln spoke at Gettysburg on November 19, 1863. This sentence is from the Nicolay draft.",
      didYouKnow: "Lincoln spoke for about two minutes. The Nicolay copy differs slightly from the later Bliss copy.",
      takeaway: "Let someone else’s effort be the reason you finish a task you were about to drop.",
    },
    related: ["lincoln-charity", "douglass-struggle"],
    speech: {
      durationSec: 120,
      watchUrl: "https://en.wikisource.org/wiki/Gettysburg_Address_(Nicolay_draft)",
      rightsStatus: "government",
      rightsNotes: "Watchlist author. Needs a confirmed non-wiki primary before publish. TODO.",
    },
  },
  {
    id: "lincoln-charity",
    type: "speech",
    text: "With malice toward none; with charity for all; with firmness in the right, as God gives us to see the right, let us strive on to finish the work we are in…",
    authorId: "abraham-lincoln",
    field: "leadership",
    moods: ["badDay", "startingOver"],
    verified: false,
    source: {
      title: "Second Inaugural Address",
      year: 1865,
      url: "https://en.wikisource.org/wiki/Abraham_Lincoln%27s_Second_Inaugural_Address",
      sourceType: "primary",
    },
    deeper: {
      context: "Delivered March 4, 1865. Lincoln asked the country to finish the war’s work without hatred.",
      didYouKnow: "The sentence continues on to binding up the nation’s wounds. The ellipsis marks that cut.",
      takeaway: "Finish the hard conversation without trying to win it.",
    },
    related: ["lincoln-gettysburg", "fdr-fear"],
    speech: {
      durationSec: 420,
      watchUrl: "https://en.wikisource.org/wiki/Abraham_Lincoln%27s_Second_Inaugural_Address",
      rightsStatus: "government",
      rightsNotes: "Watchlist author. Wiki URL cannot approve. TODO.",
    },
  },
  {
    id: "fdr-fear",
    type: "speech",
    text: "So, first of all, let me assert my firm belief that the only thing we have to fear is fear itself—nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.",
    authorId: "franklin-d-roosevelt",
    field: "resilience",
    moods: ["badDay", "examStress", "startingOver"],
    verified: false,
    source: {
      title: "First Inaugural Address",
      year: 1933,
      url: "https://en.wikisource.org/wiki/Franklin_D._Roosevelt%27s_First_Inaugural_Address",
      sourceType: "primary",
    },
    deeper: {
      context: "Spoken March 4, 1933, during the bank crisis. Roosevelt argued that panic was worsening it.",
      didYouKnow: "He wrote the address himself. The fear line is in the opening.",
      takeaway: "When you feel frozen, write down the next small action and do only that.",
    },
    related: ["thoreau-dreams", "emerson-trust"],
    speech: {
      durationSec: 1200,
      watchUrl: "https://en.wikisource.org/wiki/Franklin_D._Roosevelt%27s_First_Inaugural_Address",
      rightsStatus: "government",
      rightsNotes: "Government speech. Wiki URL cannot approve. TODO: use a non-wiki government transcript.",
    },
  },
  {
    id: "douglass-struggle",
    type: "speech",
    text: "If there is no struggle there is no progress.",
    authorId: "frederick-douglass",
    field: "resilience",
    moods: ["feelingStuck", "startingOver", "examStress"],
    verified: false,
    source: {
      title: "West India Emancipation speech, Canandaigua, New York",
      year: 1857,
      url: "https://blackpast.org/african-american-history/1857-frederick-douglass-if-there-no-struggle-there-no-progress/",
      sourceType: "secondary",
    },
    deeper: {
      context: "Spoken August 3, 1857, in Canandaigua at a commemoration of West Indian emancipation.",
      didYouKnow: "The line sits inside a longer argument that people who want change without conflict want crops without plowing.",
      takeaway: "Name the hard part of a goal you care about, and do that part first today.",
    },
    related: ["tr-arena", "lincoln-gettysburg"],
    speech: {
      durationSec: 2400,
      watchUrl: "https://blackpast.org/african-american-history/1857-frederick-douglass-if-there-no-struggle-there-no-progress/",
      rightsStatus: "public_domain",
      rightsNotes: "Secondary transcript. TODO: confirm a primary printing before approval.",
    },
  },
  {
    id: "henry-liberty",
    type: "speech",
    text: "I know not what course others may take; but as for me, give me liberty, or give me death!",
    authorId: "patrick-henry",
    field: "leadership",
    moods: ["startingOver", "feelingStuck"],
    verified: false,
    source: {
      title: "Speech at the Second Virginia Convention (Wirt text)",
      year: 1775,
      url: "https://en.wikisource.org/wiki/Give_me_liberty,_or_give_me_death!",
      sourceType: "secondary",
    },
    deeper: {
      context: "The traditional setting is Richmond on March 23, 1775. The familiar wording was published by William Wirt in 1817 from recollection.",
      didYouKnow: "There is no contemporary transcript. This card stays unverified.",
      takeaway: "Say the decision you have already made, in one sentence, to one person.",
    },
    related: ["tr-arena", "douglass-struggle"],
    speech: {
      durationSec: 420,
      watchUrl: "https://en.wikisource.org/wiki/Give_me_liberty,_or_give_me_death!",
      rightsStatus: "unknown",
      rightsNotes: "TODO: no contemporary transcript. Do not approve.",
    },
  },
  {
    id: "emerson-trust",
    type: "quote",
    text: "Trust thyself: every heart vibrates to that iron string.",
    authorId: "ralph-waldo-emerson",
    field: "arts",
    moods: ["startingOver", "needFocus", "feelingStuck"],
    verified: false,
    source: { title: "Self-Reliance", year: 1841, url: "https://en.wikisource.org/wiki/Self-Reliance", sourceType: "primary" },
    deeper: {
      context: "From Self-Reliance, Essays: First Series, 1841.",
      didYouKnow: "It follows his line that imitation is a kind of suicide.",
      takeaway: "Make one decision today without asking anyone else first.",
    },
    related: ["emerson-consistency", "shakespeare-true"],
  },
  {
    id: "emerson-consistency",
    type: "quote",
    text: "A foolish consistency is the hobgoblin of little minds, adored by little statesmen and philosophers and divines.",
    authorId: "ralph-waldo-emerson",
    field: "arts",
    moods: ["feelingStuck", "needFocus"],
    verified: false,
    source: { title: "Self-Reliance", year: 1841, url: "https://en.wikisource.org/wiki/Self-Reliance", sourceType: "primary" },
    deeper: {
      context: "From the same 1841 essay, defending the right to change your mind in public.",
      didYouKnow: "The next sentence says a great soul has nothing to do with consistency. He means a foolish consistency.",
      takeaway: "If new information changed your view, say the new view plainly.",
    },
    related: ["emerson-trust", "whitman-multitudes"],
  },
  {
    id: "thoreau-dreams",
    type: "quote",
    text: "If one advances confidently in the direction of his dreams, and endeavors to live the life which he has imagined, he will meet with a success unexpected in common hours.",
    authorId: "henry-david-thoreau",
    field: "resilience",
    moods: ["startingOver", "feelingStuck"],
    verified: false,
    source: { title: "Walden; or, Life in the Woods", year: 1854, url: "https://en.wikisource.org/wiki/Walden", sourceType: "primary" },
    deeper: {
      context: "From the conclusion of Walden, 1854.",
      didYouKnow: "The line is from the book’s last chapter, not the journals.",
      takeaway: "Take one step today that belongs to the life you keep describing to yourself.",
    },
    related: ["emerson-trust", "tr-arena"],
  },
  {
    id: "shakespeare-true",
    type: "quote",
    text: "This above all: to thine own self be true, And it must follow, as the night the day, Thou canst not then be false to any man.",
    authorId: "william-shakespeare",
    field: "arts",
    moods: ["needFocus", "startingOver"],
    verified: false,
    source: { title: "Hamlet, Act I, Scene III", url: "https://en.wikisource.org/wiki/Hamlet", sourceType: "primary" },
    deeper: {
      context: "Polonius says this to Laertes. The play does not treat Polonius as a simple hero.",
      didYouKnow: "In the scene it is one item in a longer list of advice.",
      takeaway: "Before you agree to something today, check whether it matches what you actually think.",
    },
    related: ["emerson-trust", "whitman-multitudes"],
  },
  {
    id: "whitman-multitudes",
    type: "quote",
    text: "Do I contradict myself? Very well then I contradict myself, (I am large, I contain multitudes.)",
    authorId: "walt-whitman",
    field: "arts",
    moods: ["feelingStuck", "badDay"],
    verified: false,
    source: {
      title: "Song of Myself, Leaves of Grass (deathbed edition)",
      year: 1892,
      url: "https://en.wikisource.org/wiki/Song_of_Myself",
      sourceType: "primary",
    },
    deeper: {
      context: "From Song of Myself in the 1892 deathbed edition of Leaves of Grass.",
      didYouKnow: "The 1855 version is punctuated differently.",
      takeaway: "Hold two true things at once today without forcing them into a neat slogan.",
    },
    related: ["emerson-consistency", "shakespeare-true"],
  },
  {
    id: "newton-giants",
    type: "quote",
    text: "If I have seen further it is by standing on the shoulders of Giants.",
    authorId: "isaac-newton",
    field: "science",
    moods: ["examStress", "needFocus"],
    verified: false,
    source: { title: "Letter to Robert Hooke, 5 February 1675/6", sourceType: "primary" },
    deeper: {
      context: "Newton wrote this to Robert Hooke about his optics. The card uses the modernized reading.",
      didYouKnow: "The line is from a letter, not the Principia. TODO: add a non-wiki URL for the letter.",
      takeaway: "Before you start, find the one earlier piece of work your task depends on.",
    },
    related: ["emerson-consistency", "thoreau-dreams"],
  },
  {
    id: "placeholder-13",
    type: "quote",
    text: "Placeholder quote 13",
    authorId: "placeholder",
    field: "sports",
    moods: ["preWorkout"],
    verified: false,
    source: { title: "Placeholder source — not a real work", sourceType: "secondary" },
    deeper: {
      context: "Placeholder context. This card is not a real quotation.",
      didYouKnow: "Placeholder. No historical claim is being made here.",
      takeaway: "Replace this entry before shipping.",
    },
    related: ["tr-arena"],
  },
  {
    id: "placeholder-14",
    type: "quote",
    text: "Placeholder quote 14",
    authorId: "placeholder",
    field: "business",
    moods: ["needFocus", "examStress"],
    verified: false,
    source: { title: "Placeholder source — not a real work", sourceType: "secondary" },
    deeper: {
      context: "Placeholder context. This card is not a real quotation.",
      didYouKnow: "Placeholder. No historical claim is being made here.",
      takeaway: "Replace this entry before shipping.",
    },
    related: ["newton-giants"],
  },
  {
    id: "placeholder-15",
    type: "quote",
    text: "Placeholder quote 15",
    authorId: "placeholder",
    field: "sports",
    moods: ["badDay", "preWorkout"],
    verified: false,
    source: { title: "Placeholder source — not a real work", sourceType: "secondary" },
    deeper: {
      context: "Placeholder context. This card is not a real quotation.",
      didYouKnow: "Placeholder. No historical claim is being made here.",
      takeaway: "Replace this entry before shipping.",
    },
    related: ["fdr-fear"],
  },
];

async function main() {
  const db = getFirestore();
  for (const [id, name, role, born, died, wikidataId, wikiquoteTitle] of authors) {
    await db.collection("authors").doc(id).set(
      {
        name,
        slug: id,
        role,
        bornYear: born,
        diedYear: died,
        isLiving: false,
        livingPhotoAllowed: false,
        speakerType: "person",
        bioShort: role,
        wikipediaTitle: wikidataId ? name : "",
        wikidataId,
        wikiquoteTitle,
        image: null,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  for (const [id, note] of watchlist) {
    await db.collection("misattributionWatchlist").doc(id).set({ note });
  }
  await db.collection("config").doc("flags").set(
    { charactersEnabled: false, livingFiguresEnabled: true },
    { merge: true },
  );
  for (const item of items) {
    const ref = db.collection("items").doc(item.id);
    await ref.set(
      {
        type: item.type,
        text: item.text,
        authorId: item.authorId,
        field: item.field,
        moods: item.moods,
        language: "en",
        status: "draft",
        verified: false,
        discoveredVia: "manual",
        wordCount: wordCount(item.text),
        warnings: item.id.startsWith("placeholder") ? ["not_a_real_work"] : item.id.startsWith("henry") ? ["needs_contemporary_source"] : [],
        rand: Math.random(),
        related: item.related,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    await ref.collection("sources").doc("main").set({
      title: item.source.title,
      year: item.source.year ?? null,
      url: item.source.url ?? "",
      pageOrTimestamp: "",
      sourceType: item.source.sourceType,
      confidence: "probable",
    });
    await ref.collection("deeper").doc("main").set({
      ...item.deeper,
      generatedBy: "human",
      aiModel: null,
      humanReviewed: true,
      reviewedBy: "seed",
    });
    if (item.speech) {
      await ref.collection("speech").doc("main").set({
        durationSec: item.speech.durationSec,
        watchUrl: item.speech.watchUrl,
        embedAllowed: false,
        rightsStatus: item.speech.rightsStatus,
        rightsNotes: item.speech.rightsNotes,
      });
    }
  }
  console.log(`Seeded ${items.length} draft items. Nothing was published.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
