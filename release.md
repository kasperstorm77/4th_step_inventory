# Release notes

Newest-first. The **top** block is the one shipped on the next store upload:
`scripts/upload-aab-to-play.sh` and `scripts/upload-ipa-to-testflight.sh` lift
its `<en-GB>` and `<da-DK>` bodies verbatim into Google Play / TestFlight. Keep
each locale ≤ 500 characters (Play's limit). The version on the `X.Y.Z - DATE:`
line must match `pubspec.yaml`.

2.3.8 - 2026-08-26:
<en-GB>
- Restoring a backup is now all-or-nothing. If a restore cannot finish, the
  app automatically puts every record back exactly as it was, so a failed
  restore never leaves your data half-replaced.
- The same protection covers a manual import from Emotional Sobriety.
- Backups remain compatible with Emotional Sobriety.
</en-GB>
<da-DK>
- Gendannelse af en sikkerhedskopi er nu alt eller intet. Kan gendannelsen
  ikke fuldføres, lægger appen automatisk alle poster tilbage præcis som de
  var, så en mislykket gendannelse aldrig efterlader dine data halvt udskiftet.
- Samme beskyttelse gælder en manuel import fra Emotional Sobriety.
- Sikkerhedskopier er fortsat kompatible med Emotional Sobriety.
</da-DK>

2.3.7 - 2026-08-09:
<en-GB>
- Backups now record which app created them, preventing a backup from another
  app from being restored as a complete 12 Steps App backup.
- A confirmed manual import from Emotional Sobriety replaces only shared
  recovery data and keeps data that belongs only to 12 Steps App.
</en-GB>
<da-DK>
- Sikkerhedskopier registrerer nu, hvilken app der oprettede dem, så en kopi fra
  en anden app ikke gendannes som en fuld sikkerhedskopi fra 12 Steps App.
- En bekræftet manuel import fra Emotional Sobriety erstatter kun delte
  recoverydata og bevarer data, der kun findes i 12 Steps App.
</da-DK>

2.3.6 - 2026-08-09:
<en-GB>
- "Just for Today" is now a direct choice when adding or editing a morning
  ritual item. Choose it once and the ritual shows one of the ten readings each
  morning.
- Backups remain compatible with Emotional Sobriety.
</en-GB>
<da-DK>
- "Just for Today" kan nu vælges direkte, når du tilføjer eller retter et
  element i morgenritualet. Vælg det én gang, så viser ritualet én af de ti
  læsninger hver morgen.
- Sikkerhedskopier er fortsat kompatible med Emotional Sobriety.
</da-DK>

2.3.5 - 2026-08-07:
<en-GB>
- The in-app help now describes what each tool actually does: the four inventory
  categories and how the field labels follow them, the fear behind a barrier and
  how the paper flips, the Just for Today reading, the per-item alarm sound, and
  which entries stay editable.
- Reminders have a help page for the first time, and the 8th Step help now
  explains the Yes / No / Maybe columns correctly.
- Clearer, plainer wording throughout, in both languages.
</en-GB>
<da-DK>
- Hjælpen i appen beskriver nu, hvad hvert værktøj faktisk gør: de fire
  kategorier og hvordan feltnavnene følger dem, frygten bag en barriere og
  hvordan papiret vendes, "Just for Today"-læsningen, alarmlyden per element, og
  hvilke indtastninger der kan rettes.
- Påmindelser har for første gang en hjælpeside, og hjælpen til 8. trin
  forklarer nu Ja / Nej / Måske-kolonnerne korrekt.
- Klarere og enklere formuleringer overalt, på begge sprog.
</da-DK>

2.3.4 - 2026-08-07:
<en-GB>
- Fixed: syncing could stop with a sign-in error and never recover on its own,
  so work done on your phone never reached your backup. The app now renews the
  sign-in itself and keeps syncing.
- Fixed: something saved just before you close the app could fail to upload. It
  is now sent as you leave, and anything still missing is uploaded the next time
  you open the app.
</en-GB>
<da-DK>
- Rettet: synkronisering kunne stoppe med en login-fejl og aldrig komme sig selv,
  så det du lavede på telefonen aldrig nåede din sikkerhedskopi. Appen fornyer
  nu login selv og synkroniserer videre.
- Rettet: noget gemt lige før du lukker appen kunne mislykkes i at blive sendt.
  Det sendes nu når du forlader appen, og resten sendes næste gang du åbner den.
</da-DK>

2.3.3 - 2026-08-07:
<en-GB>
- Danish is properly Danish now: dates, month names and weekdays follow the
  language you pick, and the calendar's Week/Month button is translated.
- The alarm sound you choose for a morning timer is now the one that plays.
- Reminders finally have a help page, and the 8th Step help explains the
  Yes / No / Maybe columns correctly.
- Updated for Android 15's edge-to-edge screens, so nothing sits under the
  navigation bar.
- Fixed: a restore could report failure after it had already worked.
</en-GB>
<da-DK>
- Dansk er nu rigtigt dansk: datoer, månedsnavne og ugedage følger det sprog,
  du vælger, og kalenderens Uge/Måned-knap er oversat.
- Den alarmlyd, du vælger til en morgentimer, er nu også den, der spiller.
- Påmindelser har endelig en hjælpeside, og hjælpen til 8. trin forklarer
  Ja / Nej / Måske-kolonnerne korrekt.
- Tilpasset Android 15's kant-til-kant-skærme, så intet ligger under
  navigationslinjen.
- Rettet: en gendannelse kunne melde fejl, selvom den var lykkedes.
</da-DK>

2.3.2 - 2026-08-07:
<en-GB>
- Now requires iOS 15 or later, matching Apple's current minimum.
- No other changes.
</en-GB>
<da-DK>
- Kræver nu iOS 15 eller nyere, i tråd med Apples nuværende minimum.
- Ingen andre ændringer.
</da-DK>

2.3.1 - 2026-08-06:
<en-GB>
- New "Just for Today" reading: turn it on for a prayer item and the app draws
  one of ten readings each morning. It stays the same if you pause or go back,
  and your history keeps what you read.
- You can now import a backup from the Emotional Sobriety app: I Am
  definitions, 4th Step entries, pairs and your morning ritual. Everything
  else on this device is kept.
- Fixed: deleting a morning ritual item could make your backup unreadable by
  the other app. Tidier wording in places.
</en-GB>
<da-DK>
- Ny "Kun for i dag"-læsning: slå den til på en bøn, så trækker appen én af ti
  læsninger, når dagens ritual begynder. Den er den samme, hvis du holder
  pause eller går tilbage, og historikken husker den.
- Du kan nu importere en sikkerhedskopi fra Emotional Sobriety: Jeg Er,
  4. trins poster, par og dit morgenritual. Alt andet bevares.
- Rettet: at slette et element i morgenritualet kunne gøre din sikkerhedskopi
  ulæselig for den anden app. Pænere formuleringer enkelte steder.
</da-DK>

2.3.0 - 2026-08-06:
<en-GB>
- New "Just for Today" reading: turn it on for a prayer item and the app draws
  one of ten readings when the day's ritual begins. It stays the same if you
  pause or go back, and your history keeps what you read.
- You can now import a backup from the Emotional Sobriety app: I Am
  definitions, 4th Step entries, Barrier/Power pairs and your morning ritual.
  Everything else on this device is kept.
- Fixed: deleting a morning ritual item could make your backup unreadable by
  the other app.
</en-GB>
<da-DK>
- Ny "Kun for i dag"-læsning: slå den til på en bøn, så trækker appen én af ti
  læsninger, når dagens ritual begynder. Den er den samme, hvis du holder
  pause eller går tilbage, og historikken husker den.
- Du kan nu importere en sikkerhedskopi fra Emotional Sobriety: Jeg Er,
  4. trins poster, Barriere/Kraft-par og dit morgenritual. Alt andet på
  enheden bevares.
- Rettet: at slette et element i morgenritualet kunne gøre din sikkerhedskopi
  ulæselig for den anden app.
</da-DK>

2.2.13 - 2026-06-28:
<en-GB>
- The morning ritual alarm now plays to the end instead of cutting off early.
- On desktop, the app no longer fills your Documents folder with backup files.
</en-GB>
<da-DK>
- Morgenritualets alarm spiller nu helt færdig i stedet for at blive afbrudt.
- På computer fylder appen ikke længere din Dokumenter-mappe med sikkerhedskopier.
</da-DK>
