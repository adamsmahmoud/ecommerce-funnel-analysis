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

## Recommendation

The gap is real and it is huge, but it does not mean the second visit is what causes the sale. People who come back are already more interested in buying than people who bounced once and never returned, so the group is self selected and the causation could easily run the other way. What I would actually take from this is that a return visit is a strong signal of intent, and I would trust it as a signal way before I would trust it as a lever.

## Files

- `sql/01_sessionize.sql`
- `sql/02_segment_counts.sql`
- `notebooks/01_significance_test.ipynb`
