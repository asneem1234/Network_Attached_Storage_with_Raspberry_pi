# Smart IoT Data Collection Hub Setup

This guide will walk you through setting up the Raspberry Pi Smart NAS as an intelligent central data collection hub with AI-powered analysis capabilities for IoT devices in a smart home environment.

## Overview

The Smart IoT Data Collection Hub demo showcases how our Raspberry Pi solution with AI capabilities can serve as a local storage, processing, and analysis center for various smart home sensors and devices. The system intelligently organizes incoming data, automatically detects patterns and anomalies, generates insights, and provides visualizations - all while eliminating dependency on cloud services and providing unlimited historical data retention.

## Prerequisites

- Raspberry Pi NAS set up and running
- At least one IoT device (another Raspberry Pi with sensors or ESP8266/ESP32)
- Basic understanding of MQTT protocol
- Sample visualization tools

## Setup Instructions

### 1. Install MQTT Broker

The MQTT protocol is ideal for IoT communications due to its lightweight nature:

```bash
# Log in to your Raspberry Pi NAS
ssh pi@<NAS-IP-ADDRESS>

# Install Mosquitto MQTT broker
sudo apt update
sudo apt install -y mosquitto mosquitto-clients

# Configure Mosquitto for authentication
sudo nano /etc/mosquitto/mosquitto.conf
```

Add the following to the configuration file:

```
# MQTT Configuration
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
```

Create a password file:

```bash
# Create a user (e.g., 'iotuser')
sudo mosquitto_passwd -c /etc/mosquitto/passwd iotuser
# Enter password when prompted

# Restart Mosquitto
sudo systemctl restart mosquitto
sudo systemctl enable mosquitto
```

### 2. Create Data Storage Structure

Set up a structured storage system for IoT data:

```bash
# Create IoT data directory
sudo mkdir -p /mnt/nasdata/iotdata/{raw,processed,archive,config}
sudo mkdir -p /mnt/nasdata/iotdata/raw/{temperature,humidity,motion,energy,water}
sudo chmod -R 775 /mnt/nasdata/iotdata
sudo chown -R pi:pi /mnt/nasdata/iotdata
```

### 3. Install Data Collection Scripts

Create a Python script to collect data from MQTT and store it:

```bash
# Install required packages
sudo apt install -y python3-pip
pip3 install paho-mqtt pandas

# Create the data collection script
cat << 'EOF' > /home/pi/mqtt_data_collector.py
#!/usr/bin/env python3

import paho.mqtt.client as mqtt
import json
import time
import os
import pandas as pd
from datetime import datetime

# Configuration
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_USER = "iotuser"
MQTT_PASSWORD = "your_password"  # Replace with actual password
DATA_DIR = "/mnt/nasdata/iotdata/raw"
TOPICS = [
    "home/sensors/temperature/#",
    "home/sensors/humidity/#",
    "home/sensors/motion/#",
    "home/sensors/energy/#",
    "home/sensors/water/#"
]

# Callback when connecting to the MQTT broker
def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")
    for topic in TOPICS:
        client.subscribe(topic)
    print(f"Subscribed to topics: {TOPICS}")

# Callback when a message is received
def on_message(client, userdata, msg):
    try:
        # Parse the message
        payload = msg.payload.decode('utf-8')
        topic_parts = msg.topic.split('/')
        sensor_type = topic_parts[2]
        
        # Try to parse as JSON
        try:
            data = json.loads(payload)
        except json.JSONDecodeError:
            data = {"value": payload, "raw": True}
        
        # Add metadata
        data['timestamp'] = datetime.now().isoformat()
        data['topic'] = msg.topic
        
        # Determine the file path
        date_str = datetime.now().strftime('%Y%m%d')
        file_dir = os.path.join(DATA_DIR, sensor_type)
        if not os.path.exists(file_dir):
            os.makedirs(file_dir)
        
        file_path = os.path.join(file_dir, f"{date_str}.csv")
        
        # Convert to DataFrame for easy CSV handling
        df = pd.DataFrame([data])
        
        # Append to CSV file
        if os.path.exists(file_path):
            df.to_csv(file_path, mode='a', header=False, index=False)
        else:
            df.to_csv(file_path, mode='w', header=True, index=False)
            
        print(f"Data saved: {msg.topic} -> {file_path}")
        
    except Exception as e:
        print(f"Error processing message: {e}")

# Set up MQTT client
client = mqtt.Client()
client.username_pw_set(MQTT_USER, MQTT_PASSWORD)
client.on_connect = on_connect
client.on_message = on_message

# Connect to the broker
client.connect(MQTT_BROKER, MQTT_PORT, 60)

# Start the loop
print("Starting MQTT data collection...")
client.loop_forever()
EOF

# Make the script executable
chmod +x /home/pi/mqtt_data_collector.py
```

### 4. Create a System Service

Set up the data collector as a system service:

```bash
# Create a service file
sudo nano /etc/systemd/system/mqtt-collector.service
```

Add the following content:

```
[Unit]
Description=MQTT Data Collector
After=network.target mosquitto.service

[Service]
ExecStart=/usr/bin/python3 /home/pi/mqtt_data_collector.py
WorkingDirectory=/home/pi
StandardOutput=inherit
StandardError=inherit
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl enable mqtt-collector
sudo systemctl start mqtt-collector
```

### 5. Set up Data Processing and Aggregation

Create a script to process and aggregate raw data:

```bash
cat << 'EOF' > /home/pi/process_iot_data.py
#!/usr/bin/env python3

import pandas as pd
import os
import glob
from datetime import datetime, timedelta

# Configuration
RAW_DATA_DIR = "/mnt/nasdata/iotdata/raw"
PROCESSED_DIR = "/mnt/nasdata/iotdata/processed"
SENSOR_TYPES = ["temperature", "humidity", "motion", "energy", "water"]

def process_data(sensor_type, date_str):
    try:
        # File paths
        raw_file = os.path.join(RAW_DATA_DIR, sensor_type, f"{date_str}.csv")
        processed_dir = os.path.join(PROCESSED_DIR, sensor_type)
        if not os.path.exists(processed_dir):
            os.makedirs(processed_dir)
        
        # Check if raw file exists
        if not os.path.exists(raw_file):
            print(f"No data for {sensor_type} on {date_str}")
            return False
        
        # Read the raw data
        df = pd.read_csv(raw_file)
        
        # Convert timestamp to datetime
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        
        # Resample data for hourly statistics
        if 'value' in df.columns:
            # If value exists, use it for aggregation
            df['value'] = pd.to_numeric(df['value'], errors='coerce')
            
            # Group by hour
            hourly = df.set_index('timestamp').resample('H')
            
            # Create hourly statistics
            hourly_stats = pd.DataFrame({
                'mean': hourly['value'].mean(),
                'min': hourly['value'].min(),
                'max': hourly['value'].max(),
                'count': hourly['value'].count()
            }).reset_index()
            
            # Save hourly data
            hourly_file = os.path.join(processed_dir, f"{date_str}_hourly.csv")
            hourly_stats.to_csv(hourly_file, index=False)
            
            # Create daily summary
            daily_stats = {
                'date': date_str,
                'mean': df['value'].mean(),
                'min': df['value'].min(),
                'max': df['value'].max(),
                'count': df['value'].count(),
                'sensor_type': sensor_type
            }
            
            # Save daily summary
            daily_file = os.path.join(processed_dir, f"{date_str}_summary.csv")
            pd.DataFrame([daily_stats]).to_csv(daily_file, index=False)
            
            print(f"Processed {sensor_type} data for {date_str}")
            return True
        else:
            print(f"No 'value' column in {sensor_type} data for {date_str}")
            return False
    
    except Exception as e:
        print(f"Error processing {sensor_type} data for {date_str}: {e}")
        return False

# Process yesterday's data
yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y%m%d')
for sensor in SENSOR_TYPES:
    process_data(sensor, yesterday)
EOF

# Make the script executable
chmod +x /home/pi/process_iot_data.py

# Schedule it to run daily
(crontab -l 2>/dev/null; echo "5 0 * * * /home/pi/process_iot_data.py") | crontab -
```

### 6. Install Simple Visualization

Set up a basic web dashboard:

```bash
# Install web server and PHP
sudo apt install -y apache2 php libapache2-mod-php php-sqlite3

# Create a directory for the dashboard
sudo mkdir -p /var/www/html/iotdashboard
sudo chown -R pi:www-data /var/www/html/iotdashboard

# Create a simple PHP dashboard
cat << 'EOF' > /var/www/html/iotdashboard/index.php
<!DOCTYPE html>
<html>
<head>
    <title>IoT Data Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .card { border: 1px solid #ddd; border-radius: 5px; padding: 15px; margin: 10px 0; }
        .sensor-data { display: flex; flex-wrap: wrap; }
        .sensor-card { width: 300px; margin: 10px; padding: 15px; border: 1px solid #ccc; border-radius: 5px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; }
        th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
        tr:nth-child(even) { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>IoT Data Dashboard</h1>
    
    <?php
    // Configuration
    $processed_dir = '/mnt/nasdata/iotdata/processed';
    $sensor_types = ['temperature', 'humidity', 'motion', 'energy', 'water'];
    $date = isset($_GET['date']) ? $_GET['date'] : date('Ymd', strtotime('-1 day'));
    
    echo "<div class='card'>";
    echo "<h2>Data for " . date('Y-m-d', strtotime($date)) . "</h2>";
    echo "<form method='get'>";
    echo "<input type='date' name='date' value='" . date('Y-m-d', strtotime($date)) . "' onchange='this.form.submit()'>";
    echo "</form>";
    echo "</div>";
    
    echo "<div class='sensor-data'>";
    
    foreach ($sensor_types as $sensor) {
        $summary_file = $processed_dir . '/' . $sensor . '/' . $date . '_summary.csv';
        $hourly_file = $processed_dir . '/' . $sensor . '/' . $date . '_hourly.csv';
        
        echo "<div class='sensor-card'>";
        echo "<h2>" . ucfirst($sensor) . " Data</h2>";
        
        if (file_exists($summary_file)) {
            $summary = array_map('str_getcsv', file($summary_file));
            $header = array_shift($summary);
            $data = $summary[0];
            
            echo "<table>";
            echo "<tr><th>Metric</th><th>Value</th></tr>";
            echo "<tr><td>Average</td><td>" . $data[array_search('mean', $header)] . "</td></tr>";
            echo "<tr><td>Minimum</td><td>" . $data[array_search('min', $header)] . "</td></tr>";
            echo "<tr><td>Maximum</td><td>" . $data[array_search('max', $header)] . "</td></tr>";
            echo "<tr><td>Readings</td><td>" . $data[array_search('count', $header)] . "</td></tr>";
            echo "</table>";
            
            if (file_exists($hourly_file)) {
                echo "<h3>Hourly Data</h3>";
                echo "<table>";
                echo "<tr><th>Hour</th><th>Avg</th><th>Min</th><th>Max</th></tr>";
                
                $hourly_data = array_map('str_getcsv', file($hourly_file));
                $hourly_header = array_shift($hourly_data);
                
                foreach ($hourly_data as $row) {
                    $hour = date('H:i', strtotime($row[array_search('timestamp', $hourly_header)]));
                    echo "<tr>";
                    echo "<td>" . $hour . "</td>";
                    echo "<td>" . round($row[array_search('mean', $hourly_header)], 1) . "</td>";
                    echo "<td>" . round($row[array_search('min', $hourly_header)], 1) . "</td>";
                    echo "<td>" . round($row[array_search('max', $hourly_header)], 1) . "</td>";
                    echo "</tr>";
                }
                
                echo "</table>";
            }
        } else {
            echo "<p>No data available for this date</p>";
        }
        
        echo "</div>";
    }
    
    echo "</div>";
    ?>
</body>
</html>
EOF

# Set proper permissions
sudo chown pi:www-data /var/www/html/iotdashboard/index.php
sudo chmod 644 /var/www/html/iotdashboard/index.php
```

### 7. IoT Sensor Setup (Example with ESP8266)

To demonstrate the IoT data collection, here's a simple ESP8266 sensor code:

```cpp
// ESP8266 Temperature and Humidity Sensor with MQTT
// Save this to Arduino IDE and flash to an ESP8266 with DHT22 sensor

#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

// WiFi and MQTT configuration
const char* ssid = "YourWiFiName";
const char* password = "YourWiFiPassword";
const char* mqtt_server = "192.168.1.100";  // NAS IP
const int mqtt_port = 1883;
const char* mqtt_user = "iotuser";
const char* mqtt_password = "your_password";
const char* client_id = "esp8266-sensor1";

// Sensor configuration
#define DHTPIN 2        // Digital pin connected to the DHT sensor
#define DHTTYPE DHT22   // DHT 22 (AM2302)
DHT dht(DHTPIN, DHTTYPE);

// MQTT topics
const char* temp_topic = "home/sensors/temperature/livingroom";
const char* humidity_topic = "home/sensors/humidity/livingroom";

// Setup WiFi and MQTT clients
WiFiClient espClient;
PubSubClient client(espClient);

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect(client_id, mqtt_user, mqtt_password)) {
      Serial.println("connected");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  dht.begin();
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Read temperature and humidity
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  // Check if any reads failed
  if (isnan(h) || isnan(t)) {
    Serial.println("Failed to read from DHT sensor!");
    delay(2000);
    return;
  }

  // Create JSON document for temperature
  StaticJsonDocument<128> temp_doc;
  temp_doc["value"] = t;
  temp_doc["unit"] = "°C";
  temp_doc["sensor_id"] = "DHT22_1";
  temp_doc["location"] = "livingroom";
  
  // Serialize JSON to string
  char temp_buffer[128];
  serializeJson(temp_doc, temp_buffer);
  
  // Create JSON document for humidity
  StaticJsonDocument<128> hum_doc;
  hum_doc["value"] = h;
  hum_doc["unit"] = "%";
  hum_doc["sensor_id"] = "DHT22_1";
  hum_doc["location"] = "livingroom";
  
  // Serialize JSON to string
  char hum_buffer[128];
  serializeJson(hum_doc, hum_buffer);

  // Publish to MQTT
  client.publish(temp_topic, temp_buffer);
  client.publish(humidity_topic, hum_buffer);
  
  Serial.print("Temperature: ");
  Serial.print(t);
  Serial.println(" °C");
  Serial.print("Humidity: ");
  Serial.print(h);
  Serial.println(" %");

  // Wait 30 seconds
  delay(30000);
}
```

### 8. Data Retention and Archiving

Create a script to manage data retention and archiving:

```bash
cat << 'EOF' > /home/pi/archive_iot_data.py
#!/usr/bin/env python3

import os
import shutil
import datetime
import gzip

# Configuration
RAW_DATA_DIR = "/mnt/nasdata/iotdata/raw"
PROCESSED_DIR = "/mnt/nasdata/iotdata/processed"
ARCHIVE_DIR = "/mnt/nasdata/iotdata/archive"
SENSOR_TYPES = ["temperature", "humidity", "motion", "energy", "water"]

# Archive data older than 30 days
def archive_old_data():
    today = datetime.datetime.now()
    archive_cutoff = today - datetime.timedelta(days=30)
    
    for sensor in SENSOR_TYPES:
        # Archive raw data
        raw_sensor_dir = os.path.join(RAW_DATA_DIR, sensor)
        if os.path.exists(raw_sensor_dir):
            for file in os.listdir(raw_sensor_dir):
                if file.endswith('.csv'):
                    try:
                        # Get date from filename (YYYYMMDD.csv)
                        file_date = datetime.datetime.strptime(file.split('.')[0], '%Y%m%d')
                        
                        # Check if file is older than cutoff
                        if file_date < archive_cutoff:
                            # Create archive directory structure
                            year_month = file_date.strftime('%Y-%m')
                            archive_path = os.path.join(ARCHIVE_DIR, sensor, year_month)
                            if not os.path.exists(archive_path):
                                os.makedirs(archive_path)
                            
                            # Compress and move file
                            src_file = os.path.join(raw_sensor_dir, file)
                            dst_file = os.path.join(archive_path, file + '.gz')
                            
                            with open(src_file, 'rb') as f_in:
                                with gzip.open(dst_file, 'wb') as f_out:
                                    shutil.copyfileobj(f_in, f_out)
                            
                            # Remove original file
                            os.remove(src_file)
                            print(f"Archived: {src_file} -> {dst_file}")
                    except Exception as e:
                        print(f"Error archiving {file}: {e}")
        
        # Archive processed data
        proc_sensor_dir = os.path.join(PROCESSED_DIR, sensor)
        if os.path.exists(proc_sensor_dir):
            for file in os.listdir(proc_sensor_dir):
                if '_summary.csv' in file or '_hourly.csv' in file:
                    try:
                        # Get date from filename (YYYYMMDD_summary.csv or YYYYMMDD_hourly.csv)
                        date_part = file.split('_')[0]
                        file_date = datetime.datetime.strptime(date_part, '%Y%m%d')
                        
                        # Check if file is older than cutoff
                        if file_date < archive_cutoff:
                            # Create archive directory structure
                            year_month = file_date.strftime('%Y-%m')
                            archive_path = os.path.join(ARCHIVE_DIR, 'processed', sensor, year_month)
                            if not os.path.exists(archive_path):
                                os.makedirs(archive_path)
                            
                            # Compress and move file
                            src_file = os.path.join(proc_sensor_dir, file)
                            dst_file = os.path.join(archive_path, file + '.gz')
                            
                            with open(src_file, 'rb') as f_in:
                                with gzip.open(dst_file, 'wb') as f_out:
                                    shutil.copyfileobj(f_in, f_out)
                            
                            # Remove original file
                            os.remove(src_file)
                            print(f"Archived: {src_file} -> {dst_file}")
                    except Exception as e:
                        print(f"Error archiving {file}: {e}")

if __name__ == "__main__":
    archive_old_data()
EOF

# Make the script executable
chmod +x /home/pi/archive_iot_data.py

# Schedule it to run weekly
(crontab -l 2>/dev/null; echo "0 2 * * 0 /home/pi/archive_iot_data.py") | crontab -
```

## Demo Preparation

1. Set up a sample IoT device (like the ESP8266 with a temperature sensor)
2. Generate and collect sample data for a few days before the demo
3. Prepare visualizations of the collected data
4. Create a comparison with cloud-based IoT solutions

## IoT Data Analysis Example

Create a simple analysis script for the demo:

```bash
cat << 'EOF' > /home/pi/analyze_temperature.py
#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import os
import glob
from datetime import datetime, timedelta

# Configuration
PROCESSED_DIR = "/mnt/nasdata/iotdata/processed/temperature"
OUTPUT_DIR = "/var/www/html/iotdashboard/images"

# Ensure output directory exists
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

# Get data from the last 7 days
end_date = datetime.now().date()
start_date = end_date - timedelta(days=7)

# Prepare to collect data
all_data = []

# Loop through each day
current_date = start_date
while current_date <= end_date:
    date_str = current_date.strftime('%Y%m%d')
    hourly_file = os.path.join(PROCESSED_DIR, f"{date_str}_hourly.csv")
    
    if os.path.exists(hourly_file):
        df = pd.read_csv(hourly_file)
        df['date'] = current_date.strftime('%Y-%m-%d')
        all_data.append(df)
    
    current_date += timedelta(days=1)

# If we have data, create a chart
if all_data:
    # Combine all data
    combined_data = pd.concat(all_data)
    combined_data['timestamp'] = pd.to_datetime(combined_data['timestamp'])
    
    # Create the plot
    plt.figure(figsize=(12, 6))
    plt.plot(combined_data['timestamp'], combined_data['mean'], 'b-', label='Average')
    plt.fill_between(combined_data['timestamp'], combined_data['min'], combined_data['max'], 
                     color='blue', alpha=0.2, label='Min-Max Range')
    
    plt.title('Temperature Over the Last 7 Days')
    plt.xlabel('Date')
    plt.ylabel('Temperature (°C)')
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.legend()
    
    # Save the figure
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'temperature_week.png'))
    print(f"Chart saved to {os.path.join(OUTPUT_DIR, 'temperature_week.png')}")
else:
    print("No data available for the last 7 days")
EOF

# Make the script executable
chmod +x /home/pi/analyze_temperature.py
```

## Cost Savings Analysis

| Solution | Initial Cost | Annual Cost | 5-Year Total |
|----------|--------------|-------------|--------------|
| Raspberry Pi NAS IoT Hub | ₹5,820 | ₹0 | ₹5,820 |
| Cloud IoT Platform (Basic) | ₹0 | ₹3,600 | ₹18,000 |
| Commercial IoT Gateway | ₹8,000 | ₹1,200 | ₹14,000 |
| **Savings vs. Cloud** | | | **₹12,180** |
| **Savings vs. Commercial** | | | **₹8,180** |

## Advantages to Highlight

1. **Data Privacy**: All data stays on your local network
2. **No Internet Dependency**: Continues working during internet outages
3. **Unlimited Storage**: No data retention limitations or additional costs
4. **Customizability**: Fully customizable data collection and processing
5. **Integration Flexibility**: Works with various IoT protocols and devices
6. **Cost Efficiency**: No subscription fees or per-device costs
7. **Historical Data**: Keep years of data at no additional cost

## Troubleshooting

- **MQTT Connection Issues**: Check broker status and credentials
- **Missing Data**: Verify sensor connectivity and MQTT topics
- **Processing Errors**: Check log files for Python script errors
- **Visualization Problems**: Verify web server configuration and PHP settings
