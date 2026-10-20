# Business model and implementation status

## Product goal

Affordable German learning for Arabic-speaking and international learners, with structured A1–C2 learning, exam preparation, and private tutoring. The original web prototype and new Flutter source foundation include only a short A1 learning flow, local flashcard review, and a small grammar quiz. Content is a demo, not a complete course, officially reviewed curriculum, or Goethe exam product.

## Possible revenue (not implemented or validated)

- Free and paid learning plans with server-enforced entitlements.
- Reviewed courses, original/licensed exam practice, worksheets, and authorized videos.
- Metered AI practice with explicit quota and cost limits.
- Verified teacher marketplace with transparent commissions after booking, refunds, attendance, and payouts are defined.
- Group courses and institutional licensing after validation.

There are no prices, customers, demand, margin, subscriptions, checkout, paid entitlements, teacher inventory, bookings, or profitability results implemented or validated. Do not sell a paid plan based on this local preview.

## Controls required before launch

Select a payment provider only after confirming merchant eligibility for Egypt and intended markets, currencies/settlement, recurring and one-time payments, refunds, webhook verification, fees, marketplace payouts, and current mobile-store rules. Use server-verified idempotent events; never store card data or grant paid access from client state. No live payment is integrated.

Choose an AI provider only after reviewing Arabic/German quality, privacy, availability, and text/voice costs. Enforce usage quotas, rate limits, cost accounting, budgets, and retention on a server. Both current tutor areas are labeled local samples and make no AI calls.

Label content by review and license status. Obtain qualified legal advice on privacy, minors/parental consent, consumer terms/refunds, and target-market requirements. Revenue and AI costs are currently zero; any later profitability calculation must clearly mark estimates.
