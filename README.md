# Compliance Certificate Merge Detection

A Salesforce Apex trigger framework that detects when Account merges cause related `ComplianceCertificate__c` records to be reparented, and automatically deactivates them with an audit-friendly reason — solving a problem Salesforce provides no direct platform hook for.

## The problem

At a financial services firm, compliance certificates (AML verification, KYC checks, suitability reviews, etc.) are held on a custom object related to `Account` via a lookup field. When two duplicate Account records are merged, Salesforce reparents the losing Account's related records onto the surviving Account — including these certificates.

A certificate that was valid for one Account isn't necessarily still valid once it's silently living under a different, merged Account. This project detects that reparenting event and flags the certificate as `Inactive`, with a clear reason recorded for audit purposes.

## Why this is harder than it sounds

Two assumptions that seem reasonable turned out to be wrong, and discovering that shaped the whole design:

**Assumption 1: reparenting fires a normal Apex trigger on the child record.** It doesn't. A merge operation reparents related records as an internal platform operation — it does not invoke `before`/`after update` triggers on the children being moved. The only triggerable events are an `after update` on the surviving Account and a `before`/`after delete` on the losing Account.

**Assumption 2: Field History Tracking would at least capture the change.** Also wrong, confirmed empirically rather than assumed — enabling history tracking on the lookup field and querying `ComplianceCertificate__History` after a real test merge showed zero history rows for the reparenting. The field's live value changes; no audit trail is written for it.

So there is no direct, reliable, platform-native signal that says "this specific record was just reparented by a merge." The detection approach here is built entirely around the signals that *do* survive: the field's new value, and the standard system fields (`LastModifiedDate`, `LastModifiedById`) that a normal DML operation still updates even when it bypasses triggers and history tracking.

## How detection works

1. `AccountTrigger` fires on `after delete` (this is when a losing Account in a merge is deleted).
2. `MasterRecordId` on the deleted Account is checked — this field is populated *only* when the Account was deleted as the losing side of a merge, distinguishing a merge from an ordinary delete.
3. Candidate certificates are queried: records now pointing at the winning Account, modified within a narrow recent time window, by the same user running the current transaction.
4. Confirmed certificates are deactivated with a status reason of "Inactive due to account merge."

This is a heuristic, not a guarantee — see [Limitations](#limitations) below.

## Architecture

| Class | Responsibility |
|---|---|
| `TriggerHandler` | Reusable base class: context dispatch, recursion/loop-count guards, bypass switches. Not specific to this feature. |
| `AccountTriggerHandler` | Thin orchestration layer — detects, then delegates. No business logic itself. |
| `IComplianceCertificateSelector` / `ComplianceCertificateSelector` | Data access, isolated behind an interface for testability. |
| `AccountMergeCertificateResolver` | The decision logic — correlates a merge event against candidate certificates and returns confirmed matches. |
| `ComplianceCertificateMergeDeactivator` | The action — updates confirmed certificates to `Inactive`. |

Each class has exactly one job. Detection, decision, and action are deliberately kept separate so each can be tested — and reasoned about — independently.

## Testing approach

Two distinct testing strategies are used, deliberately:

- **Fakes, no real DML** (`AccountMergeCertificateResolverTest`) — the resolver's correlation logic is tested against a hand-written fake implementing `IComplianceCertificateSelector`, with no database access at all. This makes it possible to test edge cases (a false-positive candidate that shouldn't be confirmed, no merge losers at all) that would be difficult or slow to provoke with real data.
- **Real DML, real merge** (`AccountTriggerHandlerTest`) — a genuine `merge` statement is executed in test context, proving the whole pipeline against actual Salesforce merge semantics rather than assumptions about them. This is the test that would have caught both wrong assumptions above.

`ComplianceCertificateSelectorTest` sits in between — it can't be mocked, since its entire purpose is verifying the SOQL filter logic itself, so it runs against real inserted records.

<img width="1255" height="767" alt="image" src="https://github.com/user-attachments/assets/40eb107a-2e98-4c9c-b106-14c9b4b0488c" />


## Limitations

- **This is a heuristic, not a certainty.** In principle, an unrelated process modifying a certificate in the same narrow time window, by the same user, could be misidentified as a merge-driven reparent. The time window is deliberately narrow to minimize this risk.
- **No field-history cross-check is possible**, for the reason explained above — there's no additional independent signal available to corroborate the heuristic.
- The time window (currently 20–30 seconds) may need recalibration against real-world transaction timing in a production-scale org.

## Tech stack

Apex, Salesforce DX (SFDX) project structure, deployed and tested via Salesforce CLI.
