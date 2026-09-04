---
name: slack-draft
description: Draft a Slack message in Dexter's voice. Use when asked to draft or write a Slack message, post in a channel, or reply to a thread.
argument-hint: "[channel-url-or-thread] [message-context]"
---

Draft a Slack message for the user. The task: $ARGUMENTS

## Style Calibration

Read the user's Slack writing style from memory at:
`~/.claude/projects/-Users-dexter-projects-rippling-main/memory/user_slack_writing_style.md`

If the user specifies a formality level, adjust accordingly:

### Casual (default)
The user's natural Slack voice. Lowercase starts, short sentences, no headers, linear flow. Technical terms in backticks but everything else reads like talking to a coworker. This is the default.

### Standard
Slightly more structured. May capitalize sentence starts and use a brief intro line. Still no bold headers or numbered lists. Good for cross-team threads where people don't have full context.

### Formal
For exec-facing or company-wide channels. Proper capitalization, clear paragraph breaks, may use bold for key terms (not headers). Still concise — no corporate filler.

## Process

1. **Read the thread** (if a URL is provided) using `slack_read_thread` to understand the conversation context, who's involved, and what's already been said.

2. **Read relevant context** — if the message is about code changes, PRs, or incidents, read the relevant files, PRs, or Slack threads to get the technical details right.

3. **Draft the message** using `slack_send_message_draft`. Match the style level. Key rules:
   - Never put words in the user's mouth about things you're not sure about
   - Get the technical details exactly right — wrong details are worse than vague ones
   - Match the energy of the thread (incident urgency vs casual discussion vs status update)
   - Keep it as short as possible while covering what needs to be said
   - If replying to a thread, use `thread_ts` from the parent message

4. **Tell the user** where the draft is so they can review and send.

## Common Patterns

**Incident RCA post**: State ownership, explain what happened technically, link the fix PR, confirm revert safety. No apology tour — just facts and next steps.

**Status update**: What changed, link to PR, any action needed from others.

**Code review request**: Link to PR, one line on what it does, tag the reviewer.

**Question/ask**: State what you need, provide context inline, no preamble.
