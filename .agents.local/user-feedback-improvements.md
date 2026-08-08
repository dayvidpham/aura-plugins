As an extra step to the Epoch workflow: we can use mostly reviewer-mini agents for review, until we achieve a clean 0/0/0. Then use one more review wave with full `review` agents, to see if we reach the 0/0/0 clean review. If all the work is already specified and planned out, and all the API surfaces are determined, then we can use worker-mini for implementation. If there is vague spec, and the work is cross-repo, then we should use the `worker` agent. When we get back the results of a review, run an architect planning subagent to consolidate the results, figure out a internally consistent fix instead of monkey-patching each issue, and write new impl leaves as children of the review nodes. Reviews and fix waves should suggest the minimal amount of code changes needed. We need to ship faster, we don't need extensively robust test code right now that will cover every possible case.

// testing
As an extra step to the Epoch workflow: we can use mostly `reviewer-mini` agents for review, until we achieve a clean 0/0/0. Then use one more review wave with full `reviewer` agents, to see if we reach the 0/0/0 clean review. If all the work is already specified and planned out, and all the API surfaces are determined, then we can use `worker-mini` for implementation. If there is vague spec, the work is cross-repo, or it involves modeling and implementing complex parts of the codebase, then we should use the `worker` agent. When we get back the results of a review, run an `architect-subagent` planning agent to consolidate the results and to figure out a internally consistent fix instead of monkey-patching each issue. `reviewer` agents, `architect`s, and `worker`s: should suggest the minimal, maintainable code changes or new APIs needed to solve the problem. Don't need to boil the ocean and chase down every possible verification path, or be the ultimate and modular, clean, generic library. Complex over-engineering: YAGNI (you ain't gonna need it) and focus on quick iterations following the critical path. The supervisor should write new impl leaves as children of the review nodes. Reviews and fix waves should suggest the minimal amount of code changes needed. We need to ship faster, we don't need extensively robust test code right now that will cover every possible case.

Whenever we run a worker wave, workers should be given the relevant Beads task IDs (reviewer Beads tasks, implementation plan, slices, URE/URDs, etc.), Git commit hashes, and aboslute filesystem paths to properly ground the work, and for them to understand what they even have to implement or fix. If there are any findings, let's run a `worker` agent for the remainder of the work, not a `worker-mini`. 

This is the same with the reviewers too. They should receive appropriate grounding for their review tasks. They need the UREs, URDs, ratified proposal, the implementation plan, and the relevant slices.

Don't just blindly list the Beads task IDs, deliver them in a concise bulleted list, with some context about why they're relevant and their description. Can also deliver them this Beads context in YAML frontmatter format, before any other handwritten instructions. 

Let's also extend the Epoch protocol for this work, don't need to record this anywhere except maybe a Beads note. During a review or worker wave, the spawned review or worker agents will (even if they are mini agents):

- delegate clear or straightforward parts of their tasks to their corresponding `-mini` agents
- utilize `-mini` agents when they need information, for exploration, where these `-mini` agents will produce a concise report on their assigned exploration taskings
- synthesize and coalesce the various reports from their delegates, verify the reports themselves, then proceed, or delegate again

This way, for example for a review wave, the root parent agent -> `reviewer-1` -> `reviewer-delegate-1` (many minis for exploration and review, fan out)

When a delegate further delegates to a -mini subagent, should also adopt the same YAML handoff principles as usual for delegation.

## Review Details

Run ONE reviewer-mini agent to run all test gates and checks, log the outputs, then feed those results into the wave of reviewers, so they don't all waste time running the tests.

