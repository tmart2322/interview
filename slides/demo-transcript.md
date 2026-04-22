# Demo Transcript — MRI Pre-Authorization

## Happy Path (Member M-10047, Jane Doe)

**AGENT**: Hi, I'm an AI service assistant for Meridian Health. How can I help you today?

**PATIENT**: Hi, my doctor said I need to get an MRI on my knee and that I need to get it pre-authorized first. Can you help me with that?

**AGENT**: I'm sorry to hear about your knee — let's get this taken care of quickly. Could you please provide your Meridian Member ID? You can find it on your insurance card.

**PATIENT**: Sure, it's M-10047.

**AGENT**: Thank you, Jane. I've located your account. Do you have the CPT code for the MRI? Your doctor's office should have included it on your referral paperwork.

**PATIENT**: Let me check... I have a paper here from Dr. Smith's office. It says 73721?

**AGENT**: That's right — CPT 73721, MRI of the knee without contrast. And what's the NPI number for Dr. Smith? That should also be on the referral.

**PATIENT**: I see a number here... 1234567890. Is that it?

**AGENT**: That's it. And can you tell me a little about why the MRI was ordered? What's been going on with your knee?

**PATIENT**: I've had knee pain for about 3 months now. I did physical therapy but it didn't really help. Dr. Smith thinks it might be a torn meniscus and wants the MRI to confirm.

**AGENT**: Thank you, Jane. I have everything I need. Let me run the verification checks — this will just take a moment.

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
- **Remaining deductible this plan year**: $450.00

You can schedule your MRI at any in-network imaging center. Is there anything else I can help with?

**PATIENT**: Wow, that was fast. No, that's everything. Thank you so much!

**AGENT**: You're welcome, Jane. I hope your knee feels better soon. Take care!

---

## Escalation Path (Member M-10099, Marcus Reyes)

**AGENT**: Hi, I'm an AI service assistant for Meridian Health. How can I help you today?

**PATIENT**: Yeah I need a pre-auth for an MRI.

**AGENT**: I'd be happy to help with that. Could you provide your Meridian Member ID?

**PATIENT**: M-10099.

**AGENT**: Thank you, Marcus. Do you have the CPT code from your doctor?

**PATIENT**: 70553. It's for my head.

**AGENT**: CPT 70553, MRI of the brain with and without contrast. What's the NPI of the ordering provider?

**PATIENT**: 1234567890

**AGENT**: And what's the reason the MRI was ordered?

**PATIENT**: I've been getting really bad headaches for a couple weeks.

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

**After happy path approval**: "End to end: under 60 seconds. The before-state was 3-7 days. That is the headline."

**After escalation**: "The AI never denies. The fraud agent returned a risk score of 0.72 — six prior authorizations reversed in 12 months, three different ordering providers across four facilities in six months, geographic mismatch. That context is attached to the Case for the human reviewer. A medical director makes the adverse determination. That's how CMS-0057 requires it to work."

**D360 callout**: "Notice the agent has context about Jane's care history — three office visits showing knee pain progression, 12 sessions of PT with limited improvement, ortho referral. That data lives in the EHR. Data 360 federates it into the member's unified profile — no ETL, no data copy, no HIPAA residency risk."
