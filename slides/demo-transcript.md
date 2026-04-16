# Demo Transcript — MRI Pre-Authorization

## Happy Path (Member M-10047, Jane Doe)

**AGENT**: Hi, I'm an AI service assistant for Meridian Health. How can I help you today?

**PATIENT**: Hi, I need to submit an MRI pre-auth for my knee.

**AGENT**: I'm sorry to hear about your knee — let's get this taken care of quickly. Could you please provide your Meridian Member ID?

**PATIENT**: It's M-10047.

**AGENT**: Thank you, Jane. I've located your account. What's the CPT code for the MRI? If you're not sure, just tell me what body part is being imaged and I can help.

**PATIENT**: It's for my left knee. CPT 73721.

**AGENT**: Got it — CPT 73721, MRI of the knee without contrast. What's the NPI of the ordering provider?

**PATIENT**: 1234567890

**AGENT**: Thank you. And finally, what's the clinical reason the MRI was ordered?

**PATIENT**: Torn meniscus confirmed by imaging referral from Dr. Smith. I've had knee pain for 3 months and physical therapy didn't help.

**AGENT**: Thank you, Jane. Let me run the verification checks — this will just take a moment.

*[Checking your benefits...]*
*[Running fraud risk analysis...]*
*[Fetching coverage details...]*
*[Creating your pre-auth case...]*
*[Finalizing decision...]*

**AGENT**: Great news, Jane! Your MRI pre-authorization has been approved.

Here are the details:
- **Authorization Number**: AUTH-4721
- **Case Number**: 00001234
- **Coverage**: 80% in-network
- **Your estimated copay**: $250.00
- **Remaining deductible this plan year**: $375.00

You can schedule your MRI at any in-network imaging center. Is there anything else I can help with?

**PATIENT**: No, that's everything. Thank you!

**AGENT**: You're welcome, Jane. I hope your knee feels better soon. Take care!

---

## Escalation Path (Member M-10099, Marcus Reyes)

**AGENT**: Hi, I'm an AI service assistant for Meridian Health. How can I help you today?

**PATIENT**: I need an MRI pre-auth. Member ID M-10099.

**AGENT**: Thank you, Marcus. I've pulled up your account. What's the CPT code for the MRI?

**PATIENT**: 70553, brain MRI.

**AGENT**: CPT 70553, MRI of the brain with and without contrast. What's the NPI of the ordering provider?

**PATIENT**: 1234567890

**AGENT**: And what's the clinical reason for the MRI?

**PATIENT**: Severe headaches for 2 weeks.

**AGENT**: Thank you. Let me run the checks now.

*[Checking your benefits...]*
*[Running fraud risk analysis...]*
*[Creating your pre-auth case...]*
*[Finalizing decision...]*

**AGENT**: Marcus, your pre-authorization request has been submitted and routed to our clinical review team for further evaluation.

- **Case Number**: 00001235
- **Status**: Under Clinical Review
- **Expected response**: Within 48 hours per New York state requirements

A utilization management reviewer will contact you or your provider's office with the determination. Is there anything else I can help with?

---

## Narrator Notes (say during demo)

**After happy path approval**: "End to end: 12 seconds. The before-state was 3-7 days. That is the headline."

**After escalation**: "The AI never denies. The fraud agent returned a risk score of 0.72 — six prior authorizations reversed in 12 months, three different ordering providers across four facilities in six months, geographic mismatch. That context is attached to the Case for the human reviewer. A medical director makes the adverse determination. That's how CMS-0057 requires it to work."

**D360 callout**: "Notice the agent has context about Jane's care history — three office visits showing knee pain progression, 12 sessions of PT with limited improvement, ortho referral. That data lives in the EHR. Data 360 federates it into the member's unified profile — no ETL, no data copy, no HIPAA residency risk."
