# UAT Structured Output Template

Use this XML template to capture UAT results. Each component is presented one at a time to the user with its definition, motivating example, and design-space questions.

Before tracker recipes, follow [TRACKER.md](TRACKER.md) to select the store,
explicit namespace and registered author, and bind task variables to full URIs.

## Template

```xml
<uat>
  <metadata>
    <title>{{UAT_TITLE}}</title>
    <task-uri>{{UAT_TASK_URI}}</task-uri>
    <proposal-ref>{{PROPOSAL_TASK_URI}}</proposal-ref>
    <phase>{{plan | implementation}}</phase>
    <date>{{YYYY-MM-DD}}</date>
  </metadata>

  <components>

    <component id="{{N}}">
      <name>{{COMPONENT_NAME}}</name>

      <definition>
        <code lang="{{LANGUAGE}}">
{{CODE_SNIPPET_OR_INTERFACE_DEFINITION}}
        </code>
      </definition>

      <motivating-example>
        {{DESCRIPTION_OF_BEFORE_AFTER_OR_USAGE_SCENARIO}}
        <code lang="{{LANGUAGE}}">
{{EXAMPLE_CODE_OR_OUTPUT}}
        </code>
      </motivating-example>

      <questions>

        <question id="Q{{M}}">
          <text>{{EXACT_QUESTION_TEXT_PRESENTED_TO_USER}}</text>
          <context>{{OPTIONAL_ADDITIONAL_CONTEXT_SHOWN_BEFORE_OPTIONS}}</context>

          <options>
            <option id="{{A}}">
              <label>{{OPTION_LABEL}}</label>
              <description>{{OPTION_DESCRIPTION_WITH_TRADEOFFS}}</description>
            </option>
            <option id="{{B}}">
              <label>{{OPTION_LABEL}}</label>
              <description>{{OPTION_DESCRIPTION_WITH_TRADEOFFS}}</description>
            </option>
            <!-- 2-4 options per question -->
          </options>

          <user-response>
            <selected>{{OPTION_LABEL_OR_OTHER}}</selected>
            <verbatim>{{USER_RESPONSE_VERBATIM_INCLUDING_NOTES}}</verbatim>
          </user-response>
        </question>

        <!-- User-initiated comments (not in response to a question) -->
        <user-comment>
          <verbatim>{{EXACT_USER_COMMENT}}</verbatim>
        </user-comment>

      </questions>

      <decision>{{ACCEPT | REVISE}}</decision>
      <decision-notes>{{OPTIONAL_NOTES_ON_DECISION}}</decision-notes>
    </component>

  </components>

  <addenda>
    <!-- Post-UAT user comments captured verbatim -->
    <addendum>
      <verbatim>{{EXACT_USER_STATEMENT}}</verbatim>
      <design-implication>{{WHAT_THIS_MEANS_FOR_THE_DESIGN}}</design-implication>
    </addendum>
  </addenda>

  <final-decision>
    <verdict>{{ACCEPT | REVISE}}</verdict>
    <summary>
      <change id="{{N}}">{{KEY_DESIGN_CHANGE_FROM_ORIGINAL_PROPOSAL}}</change>
      <!-- One per design change -->
    </summary>
    <open-questions>
      <question>{{DEFERRED_OR_UNRESOLVED_QUESTION}}</question>
    </open-questions>
  </final-decision>

</uat>
```

## Tracker Commands

All operands are full task URIs. Bind `$UAT_TASK_URI`, `$PROPOSAL_TASK_URI`,
`$URD_TASK_URI`, and `$REQUEST_TASK_URI` from tracker output; see
[TRACKER.md](TRACKER.md) for the full supported recipe set.

```bash
# 1. Create the UAT task with a structured description.
#    - The title is positional.
#    - Labels are added in a second, non-atomic command.
#    - The description contains the full XML-structured UAT record.
UAT_TASK_URI=$(pasture task create "UAT: {{PLAN_OR_IMPL}} acceptance for {{FEATURE}}" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "---
references:
  proposal: {{PROPOSAL_TASK_URI}}
  urd: {{URD_TASK_URI}}
  request: {{REQUEST_TASK_URI}}
---
<FULL_XML_STRUCTURED_DESCRIPTION>" --format json | jq -er '.id')
pasture task label add "$UAT_TASK_URI" aura:p5-user:s5-uat --namespace "$PASTURE_NAMESPACE"

# 2. Record post-UAT addenda as attributed comments (user feedback after main survey).
pasture task comment add "$UAT_TASK_URI" "UAT ADDENDUM (user-initiated, verbatim): {{VERBATIM}}" \
  --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"

# 3. Update the URD with UAT results.
pasture task comment add "$URD_TASK_URI" "UAT {{PHASE}}: {{VERDICT}} - {{key design decisions summary}}" \
  --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"

# 4. After UAT passes, proceed to ratification (Phase 6).
pasture task label add "$PROPOSAL_TASK_URI" aura:p6-plan:s6-ratify --namespace "$PASTURE_NAMESPACE"
pasture task comment add "$PROPOSAL_TASK_URI" "RATIFIED: All 3 reviewers ACCEPT, UAT passed ($UAT_TASK_URI)." \
  --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"

# 5. If UAT fails (REVISE), return to proposal phase.
#    - Do NOT ratify.
#    - Create a new PROPOSAL-N task (increment N), referencing the original.
#    - Record the specific component and verbatim feedback.
```

## Rules

1. **One component per AskUserQuestion call** — never batch all components into one survey
2. **Show definition + example BEFORE asking** — user must see the concrete thing first
3. **Options describe tradeoffs, not approval levels** — never use "exactly matches" / "mostly matches"
4. **Capture verbatim** — user responses are recorded exactly as given, including notes
5. **Option descriptions are part of the record** — capture label AND description for each option presented
6. **User-initiated comments** go in `<user-comment>` outside the question/answer flow
7. **Addenda** capture post-UAT feedback that modifies the design
8. **Final decision** summarizes all design changes relative to the proposal being UAT'd
9. **Binary decisions only** — component decisions are ACCEPT or REVISE (no intermediate levels)
10. **Findings tracked via severity tree** — if ACCEPT with minor concerns, track them as IMPORTANT/MINOR findings in the severity tree during code review (Phase 10), not at UAT time

## See Also

- [UAT_EXAMPLE.md](./UAT_EXAMPLE.md) — Complete worked example of this template in use
