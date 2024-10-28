#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#define REG_FIFO_DATA        0x07
#define REG_MODE_CONFIG      0x09
#define REG_SPO2_CONFIG      0x0A
#define REG_LED_RED          0x0C
#define REG_LED_IR           0x0D
#define REG_PART_ID          0xFF
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_ADDR 0x3C 
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
unsigned long previousMillis = 0;
const long interval = 30000;  
long totalRedValue = 0;
long totalIRValue = 0;
int count = 0;
void setup() {
  Serial.begin(9600); 
  if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println(F("SSD1306 allocation failed"));
    for (;;); 
  }
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("ECG Monitoring");
  display.display();
  delay(2000); 
  display.clearDisplay();
  Wire.begin();
  max30102_setup();
  byte partID = read_max30102_register(REG_PART_ID);
  Serial.print("Part ID: 0x");
  Serial.println(partID, HEX);
  if (partID != 0x15) {
    Serial.println("Error: Incorrect Part ID. Sensor is not connected properly.");
  } else {
    Serial.println("Sensor is correctly initialized.");
  }
}
void loop() {
  int ecgValue = analogRead(A1);  
  Serial.println(ecgValue);      
  delay(1);
  long redValue = read_max30102_data();  
  long irValue = read_max30102_data();   
  if (redValue < 50000 || irValue < 50000) {
    Serial.println("No finger detected or values too low.");
  } else {
    totalRedValue += redValue;
    totalIRValue += irValue;
    count++;
    unsigned long currentMillis = millis();
    if (currentMillis - previousMillis >= interval) {
      float averageSpO2 = calculateSpO2(totalRedValue / count, totalIRValue / count);
      Serial.print("Average SpO2 over 30 seconds: ");
      Serial.print(averageSpO2);
      Serial.println(" %");
      if (Serial.available() > 0) {
        String receivedData = Serial.readString();
        int pulseRateStart = receivedData.indexOf("Pulse Rate: ") + 12;
        int pulseRateEnd = receivedData.indexOf(" BPM");
        int predictionStart = receivedData.indexOf("Prediction: ") + 12;
        
        float pulseRate = receivedData.substring(pulseRateStart, pulseRateEnd).toFloat();
        String prediction = receivedData.substring(predictionStart);
        display.clearDisplay();
        drawHeart();
        displayHeartRate(averageSpO2, prediction, pulseRate); 
        display.display();
        totalRedValue = 0;
        totalIRValue = 0;
        count = 0;
        previousMillis = currentMillis;
      }
    }
  }
  delay(100);
}
void max30102_setup() {
  delay(500);  
  write_max30102_register(REG_MODE_CONFIG, 0x40); 
  delay(100);
  write_max30102_register(REG_MODE_CONFIG, 0x03);
  write_max30102_register(REG_SPO2_CONFIG, 0x27);
  write_max30102_register(REG_LED_RED, 0xFF);
  write_max30102_register(REG_LED_IR, 0xFF);
  Serial.println("MAX30102 initialized");
}
long read_max30102_data() {
  Wire.beginTransmission(0x57);
  Wire.write(REG_FIFO_DATA);
  Wire.endTransmission(false);
  Wire.requestFrom(0x57, 6);
  long redValue = ((long)Wire.read() << 16) | ((long)Wire.read() << 8) | (long)Wire.read();
  long irValue = ((long)Wire.read() << 16) | ((long)Wire.read() << 8) | (long)Wire.read();
  return redValue; 
}
void write_max30102_register(byte reg, byte value) {
  Wire.beginTransmission(0x57);
  Wire.write(reg);
  Wire.write(value);
  Wire.endTransmission();
}
byte read_max30102_register(byte reg) {
  Wire.beginTransmission(0x57);
  Wire.write(reg);
  Wire.endTransmission(false);
  Wire.requestFrom(0x57, 1);
  return Wire.read();
}
float calculateSpO2(long redValue, long irValue) {
  if (irValue == 0) {
    return 0.0;
  }
  float SpO2 = 110 - (25 * ((float)redValue / (float)irValue));
  return SpO2;
}
void drawHeart() {
  display.fillCircle(15, 15, 10, SSD1306_WHITE);
  display.fillCircle(35, 15, 10, SSD1306_WHITE);
  display.fillTriangle(5, 15, 45, 15, 25, 30, SSD1306_WHITE);
}
void displayHeartRate(float spO2, String prediction, float pulseRate) {
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.print("SpO2: ");
  display.print(spO2);
  display.println(" %");
  display.setCursor(0, 20);
  display.print("Pulse Rate: ");
  display.print(pulseRate);
  display.println(" BPM");
  display.setCursor(0, 40); 
  display.print("Prediction: ");
  display.print(prediction); 
}
