---
name: next
description: >
  Energy-aware priority surfacing. Considers current queue, goals, reminders,
  and asks about focus/energy level to recommend what to work on NOW. Designed
  for ADHD-friendly task selection — reduces choice paralysis by presenting
  one clear recommendation with alternatives.
when_to_use: >
  "next", "what should I do", "what's next", "I don't know where to start",
  "pick something for me", "I have low energy", "quick win"
argument-hint: "[energy: low|medium|high] [time: Nm|Nh]"
allowed-tools: Bash Read Grep Glob
---

# next -- What Should I Do Now?

Reduce choice paralysis by surfacing ONE recommended task based on your current
energy, available time, and priorities. Provides alternatives without overwhelming.

## When to Use

- You're staring at your task list feeling stuck
- You have limited time and need the highest-value thing
- You just finished something and want momentum
- You're low energy and need something achievable

## When NOT to Use

- You already know what to do (just do it)
- You need to add tasks (use `/queue add`)
- You want a full session briefing (use `/orient`)

---

## Procedure

### Step 1: Load State

Read config, then load:
1. `{ops_dir}/queue/` — all task files
2. `{self_dir}/goals.md` — active threads for priority alignment
3. `{ops_dir}/reminders.md` — anything due today

### Step 2: Gather Context (if not provided as arguments)

If energy level not provided, ask:

```
How's your energy/focus right now?
  (1) Low — tired, distracted, want something easy
  (2) Medium — functional, can handle moderate complexity
  (3) High — locked in, ready for deep work
```

If time not provided, ask:

```
How much time do you have?
  (1) Quick — under 15 minutes
  (2) Short — 15-45 minutes
  (3) Full — 1+ hours
```

### Step 3: Score Tasks

For each task in `{ops_dir}/queue/` with `status: ready`:

Read its frontmatter. Expected fields:
- `energy`: low | medium | high (required energy level)
- `size`: quick | short | full (estimated time)
- `priority`: 1-5 (1 = highest)
- `goal`: which active thread this serves (optional)
- `tags`: for topic matching

**Scoring rules:**

1. **Energy match** (most important for ADHD):
   - User low → only show low-energy tasks
   - User medium → show low and medium
   - User high → show all, prefer high-energy tasks

2. **Time fit**:
   - Filter out tasks that exceed available time
   - Prefer tasks that fill the time slot (don't suggest 15min task for a 2hr block)

3. **Priority boost**:
   - Tasks aligned with active goals get +2 priority
   - Overdue reminders that map to queue items get +3
   - Tasks with `status: in-progress` get +1 (momentum)

4. **Staleness penalty**:
   - Tasks untouched for >7 days get -1 (they might be stale/blocked)

### Step 4: Present Recommendation

Output format:

```markdown
# Next: {task title}

**Why this**: {one sentence — e.g., "Aligns with your active goal, fits your energy, and takes ~20min"}

**First step**: {the smallest concrete action to start — reduce activation energy}

---

## Alternatives

If that doesn't feel right:

1. **{task B title}** — {one-line reason} [{size}] {if in-progress: `[continuing]`}
2. **{task C title}** — {one-line reason} [{size}] {if in-progress: `[continuing]`}

## Quick wins available

{if any low-energy/quick tasks exist, list 1-2 regardless of priority}
- {task title} [{estimated time}]
```

### Step 5: If Queue is Empty

```markdown
# Nothing in the queue

Your task queue is empty. A few options:

1. **Check reminders** — you have {N} items due
2. **Process inbox** — {N} items waiting (`/maintain inbox`)
3. **Add something** — `/queue add "description"`
4. **Reflect** — `/reflect` to capture what you've been thinking about
```

---

## ADHD-Friendly Design Principles

These rules shape the output:

1. **ONE recommendation, not a list** — the primary output is a single task. Alternatives are visually de-emphasised.
2. **First step, not full plan** — tell them the smallest possible starting action. "Open the file" not "implement the feature."
3. **Energy-first filtering** — never suggest deep work to someone who said "low energy." Respect the input.
4. **Permission to skip** — the alternatives section implicitly says "it's OK if the top pick doesn't land."
5. **Quick wins always visible** — even at high energy, showing a quick win provides an on-ramp if the main task feels too big.
6. **No guilt** — never say "you should have done this yesterday" or reference staleness negatively. Just surface what's ready now.

---

## Task File Format (expected in queue/)

```markdown
---
title: Short descriptive title
created: YYYY-MM-DD
status: ready | in-progress | blocked | done
energy: low | medium | high
size: quick | short | full
priority: 1-5
goal: "name of active thread this serves"
tags: [topic1, topic2]
blocked_by: "reason or link" (if status: blocked)
---

# {Title}

{Description of what needs to be done}

## Steps

- [ ] First concrete step
- [ ] Second step
- [ ] ...

## Context

{Links to relevant notes, domain knowledge, or prior work}
[[knowledge/lizard-brain/Some relevant note]]
```

---

## Edge Cases

- **All tasks are high-energy but user is low**: Apply the "quick wins always visible" principle — suggest inbox processing, vault maintenance, or reviewing session notes. These are productive without being demanding. Or suggest taking a break.
- **No tasks match time constraint**: Suggest decomposing a larger task into a sub-step that fits. Offer to help with `/queue decompose`.
- **Only one task exists**: Still present it in the recommendation format (the structure itself reduces activation energy).
- **User repeatedly skips recommendations**: After 3 skips in a session, ask "What's making these not land? We can adjust priorities or add what you actually want to do."
