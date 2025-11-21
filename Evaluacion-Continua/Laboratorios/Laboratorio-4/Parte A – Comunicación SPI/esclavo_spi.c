#include <DHT.h>
#include <LiquidCrystal_I2C.h>
#include <SPI.h>
#include <Wire.h>

// ---------------- Pines ----------------
#define DHTPIN 2 // DHT11 DATA
#define DHTTYPE DHT11
#define LDR_PIN A0
#define BUTTON_PIN 3
#define SS_SLAVE_PIN 10 // SS DEL ESCLAVO (CONECTADO)

// LCD
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Objeto DHT
DHT dht(DHTPIN, DHTTYPE);

// Umbrales
const float TEMP_UMBRAL = 23.6; // temperatura para LED temp
const int LDR_UMBRAL = 1100;    // umbral para luz baja (ajustalo después)

void setup() {
  // LCD
  Wire.begin();
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Iniciando...");

  // DHT11
  dht.begin();

  // Botón
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  // SPI maestro
  pinMode(SS_SLAVE_PIN, OUTPUT);
  digitalWrite(SS_SLAVE_PIN, HIGH);
  SPI.begin();

  delay(1500);
}

void loop() {
  // ---------------- Lecturas ----------------
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();
  int luz = analogRead(LDR_PIN);
  bool botonPulsado = (digitalRead(BUTTON_PIN) == LOW);

  // Manejo de error
  if (isnan(temp) || isnan(hum)) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Error DHT11");
    delay(1000);
    return;
  }

  // ---------------- LCD ----------------
  lcd.clear();

  // Fila 1
  lcd.setCursor(0, 0);
  lcd.print("T:");
  lcd.print(temp, 1);
  lcd.print("C ");
  lcd.print("L:");
  lcd.print(luz);

  // Fila 2
  lcd.setCursor(0, 1);
  lcd.print("H:");
  lcd.print(hum, 0);
  lcd.print("% B:");
  lcd.print(botonPulsado ? "1" : "0");

  // ---------------- Comando SPI ----------------
  byte comando = 0;

  if (temp > TEMP_UMBRAL)
    comando |= 0b00000001; // Bit 0 -> LED temperatura
  if (luz < LDR_UMBRAL)
    comando |= 0b00000010; // Bit 1 -> LED luz baja
  if (botonPulsado)
    comando |= 0b00000100; // Bit 2 -> buzzer

  // Enviar al esclavo
  digitalWrite(SS_SLAVE_PIN, LOW);
  SPI.transfer(comando);
  digitalWrite(SS_SLAVE_PIN, HIGH);

  delay(1000);
}
