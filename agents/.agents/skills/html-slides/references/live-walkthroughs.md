# Live walkthroughs and exercises

Read this for presentations that use live tools, investigations or historical examples. Keep the base slide workflow for ordinary explanations.

## Set the learning task

Establish what the audience should discover using the material they can actually inspect. For a triage exercise, that might be **what is elevated → which workload is driving it → where to investigate next**. Don't silently expand that into a full root-cause investigation or recovery exercise.

Choose the appropriate treatment:

| Treatment | What the audience gets |
|---|---|
| Guided walkthrough | A demonstrated reading order, then the supported finding and conclusion |
| Blind exercise | The symptom, investigation window and starting view; findings arrive on reveal |
| Historical reference | Available evidence and retained findings, including evidence no longer recoverable live |

Keep deeper mechanisms and recovery history in factual notes or references when they are beyond the learning task. Don't require expired logs, inaccessible tools or unintroduced implementation details to solve an exercise. Do not induce incidents or replay mitigations without separate authorization.

## Prepare the example

- Verify the symptom and the attribution separately. A dominant sampled caller is not automatically the sole cause of a CPU spike.
- Read the actual metric/query: units, aggregation, sampling, grouping, smoothing window and what is counted. Starts are not concurrency; field writes are not submissions; a chart proxy may differ from a control's input.
- Establish the conclusion before building. What action happened, what changed afterward, or where should triage stop? Identify an immediate mitigation versus a later improvement. Don't merge distinct paging, admission and execution settings into a vague “threshold change.”
- Resolve material evidence gaps or frame the case as a pressure window/reference instead of inventing a page or causal explanation. Keep internal research status out of audience captions unless it affects interpretation.

## Make links usable live

- Use a fixed historical window, a clear year/timezone and a date range the tool accepts when pasted. Allow enough baseline, rise and recovery to understand the event; avoid a peak-only crop unless that is the task.
- Check displayed ranges against the actual URL parameters. For Datadog, use paused historical links with matching `from_ts`, `to_ts` and `live=false` rather than a sliding live view.
- Keep the overview window and narrower attribution window distinct. If a link is widened, keep existing counts labelled with their original sample window unless those counts are recomputed.
- Preserve the exact namespace/job/filter spelling from the source. Check that a highlighted widget measures the intended quantity, not a similarly named metric.
- Operational links should open the actual control or relevant runbook section. Source-code links support implementation claims; they are not substitutes for operator destinations.
- Cache or retain approved evidence for the presentation. Don't restart a broad investigation during a copy revision merely because raw logs have since expired.

## Stage a blind exercise

The initial state shows a neutral scenario number, the verified symptom or pressure window, the copyable range and the starting investigation link. Keep caller names, answer-bearing titles, diagnostic questions and supporting links out of that state. Check link labels as well as slide text.

Use one native Reveal fragment for the complete checkpoint, its diagram and supporting links. The next advance should move on; don't make the audience reveal each bullet or introduce a separate answer button/key handler.

```html
<section id="scenario-1">
  <div class="slide-content">
    <h2>Scenario 1: High request latency</h2>
    <p><!-- Fixed range, year/timezone and starting dashboard link. --></p>
    <div class="fragment" data-fragment-index="0">
      <h3>Findings</h3>
      <ul>
        <li><!-- Observed pressure. --></li>
        <li><!-- Supported workload attribution. --></li>
        <li><!-- Next investigation or verified outcome. --></li>
      </ul>
      <!-- Diagram and supporting links belong inside this fragment. -->
    </div>
  </div>
</section>
```

For a guided example, establish the symptom and reading order, then reveal the finding and conclusion. Don't leave a known outcome solely in speaker notes. Readable scroll view may show all findings; use slide view for a blind live exercise. Fragment hiding is presentation staging, not confidentiality.

## Check the presentation path

- Test the initial state, the fully revealed state and the next advance in slide view. Confirm hidden supporting links don't leak the answer through visible labels.
- Check fit and readability after the reveal, not only on the mostly empty initial slide.
- Check the exact fixed links and window labels, including any intentionally different attribution window.
- Confirm retained counts still describe their stated cohort/window. Keep live targeting, deployed configuration and historical configuration distinct where the distinction matters.
- Keep facilitator navigation instructions off the audience slide. Use short factual notes, or a separate pre-meeting reference if requested.
