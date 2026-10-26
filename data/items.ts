export type Field =
  | 'sports'
  | 'business'
  | 'science'
  | 'arts'
  | 'leadership'
  | 'resilience'
  | 'other';

export type Item = {
  id: string;
  type: 'quote' | 'speech';
  text: string;
  author: string;
  authorRole: string;
  field: Field;
  moods: string[];
  source: { title: string; year?: number; url?: string };
  verified: boolean;
  deeper: {
    context: string;
    didYouKnow: string;
    takeaway: string;
    related: string[];
  };
  speech?: { durationSec: number; watchUrl: string };
  // PHASE 2: populate imageUrl from a licensed portrait store. Do not fetch images on the device.
  imageUrl?: string;
  imageCredit?: { artist: string; license: string; sourceUrl: string };
};

/**
 * Local seed catalog.
 * Speech `durationSec` values are approximate delivery lengths for the badge,
 * not timestamps from a recording.
 *
 * // PHASE 2: replace this module with a fetch of the verified catalog.
 */
export const ITEMS: Item[] = [
  {
    id: 'tr-arena',
    type: 'speech',
    text: 'It is not the critic who counts; not the man who points out how the strong man stumbles, or where the doer of deeds could have done them better. The credit belongs to the man who is actually in the arena, whose face is marred by dust and sweat and blood…',
    author: 'Theodore Roosevelt',
    authorRole: '26th President of the United States',
    field: 'leadership',
    moods: ['starting-over', 'feeling-stuck', 'pre-workout'],
    source: {
      title: 'Citizenship in a Republic',
      year: 1910,
      url: 'https://en.wikisource.org/wiki/Citizenship_in_a_Republic',
    },
    verified: true,
    deeper: {
      context:
        'Roosevelt gave this lecture at the Sorbonne in Paris on April 23, 1910, the year after he left the presidency. He was talking about what a citizen owes a republic. This passage says the person who tries and fails still counts for more than the person who only points out the failure.',
      didYouKnow:
        'The lecture is titled “Citizenship in a Republic.” This section was not a separate speech. It later picked up the nickname “The Man in the Arena.” The badge length is an estimate for the full lecture.',
      takeaway: 'Do one concrete thing today that you have been postponing because someone might judge it.',
      related: ['douglass-struggle', 'thoreau-dreams', 'henry-liberty'],
    },
    speech: {
      durationSec: 2700,
      watchUrl: 'https://en.wikisource.org/wiki/Citizenship_in_a_Republic',
    },
  },
  {
    id: 'lincoln-gettysburg',
    type: 'speech',
    text: 'The world will little note, nor long remember what we say here; while it can never forget what they did here.',
    author: 'Abraham Lincoln',
    authorRole: '16th President of the United States',
    field: 'leadership',
    moods: ['feeling-stuck', 'need-focus'],
    source: {
      title: 'Gettysburg Address (Nicolay draft)',
      year: 1863,
      url: 'https://en.wikisource.org/wiki/Gettysburg_Address_(Nicolay_draft)',
    },
    verified: true,
    deeper: {
      context:
        'On November 19, 1863, Lincoln spoke at the dedication of the Soldiers’ National Cemetery in Gettysburg, after a much longer oration by Edward Everett. The sentence here is from the draft kept by his secretary, John Nicolay.',
      didYouKnow:
        'Lincoln spoke for about two minutes. The Nicolay copy is one of the earliest surviving texts of the address, and its wording differs slightly from the later Bliss copy.',
      takeaway: 'Let someone else’s effort be the reason you finish a task you were about to drop.',
      related: ['lincoln-charity', 'douglass-struggle'],
    },
    speech: {
      durationSec: 120,
      watchUrl: 'https://en.wikisource.org/wiki/Gettysburg_Address_(Nicolay_draft)',
    },
  },
  {
    id: 'lincoln-charity',
    type: 'speech',
    text: 'With malice toward none; with charity for all; with firmness in the right, as God gives us to see the right, let us strive on to finish the work we are in…',
    author: 'Abraham Lincoln',
    authorRole: '16th President of the United States',
    field: 'leadership',
    moods: ['bad-day', 'starting-over'],
    source: {
      title: 'Second Inaugural Address',
      year: 1865,
      url: 'https://en.wikisource.org/wiki/Abraham_Lincoln%27s_Second_Inaugural_Address',
    },
    verified: true,
    deeper: {
      context:
        'Lincoln delivered his second inaugural on March 4, 1865, with the Civil War near its end. Instead of celebrating, he asked the country to finish the work without hatred.',
      didYouKnow:
        'The sentence continues past this excerpt, on to binding up the nation’s wounds and caring for those who fought and for their families. The ellipsis marks that cut.',
      takeaway: 'Finish the hard conversation without trying to win it.',
      related: ['lincoln-gettysburg', 'fdr-fear'],
    },
    speech: {
      durationSec: 420,
      watchUrl: 'https://en.wikisource.org/wiki/Abraham_Lincoln%27s_Second_Inaugural_Address',
    },
  },
  {
    id: 'fdr-fear',
    type: 'speech',
    text: 'So, first of all, let me assert my firm belief that the only thing we have to fear is fear itself—nameless, unreasoning, unjustified terror which paralyzes needed efforts to convert retreat into advance.',
    author: 'Franklin D. Roosevelt',
    authorRole: '32nd President of the United States',
    field: 'resilience',
    moods: ['bad-day', 'exam-stress', 'starting-over'],
    source: {
      title: 'First Inaugural Address',
      year: 1933,
      url: 'https://en.wikisource.org/wiki/Franklin_D._Roosevelt%27s_First_Inaugural_Address',
    },
    verified: true,
    deeper: {
      context:
        'Roosevelt spoke from the East Portico of the Capitol on March 4, 1933. Banks were failing and the country was deep in the Depression. He argued that panic itself was making the crisis worse.',
      didYouKnow:
        'He wrote the address himself. The “fear itself” line comes in the opening, before he turns to policy. The badge length is an estimate for the full address, often described as about twenty minutes.',
      takeaway: 'When you feel frozen, write down the next small action and do only that.',
      related: ['thoreau-dreams', 'emerson-trust'],
    },
    speech: {
      durationSec: 1200,
      watchUrl: 'https://en.wikisource.org/wiki/Franklin_D._Roosevelt%27s_First_Inaugural_Address',
    },
  },
  {
    id: 'douglass-struggle',
    type: 'speech',
    text: 'If there is no struggle there is no progress.',
    author: 'Frederick Douglass',
    authorRole: 'Abolitionist and orator',
    field: 'resilience',
    moods: ['feeling-stuck', 'starting-over', 'exam-stress'],
    source: {
      title: 'West India Emancipation speech, Canandaigua, New York',
      year: 1857,
      url: 'https://blackpast.org/african-american-history/1857-frederick-douglass-if-there-no-struggle-there-no-progress/',
    },
    verified: true,
    deeper: {
      context:
        'On August 3, 1857, Douglass spoke in Canandaigua, New York, at a commemoration of emancipation in the British West Indies. Early in the address he turned to what it costs to win any real freedom.',
      didYouKnow:
        'The sentence sits inside a longer argument. People who want change without conflict, he said, want crops without plowing the ground. The badge length is an estimate for the full address.',
      takeaway: 'Name the hard part of a goal you care about, and do that part first today.',
      related: ['tr-arena', 'lincoln-gettysburg'],
    },
    speech: {
      durationSec: 2400,
      watchUrl:
        'https://blackpast.org/african-american-history/1857-frederick-douglass-if-there-no-struggle-there-no-progress/',
    },
  },
  // TODO: replace in Phase 2
  // The familiar wording comes from William Wirt's 1817 biography, reconstructed
  // from recollection rather than a contemporary transcript.
  {
    id: 'henry-liberty',
    type: 'speech',
    text: 'I know not what course others may take; but as for me, give me liberty, or give me death!',
    author: 'Patrick Henry',
    authorRole: 'Virginia statesman',
    field: 'leadership',
    moods: ['starting-over', 'feeling-stuck'],
    source: {
      title: 'Speech at the Second Virginia Convention (Wirt text)',
      year: 1775,
      url: 'https://en.wikisource.org/wiki/Give_me_liberty,_or_give_me_death!',
    },
    verified: false,
    deeper: {
      context:
        'The traditional setting is St. John’s Church in Richmond on March 23, 1775, during the Second Virginia Convention’s debate over preparing a militia. The wording most people know was published decades later by William Wirt.',
      didYouKnow:
        'There is no contemporary transcript of the speech. Treat this card as unverified until a sourced text is chosen for the catalog. The badge length is only a rough reading time for the Wirt text.',
      takeaway: 'Say the decision you have already made, in one sentence, to one person.',
      related: ['tr-arena', 'douglass-struggle'],
    },
    speech: {
      durationSec: 420,
      watchUrl: 'https://en.wikisource.org/wiki/Give_me_liberty,_or_give_me_death!',
    },
  },
  {
    id: 'emerson-trust',
    type: 'quote',
    text: 'Trust thyself: every heart vibrates to that iron string.',
    author: 'Ralph Waldo Emerson',
    authorRole: 'Essayist',
    field: 'arts',
    moods: ['starting-over', 'need-focus', 'feeling-stuck'],
    source: {
      title: 'Self-Reliance',
      year: 1841,
      url: 'https://en.wikisource.org/wiki/Self-Reliance',
    },
    verified: true,
    deeper: {
      context:
        'This line is from the essay “Self-Reliance,” published in Essays: First Series in 1841. Emerson is arguing against living by imitation.',
      didYouKnow:
        'It comes just after he writes that imitation is a kind of suicide, and that a person only learns what they can do by trying.',
      takeaway: 'Make one decision today without asking anyone else first.',
      related: ['emerson-consistency', 'shakespeare-true'],
    },
  },
  {
    id: 'emerson-consistency',
    type: 'quote',
    text: 'A foolish consistency is the hobgoblin of little minds, adored by little statesmen and philosophers and divines.',
    author: 'Ralph Waldo Emerson',
    authorRole: 'Essayist',
    field: 'arts',
    moods: ['feeling-stuck', 'need-focus'],
    source: {
      title: 'Self-Reliance',
      year: 1841,
      url: 'https://en.wikisource.org/wiki/Self-Reliance',
    },
    verified: true,
    deeper: {
      context:
        'From the same 1841 essay. Emerson is defending the right to change your mind in public when you have learned something new.',
      didYouKnow:
        'The next sentence says that with consistency a great soul has simply nothing to do. He is attacking a foolish consistency, not every kind of steadiness.',
      takeaway: 'If new information changed your view, say the new view plainly instead of defending the old one.',
      related: ['emerson-trust', 'whitman-multitudes'],
    },
  },
  {
    id: 'thoreau-dreams',
    type: 'quote',
    text: 'If one advances confidently in the direction of his dreams, and endeavors to live the life which he has imagined, he will meet with a success unexpected in common hours.',
    author: 'Henry David Thoreau',
    authorRole: 'Essayist',
    field: 'resilience',
    moods: ['starting-over', 'feeling-stuck'],
    source: {
      title: 'Walden; or, Life in the Woods',
      year: 1854,
      url: 'https://en.wikisource.org/wiki/Walden',
    },
    verified: true,
    deeper: {
      context:
        'This sentence is from the conclusion of Walden, published in 1854, after Thoreau’s two years at Walden Pond. It is his summary of what the experiment taught him.',
      didYouKnow:
        'The line is from the book’s last chapter, not from the journals. The paragraph goes on to say that new and more liberal laws will begin to establish themselves around such a person.',
      takeaway: 'Take one step today that belongs to the life you keep describing to yourself.',
      related: ['emerson-trust', 'tr-arena'],
    },
  },
  {
    id: 'shakespeare-true',
    type: 'quote',
    text: 'This above all: to thine own self be true, And it must follow, as the night the day, Thou canst not then be false to any man.',
    author: 'William Shakespeare',
    authorRole: 'Playwright',
    field: 'arts',
    moods: ['need-focus', 'starting-over'],
    source: {
      title: 'Hamlet, Act I, Scene III',
      url: 'https://en.wikisource.org/wiki/Hamlet',
    },
    verified: true,
    deeper: {
      context:
        'Polonius says this to his son Laertes, who is about to leave for France. It is a father’s send-off, and the play does not treat Polonius as a simple hero.',
      didYouKnow:
        'The line is often quoted alone. In the scene it is one piece of a longer list of practical advice, between warnings about quarrels and about clothes.',
      takeaway: 'Before you agree to something today, check whether it matches what you actually think.',
      related: ['emerson-trust', 'whitman-multitudes'],
    },
  },
  {
    id: 'whitman-multitudes',
    type: 'quote',
    text: 'Do I contradict myself? Very well then I contradict myself, (I am large, I contain multitudes.)',
    author: 'Walt Whitman',
    authorRole: 'Poet',
    field: 'arts',
    moods: ['feeling-stuck', 'bad-day'],
    source: {
      title: 'Song of Myself, Leaves of Grass (deathbed edition)',
      year: 1892,
      url: 'https://en.wikisource.org/wiki/Song_of_Myself',
    },
    verified: true,
    deeper: {
      context:
        'From “Song of Myself.” Whitman asks whether he contradicts himself, then refuses to apologize for it. This wording is the one in the final edition of Leaves of Grass that he prepared.',
      didYouKnow:
        'He revised Leaves of Grass across decades. The 1855 version of the poem is punctuated differently. This card uses the 1892 deathbed edition.',
      takeaway: 'Hold two true things at once today without forcing them into a neat slogan.',
      related: ['emerson-consistency', 'shakespeare-true'],
    },
  },
  {
    id: 'newton-giants',
    type: 'quote',
    text: 'If I have seen further it is by standing on the shoulders of Giants.',
    author: 'Isaac Newton',
    authorRole: 'Natural philosopher',
    field: 'science',
    moods: ['exam-stress', 'need-focus'],
    source: {
      title: 'Letter to Robert Hooke, 5 February 1675/6',
    },
    verified: true,
    deeper: {
      context:
        'Newton wrote this to Robert Hooke about his work in optics, and about how that work depended on people who came before him. The surviving spelling is “ye sholders of Giants.” The card uses the standard modernized reading of the same words.',
      didYouKnow:
        'The line is from a letter, not from the Principia. The date is often written 1675/6 because England had not yet moved the new year to January 1.',
      takeaway: 'Before you start, find the one earlier piece of work your task depends on.',
      related: ['emerson-consistency', 'thoreau-dreams'],
    },
  },
  // TODO: replace in Phase 2
  {
    id: 'placeholder-13',
    type: 'quote',
    text: 'Placeholder quote 13',
    author: 'Placeholder',
    authorRole: 'Not a real person',
    field: 'sports',
    moods: ['pre-workout'],
    source: { title: 'Placeholder source — not a real work' },
    verified: false,
    deeper: {
      context: 'Placeholder context. This card is not a real quotation.',
      didYouKnow: 'Placeholder. No historical claim is being made here.',
      takeaway: 'Replace this entry before shipping.',
      related: ['tr-arena'],
    },
  },
  // TODO: replace in Phase 2
  {
    id: 'placeholder-14',
    type: 'quote',
    text: 'Placeholder quote 14',
    author: 'Placeholder',
    authorRole: 'Not a real person',
    field: 'business',
    moods: ['need-focus', 'exam-stress'],
    source: { title: 'Placeholder source — not a real work' },
    verified: false,
    deeper: {
      context: 'Placeholder context. This card is not a real quotation.',
      didYouKnow: 'Placeholder. No historical claim is being made here.',
      takeaway: 'Replace this entry before shipping.',
      related: ['newton-giants'],
    },
  },
  // TODO: replace in Phase 2
  {
    id: 'placeholder-15',
    type: 'quote',
    text: 'Placeholder quote 15',
    author: 'Placeholder',
    authorRole: 'Not a real person',
    field: 'sports',
    moods: ['bad-day', 'pre-workout'],
    source: { title: 'Placeholder source — not a real work' },
    verified: false,
    deeper: {
      context: 'Placeholder context. This card is not a real quotation.',
      didYouKnow: 'Placeholder. No historical claim is being made here.',
      takeaway: 'Replace this entry before shipping.',
      related: ['fdr-fear'],
    },
  },
];

export function itemById(id: string) {
  return ITEMS.find((item) => item.id === id);
}
