
import pandas as pd
import numpy as np
from lightgbm import LGBMRegressor
import joblib


df = pd.read_csv("ParisTrain.csv")
df['date'] = pd.to_datetime(df['date'])
df['day'] = df['date'].dt.date


split_date = pd.to_datetime("2021-01-01")
train_df = df[df['date'] < split_date].copy()
val_df = df[df['date'] >= split_date].copy()

# Feature engineering

# 1. station_15min_avg_available
station_15min_avg = train_df.groupby(['Station', 'tod'])['Available'].mean().reset_index()
station_15min_avg.rename(columns={'Available': 'station_15min_avg_available'}, inplace=True)

# 2. station_dow_avg_available
station_dow_avg = train_df.groupby(['Station', 'dow'])['Available'].mean().reset_index()
station_dow_avg.rename(columns={'Available': 'station_dow_avg_available'}, inplace=True)

# 3. area_avg_available
area_avg = train_df.groupby('area')['Available'].mean().reset_index()
area_avg.rename(columns={'Available': 'area_avg_available'}, inplace=True)

# 4. EWA
daily_avg_train = train_df.groupby(['Station', 'day'])['Available'].mean().reset_index()
daily_avg_train = daily_avg_train.sort_values(['Station', 'day'])
daily_avg_train['station_smoothed_trend'] = daily_avg_train.groupby('Station')['Available'].transform(
    lambda x: x.shift(1).ewm(span=3, adjust=False).mean()
)
train_df = train_df.merge(
    daily_avg_train[['Station', 'day', 'station_smoothed_trend']],
    on=['Station', 'day'], how='left'
)

combined = pd.concat([train_df[['Station', 'day', 'Available']], val_df[['Station', 'day', 'Available']]])
combined = combined.sort_values(['Station', 'day'])


daily_avg_all = combined.groupby(['Station', 'day'])['Available'].mean().reset_index()
daily_avg_all = daily_avg_all.sort_values(['Station', 'day'])

# EWA
daily_avg_all['station_smoothed_trend'] = daily_avg_all.groupby('Station')['Available'].transform(
    lambda x: x.shift(1).ewm(span=3, adjust=False).mean()
)


ewa_val = daily_avg_all[daily_avg_all['day'].isin(val_df['day'])]

# Merge
val_df = val_df.merge(
    ewa_val[['Station', 'day', 'station_smoothed_trend']],
    on=['Station', 'day'], how='left'
)


train_df = train_df.merge(station_15min_avg, on=['Station', 'tod'], how='left')
train_df = train_df.merge(station_dow_avg, on=['Station', 'dow'], how='left')
train_df = train_df.merge(area_avg, on='area', how='left')

val_df = val_df.merge(station_15min_avg, on=['Station', 'tod'], how='left')
val_df = val_df.merge(station_dow_avg, on=['Station', 'dow'], how='left')
val_df = val_df.merge(area_avg, on='area', how='left')

# previous_available and previous_charging
combined_df = pd.concat([train_df, val_df], axis=0).sort_values(['Station', 'date'])
combined_df['previous_available'] = combined_df.groupby('Station')['Available'].shift(1)
combined_df['previous_charging'] = combined_df.groupby('Station')['Charging'].shift(1)
combined_df['previous_available'].fillna(combined_df['Available'], inplace=True)
combined_df['previous_charging'].fillna(0, inplace=True)


train_df = combined_df[combined_df['date'] < split_date].copy()
val_df = combined_df[combined_df['date'] >= split_date].copy()
val_df.dropna(subset=['station_smoothed_trend'], inplace=True)
train_df.dropna(subset=['station_smoothed_trend'], inplace=True)


for df in [train_df, val_df]:
    df['Station'] = df['Station'].astype(str)
    df['tod'] = df['tod'].astype(str)
    df['dow'] = df['dow'].astype(str)


station_cats = sorted(train_df['Station'].unique())  
tod_cats = sorted(train_df['tod'].unique())          
dow_cats = sorted(train_df['dow'].unique())          


for df in [train_df, val_df]:
    df['Station'] = pd.Categorical(df['Station'], categories=station_cats)
    df['tod'] = pd.Categorical(df['tod'], categories=tod_cats)
    df['dow'] = pd.Categorical(df['dow'], categories=dow_cats)



train_df['availability_rate'] = train_df['Available'] / 3
val_df['availability_rate'] = val_df['Available'] / 3



features = [
    'Station', 'tod', 'dow',
    'station_15min_avg_available',
    'station_dow_avg_available',
    'area_avg_available',
    'station_smoothed_trend',
    'previous_available',
    'previous_charging'
]

X_train = train_df[features]
y_train = train_df['availability_rate']


model = LGBMRegressor(
    n_estimators=100,
    learning_rate=0.1,
    random_state=42,
    categorical_feature=['Station', 'tod', 'dow']  
)
model.fit(X_train, y_train)

import joblib
joblib.dump(model, "lgbm_model.pkl")
