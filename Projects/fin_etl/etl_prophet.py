import os, json, datetime as dt
from google.cloud import firestore
from prophet import Prophet          
import pandas as pd

FORECAST_DAYS   = 30
MIN_ROWS_PER_CAT = 10
LOOKBACK_DAYS   = 180                 # 6 months of history
FIRESTORE = firestore.Client()

def load_user_series(uid: str, since: dt.date) -> pd.DataFrame:
    """
    Read users/<uid>/transactions/* docs
    and return DataFrame with ['ds','y','category'] for Prophet.
    """
    tx_ref = (
        FIRESTORE.collection("users")
                 .document(uid)
                 .collection("transactions")
    )
    docs = tx_ref.where("createdAt", ">", since).stream()

    rows = []
    for d in docs:
        t = d.to_dict()
        rows.append(
            {
                "ds": t["createdAt"].isoformat(),   # Prophet wants str/ts
                "y" : float(t["amount"]),
                "category": t.get("catName", "unknown")
            }
        )
    return pd.DataFrame(rows)

def forecast_category(df_cat: pd.DataFrame) -> float:
    """Return total forecast for next 30 days for one category."""
    model = Prophet(
        daily_seasonality=False,
        weekly_seasonality=True,
        yearly_seasonality=False,
    )
    model.fit(df_cat[["ds", "y"]])
    future  = model.make_future_dataframe(periods=FORECAST_DAYS)
    fcst_30 = model.predict(future).tail(FORECAST_DAYS)
    return float(fcst_30["yhat"].sum())

def write_forecast(uid: str, payload: dict) -> None:
    """ai-forecast/<uid>/daily/<YYYY-MM-DD> = payload"""
    today = dt.date.today().isoformat()
    (
        FIRESTORE.collection("ai-forecast")
                 .document(uid)
                 .collection("daily")
                 .document(today)
                 .set(payload)
    )
    print(f"WROTE ai-forecast/{uid}/daily/{today}")

def run_single_user(uid: str) -> None:
    since = dt.date.today() - dt.timedelta(days=LOOKBACK_DAYS)
    raw   = load_user_series(uid, since)
    if raw.empty:
        print("SKIP", uid, "(no transactions)")
        return

    out = {
        "uid": uid,
        "generated_at": dt.datetime.utcnow().isoformat(),
        "forecast": {},
    }

    for cat, df_cat in raw.groupby("category"):
        if len(df_cat) < MIN_ROWS_PER_CAT:
            continue
        out["forecast"][cat] = forecast_category(df_cat)

    write_forecast(uid, out)

def main():
    uids = [d.id for d in FIRESTORE.collection("users").stream()]
    for uid in uids:
        try:
            run_single_user(uid)
        except Exception as e:
            print("ERROR", uid, e)

if __name__ == "__main__":
    main()
