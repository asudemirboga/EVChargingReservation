import socket
import json
import joblib
import pandas as pd

# Load model and category info
model = joblib.load("lgbm_model.pkl")

with open("station_cats.json") as f:
    station_cats = json.load(f)

tod_cats = [str(i) for i in range(96)]
dow_cats = [str(i) for i in range(1, 8)]

FEATURES = [
    'Station', 'tod', 'dow',
    'station_15min_avg_available',
    'station_dow_avg_available',
    'area_avg_available',
    'station_smoothed_trend',
    'previous_available',
    'previous_charging'
]

def handle_request(data_json):
    try:
        data = json.loads(data_json)
        df = pd.DataFrame([data])
        df['Station'] = pd.Categorical(df['Station'], categories=station_cats)
        df['tod'] = pd.Categorical(df['tod'], categories=tod_cats)
        df['dow'] = pd.Categorical(df['dow'], categories=dow_cats)


        prediction = model.predict(df[FEATURES])[0]
        return json.dumps({'prediction': prediction})
    except Exception as e:
        return json.dumps({'error': str(e)})

# Start socket server
def run_server(host='', port=6000):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
        server_socket.bind((host, port))
        server_socket.listen(1)
        print(f" Server is listening on {host}:{port}...")

        while True:
            conn, addr = server_socket.accept()
            with conn:
                print(f"Connected by {addr}")
                data = conn.recv(4096).decode()
                if not data:
                    continue
                response = handle_request(data)
                print("Sending response:", response)
                conn.sendall(response.encode())

if __name__ == "__main__":
    run_server()
