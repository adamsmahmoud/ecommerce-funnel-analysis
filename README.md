# Retail Rockets

RetailRocket is an ecommerce site. Every event in the dataset is a view, an addtocart, or a transaction. Question: do visitors who come back on another day buy more often than visitors who only ever show up once?

- first time: active on one calendar day
- returning: active on more than one calendar day
- columns: timestamp, visitorid, event, itemid, transactionid

## Setup

`events.csv` is not in the repo since it is too big for GitHub, but it is public and free to download. Grab it, then load it into a BigQuery dataset named `retail_rockets` with a table named `events` (columns: timestamp INTEGER, visitorid INTEGER, event STRING, itemid INTEGER, transactionid INTEGER). Then run the SQL files in order.

```bash
python3 -m venv .venv
./.venv/bin/pip install pandas statsmodels jupyter ipykernel
./.venv/bin/jupyter notebook notebooks/01_significance_test.ipynb
```

## Step 1: Load and Check the Data

We have about 2.7 million events spread over 4.5 months. The visitor and item IDs are hashed, so there are no product details or user attributes to work with, which means the only things I can really build off of are the event type and when it happened. After sessionizing, I checked that the row count still matched the raw events (2,756,101 both ways), so nothing got dropped or duplicated along the way.

## Step 2: Sessionize the Events

The raw data is just one long list of events per visitor, so I grouped them into sessions in BigQuery. If a visitor goes 30 minutes without doing anything, the next event they make starts a new session. 30 minutes is the standard cutoff most analytics tools use so I went with that instead of picking my own number.

## Step 3: Splitting the Groups (Before Comparing Them)

So before comparing anything, I want to be clear about what the two groups actually are. A visitor counts as returning if they were active on more than one distinct calendar day, and first time if they only ever showed up on one. Converting means the visitor had at least one transaction event. That gives us 1,407,580 visitors total, and only 143,769 of them (about 10.2%) are returning.

The big thing to say here is that this is not a real A/B test. Nobody assigned these visitors to a group, they sorted themselves into one by either coming back or not, so I am treating this as a comparison and not as proof of anything.

## Step 4: Conversion by Group

So after running the numbers, I found that first time visitors converted 0.53% of the time (6,689 out of 1,263,811) while returning visitors converted 3.50% of the time (5,030 out of 143,769). That is a gap of 2.97 percentage points, which is a returning visitor being roughly 6 times more likely to buy.

I ran a two proportion z test on that gap in statsmodels and put a 95% confidence interval on the difference itself, which came out to (2.87, 3.07). The interval is nowhere close to zero so this is not something I can write off as luck.

## Step 5: Windowed Re-run and Sample Size Check

There is a problem with the Step 4 comparison. Any event after the first day counts toward the returning label, even events after someone already bought something. So a visitor who buys and then comes back to check their order ends up counting as returning after the fact, and that inflates the gap.

To fix that, I only look at the first 7 days after a visitor's first appearance to decide whether they count as returning or first time. Returning means active on 2 or more distinct days in that window, and anyone who already bought during that same window gets dropped from the comparison, since I am trying to measure what happens after the label is set, not before. Conversion only counts from day 8 onward. I also drop visitors whose 7 day window runs past the end of the data since I cannot fully observe them. Query is `sql/05_windowed_segmentation.sql`.

That leaves 1,346,912 visitors, 76,094 returning and 1,270,818 first time. Returning visitors converted 0.47% of the time after day 7 (360 out of 76,094), while first time visitors converted 0.06% of the time (794 out of 1,270,818). That is a gap of 0.41 percentage points, so returning visitors convert about 7.6 times as often. I ran the same two proportion z test as before, and the 95% confidence interval on the gap is (0.36%, 0.46%), still nowhere close to zero.

Once that gets fixed, the gap shrinks a lot, from 2.97 points down to 0.41. That tells me a good chunk of the Step 4 gap was really just people buying and then coming back, not coming back and then buying.

I also checked whether this sample was even big enough to catch a smaller gap, using the same 95% confidence idea as above and asking that a real gap get caught 8 times out of 10. The smallest gap this sample could reliably catch that way comes out to about 0.03 percentage points. The actual gap is 0.41 points, way bigger than that, so the result is not one that only holds up because the bar was set low.

## Step 6: Funnel, Session by Session

The funnel query originally counted visitors, not sessions, so the 30 minute session cutoff from Step 2 never actually showed up in the numbers. I fixed that by rerunning the funnel scoped to session_id instead of just visitorid, so a visitor who leaves and comes back hours later gets counted as a separate pass through the funnel like it should.

Session counts came out higher at every stage than visitor counts, which makes sense since one visitor can go through the funnel more than once. Views went from 1,404,179 visitors to 1,755,781 sessions, add to cart went from 32,272 to 35,830, and transactions went from 10,447 to 11,760. Query is `sql/03_funnel_summary.sql`, and it keeps both versions side by side so I can compare them.

## Step 7: Retention by First-Day Behavior

The retention curves in `sql/04_cohort_retention.sql` only grouped by cohort week, so there was no way to see if some visitors retain better than others. I added a segment based on what a visitor did on their first active day: carted if they added something to cart (or bought) that day, viewed_only if they just looked around.

Carted visitors retain noticeably better. At week 1, 7.8% of carted visitors are still active compared to 3.1% of viewed_only visitors, and that gap holds up through week 8 (0.98% vs 0.62%). I also added a check so a cohort only shows up at a given week if enough time has actually passed to observe it, which matters more as new cohorts keep getting added toward the end of the data.

## Recommendation

The gap is real and it is huge, but it does not mean the second visit is what causes the sale. People who come back are already more interested in buying than people who bounced once and never returned, so the group is self selected and the causation could easily run the other way. What I would actually take from this is that a return visit is a strong signal of intent, and I would trust it as a signal way before I would trust it as a lever.

## Files

- `sql/01_sessionize.sql`
- `sql/02_segment_counts.sql`
- `sql/03_funnel_summary.sql`
- `sql/04_cohort_retention.sql`
- `sql/05_windowed_segmentation.sql`
- `sql/06_segment_counts_windowed.sql`
- `notebooks/01_significance_test.ipynb`
