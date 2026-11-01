# Release gate: electrician-ship 876eca8eefab

Verdict: **BLOCK** (2026-11-01T18:18:44+00:00)

Every finding blocks except legacy backlog. `qa-gate fix <repo>` fixes them. Motion candidates need a judgement in the ledger: `qa-gate ledger <repo> accept` for an intended change, or `add` a P1 when it is a real glitch.

## Blocking (18)

| Sev | Oracle | Persona | Journey / checkpoint | Detail | Fingerprint |
|---|---|---|---|---|---|
| P1 | overlap | duo | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-5 | text "5 of 5" overlaps "Standard method: interlocked heat at 12 kW and cooling at 5 kW cannot run together. Which load is counted?" by 48% | `overlap|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-5|# of # / standard method: interlocked heat at # kw and cooli` |
| P2 | a11y-hit-region | duo,newcomer,reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-1 | Hit area is too small: "Question 1 of 5" | `a11y-hit-region|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-1|question # of #` |
| P2 | a11y-hit-region | duo,newcomer,reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-1 | Hit area is too small: "Report a possible issue" | `a11y-hit-region|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-1|report a possible issue` |
| P2 | a11y-contrast | newcomer,reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-1 | Contrast nearly passed (measured 4.0:1): "WHAT HAPPENED" | `a11y-contrast|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-1|what happened` |
| P2 | a11y-hit-region | duo,newcomer,reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-2 | Hit area is too small: "Question 2 of 5" | `a11y-hit-region|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-2|question # of #` |
| P2 | a11y-hit-region | duo,newcomer,reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-2 | Hit area is too small: "Report a possible issue" | `a11y-hit-region|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-2|report a possible issue` |
| P2 | a11y-hit-region | duo,newcomer,reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-3 | Hit area is too small: "Question 3 of 5" | `a11y-hit-region|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-3|question # of #` |
| P2 | a11y-hit-region | duo,newcomer,reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-3 | Hit area is too small: "Report a possible issue" | `a11y-hit-region|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-3|report a possible issue` |
| P2 | a11y-hit-region | duo,newcomer,reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-4 | Hit area is too small: "Question 4 of 5" | `a11y-hit-region|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-4|question # of #` |
| P2 | a11y-hit-region | duo,newcomer,reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-4 | Hit area is too small: "Report a possible issue" | `a11y-hit-region|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-4|report a possible issue` |
| P2 | a11y-hit-region | duo,newcomer,reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-5 | Hit area is too small: "Question 5 of 5" | `a11y-hit-region|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-5|question # of #` |
| P2 | a11y-hit-region | duo,newcomer,reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-5 | Hit area is too small: "Report a possible issue" | `a11y-hit-region|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-5|report a possible issue` |
| P2 | truncated | accessibility | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / code-minute | button drawn as "Start Today's Ch..." but reads "Start Today's Challenge" (AX3 text only) | `truncated|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|code-minute|start today's challenge` |
| P2 | overlap | accessibility | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-1 | text "1 of 5" overlaps "Report 123.76 A as 123.8 A to the nearest 0.1 A. Compare actual loads against the unrounded allowable ampacity." by 59% (AX3 text only) | `overlap|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-1|# of # / report # a as # a to the nearest # a. compare actua` |
| P3 | a11y-audit | accessibility | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-2 | audit could not run: Audit failed to complete in time | `a11y-audit|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-2|` |
| P2 | overlap | accessibility | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-3 | text "Code Minute" overlaps "Tap rules are an overcurrent-protection concept: they describe when a conductor may be smaller than the device ahead of it. They sit in Article 240, not with the conductor | `overlap|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-3|code minute / tap rules are an overcurrent-protection concep` |
| P2 | overlap | accessibility | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-3 | text "3 of 5" overlaps "Tap rules are an overcurrent-protection concept: they describe when a conductor may be smaller than the device ahead of it. They sit in Article 240, not with the conductors." b | `overlap|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-3|# of # / tap rules are an overcurrent-protection concept: th` |
| P2 | overlap | accessibility | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / answered-5 | text "5 of 5" overlaps "Loads that cannot run at the same time are noncoincident, and only the largest of them is counted. Heat and air conditioning are the pair every exam uses. Adding them is the mi | `overlap|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|answered-5|# of # / loads that cannot run at the same time are noncoinc` |

## Needs a judgement (2)

| Sev | Oracle | Persona | Journey / checkpoint | Detail | Fingerprint |
|---|---|---|---|---|---|
| P1 | motion-jump | accessibility | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / code-minute | jump candidate at 199.19s of journeys.mp4 (score 0.127) ([sheet](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/accessibility/journeys.event-10.png)) | `motion-jump|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|code-minute|` |
| P1 | motion-jump | accessibility | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch / code-minute-saved | jump candidate at 276.69s of journeys.mp4 (score 0.125) ([sheet](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/accessibility/journeys.event-11.png)) | `motion-jump|testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch|code-minute-saved|` |

## Legacy backlog, warns until fixed (17)

| Sev | Oracle | Persona | Journey / checkpoint | Detail | Fingerprint |
|---|---|---|---|---|---|
| P2 | a11y-contrast |  | home(_:in:) / first-home | Contrast failed (measured 4.0:1): "Electrician+" | `a11y-contrast|home(_:in:)|first-home|electrician+` |
| P2 | a11y-contrast |  | home(_:in:) / home-after-background | Contrast failed (measured 4.4:1): "days" | `a11y-contrast|home(_:in:)|home-after-background|days` |
| P2 | a11y-contrast |  | home(_:in:) / home-after-relaunch | Contrast failed (measured 4.4:1): "days" | `a11y-contrast|home(_:in:)|home-after-relaunch|days` |
| P2 | a11y-contrast |  | home(_:in:) / home-after-settings | Contrast failed (measured 4.4:1): "days" | `a11y-contrast|home(_:in:)|home-after-settings|days` |
| P2 | a11y-contrast |  | home(_:in:) / home-after-tools | Contrast failed (measured 4.4:1): "days" | `a11y-contrast|home(_:in:)|home-after-tools|days` |
| P2 | a11y-contrast |  | home(_:in:) / home | Contrast failed (measured 4.4:1): "days" | `a11y-contrast|home(_:in:)|home|days` |
| P2 | a11y-hit-region |  | checkpoint(_:button:in:) / exam-date | Hit area is too small: "Skip" | `a11y-hit-region|checkpoint(_:button:in:)|exam-date|skip` |
| P2 | a11y-hit-region |  | checkpoint(_:button:in:) / focus | Hit area is too small: "Skip" | `a11y-hit-region|checkpoint(_:button:in:)|focus|skip` |
| P2 | a11y-hit-region |  | checkpoint(_:button:in:) / jurisdiction | Hit area is too small: "Choose a different state" | `a11y-hit-region|checkpoint(_:button:in:)|jurisdiction|choose a different state` |
| P2 | a11y-hit-region |  | checkpoint(_:button:in:) / reminder | Hit area is too small: "Skip" | `a11y-hit-region|checkpoint(_:button:in:)|reminder|skip` |
| P2 | a11y-hit-region |  | test1FirstRunToTrialAndHome / onboarding-trial | Hit area is too small: "Get Started" | `a11y-hit-region|test1FirstRunToTrialAndHome|onboarding-trial|get started` |
| P2 | a11y-hit-region |  | test1FirstRunToTrialAndHome / onboarding-trial | Hit area is too small: "Privacy" | `a11y-hit-region|test1FirstRunToTrialAndHome|onboarding-trial|privacy` |
| P2 | a11y-hit-region |  | test1FirstRunToTrialAndHome / onboarding-trial | Hit area is too small: "Restore" | `a11y-hit-region|test1FirstRunToTrialAndHome|onboarding-trial|restore` |
| P2 | a11y-hit-region |  | test1FirstRunToTrialAndHome / onboarding-trial | Hit area is too small: "Terms" | `a11y-hit-region|test1FirstRunToTrialAndHome|onboarding-trial|terms` |
| P2 | overlap |  | checkpoint(_:button:in:) / focus | button "Code Basics, How the book works before what it says" overlaps "Continue" by 42% (AX3 text only) | `overlap|checkpoint(_:button:in:)|focus|code basics, how the book works before what it says / contin` |
| P2 | overlap |  | test1FirstRunToTrialAndHome / onboarding-trial | text "The free rooms hold 73 questions. At 15 a day that is about 5 days of practice, and then you are re-reading answers you remember." overlaps "7 days free, then $9.99/month. Auto-renews until canc | `overlap|test1FirstRunToTrialAndHome|onboarding-trial|# days free, then $#/month. auto-renews until canceled. / th` |
| P2 | reduce-motion-ignored |  | all / all | with Reduce Motion on the journeys still moved for 26.7s against 33.2s without it (80%); check which animations ignore it | `reduce-motion-ignored|all|all|` |

## Journeys

| Persona | Journey | Result | Seconds |
|---|---|---|---|
| newcomer | test1FirstRunToTrialAndHome | Passed | 114.23117005825043 |
| newcomer | test2HomeToolsUpgradeSettingsAndReturn | Passed | 72.6548399925232 |
| newcomer | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch | Passed | 107.07533299922943 |
| accessibility | test1FirstRunToTrialAndHome | Passed | 113.39530098438263 |
| accessibility | test2HomeToolsUpgradeSettingsAndReturn | Passed | 65.75023400783539 |
| accessibility | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch | Passed | 124.03190004825592 |
| reduce-motion | test1FirstRunToTrialAndHome | Passed | 110.03633105754852 |
| reduce-motion | test2HomeToolsUpgradeSettingsAndReturn | Passed | 75.24444901943207 |
| reduce-motion | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch | Passed | 111.7141250371933 |
| duo | test1FirstRunToTrialAndHome | Passed | 110.17238199710846 |
| duo | test2HomeToolsUpgradeSettingsAndReturn | Passed | 74.97694098949432 |
| duo | testCoreLoopCodeMinuteAnswersSavesAndSurvivesRelaunch | Passed | 118.78333806991577 |

## Motion

| Persona | Motion s | Windows | Candidates | Gaps > 25 ms | 60 fps |
|---|---|---|---|---|---|
| newcomer | 33.219 | 56 | 15 | 123 | True |
| accessibility | 42.665 | 58 | 13 | 133 | True |
| reduce-motion | 26.719 | 56 | 6 | 57 | True |

## Launch entrances to look at

Each launch's frames after the springboard zoom, left to right then down, 4 frames per
row at the recorded rate. A blank stretch, text that reflows, or content that arrives and
pushes the layout is a finding: `qa-gate ledger <repo> add`.

- [entrance-01-test1firstruntotrialandhome.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/newcomer/entrance-01-test1firstruntotrialandhome.png)
- [entrance-15-test2hometoolsupgradesettingsandreturn.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/newcomer/entrance-15-test2hometoolsupgradesettingsandreturn.png)
- [entrance-01-test1firstruntotrialandhome.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/accessibility/entrance-01-test1firstruntotrialandhome.png)
- [entrance-15-test2hometoolsupgradesettingsandreturn.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/accessibility/entrance-15-test2hometoolsupgradesettingsandreturn.png)
- [entrance-23-test2hometoolsupgradesettingsandreturn.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/accessibility/entrance-23-test2hometoolsupgradesettingsandreturn.png)
- [entrance-25-testcoreloopcodeminuteanswerssavesandsurvivesrelaunch.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/accessibility/entrance-25-testcoreloopcodeminuteanswerssavesandsurvivesrelaunch.png)
- [entrance-35-testcoreloopcodeminuteanswerssavesandsurvivesrelaunch.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/accessibility/entrance-35-testcoreloopcodeminuteanswerssavesandsurvivesrelaunch.png)
- [entrance-01-test1firstruntotrialandhome.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/reduce-motion/entrance-01-test1firstruntotrialandhome.png)
- [entrance-15-test2hometoolsupgradesettingsandreturn.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/reduce-motion/entrance-15-test2hometoolsupgradesettingsandreturn.png)
- [entrance-23-test2hometoolsupgradesettingsandreturn.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/reduce-motion/entrance-23-test2hometoolsupgradesettingsandreturn.png)
- [entrance-25-testcoreloopcodeminuteanswerssavesandsurvivesrelaunch.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/reduce-motion/entrance-25-testcoreloopcodeminuteanswerssavesandsurvivesrelaunch.png)
- [entrance-35-testcoreloopcodeminuteanswerssavesandsurvivesrelaunch.png](/Users/jackwallner/electrician-ship/build/qa/876eca8eefab/reduce-motion/entrance-35-testcoreloopcodeminuteanswerssavesandsurvivesrelaunch.png)

Skipped personas: german (app not localized).
