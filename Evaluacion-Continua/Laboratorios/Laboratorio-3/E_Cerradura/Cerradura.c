#include <EEPROM.h>
#include <LiquidCrystal_I2C.h>
#include <MFRC522.h>
#include <SPI.h>
#include <Wire.h>

// Pines del RC522
#define RST_PIN 9
#define SS_PIN 10

// Pines de botones
#define BTN_BORRAR 3 // Botón Borrar
#define BTN_ACTUAL 4 // Botón Actualizar

// Pines de LEDs
#define LED_ROJO 5  // LED acceso denegado
#define LED_VERDE 6 // LED acceso permitido

// Instancias de librerías
MFRC522 rfid(SS_PIN, RST_PIN);
LiquidCrystal_I2C lcd(0x27, 16, 2);

int intentos = 0; // Contador de intentos fallidos

void setup() {
  // Configurar pines
  pinMode(BTN_BORRAR, INPUT);
  pinMode(BTN_ACTUAL, INPUT);
  pinMode(LED_ROJO, OUTPUT);
  pinMode(LED_VERDE, OUTPUT);
  digitalWrite(LED_ROJO, LOW);
  digitalWrite(LED_VERDE, LOW);

  // Iniciar SPI y lector RC522
  SPI.begin();
  rfid.PCD_Init();

  // Iniciar LCD
  lcd.init();
  lcd.backlight();

  // Leer EEPROM para ver si ya hay tarjeta registrada
  byte storedSize = EEPROM.read(0);
  if (storedSize < 1 || storedSize > 10) {
    // No hay tarjeta registrada: pedimos registro inicial
    lcd.setCursor(0, 0);
    lcd.print("Registrar Tarjeta");
    unsigned long inicio = millis();
    // Esperar hasta 10 segundos para escanear una tarjeta
    while (millis() - inicio < 10000) {
      if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
        // Leer UID de la tarjeta y guardarlo en EEPROM
        byte len = rfid.uid.size; // longitud del UID leído
        EEPROM.write(0, len);
        for (byte i = 0; i < len; i++) {
          EEPROM.write(i + 1, rfid.uid.uidByte[i]);
        }
        lcd.clear();
        lcd.print("Tarjeta guardada");
        delay(2000);
        break;
      }
    }
    lcd.clear(); // Limpia mensaje después del tiempo de espera
  } else {
    // Ya existía una tarjeta en EEPROM; continúa normal
    lcd.clear();
  }
}

void loop() {
  // Manejo del botón BORRAR: eliminar tarjeta registrada
  if (digitalRead(BTN_BORRAR) == HIGH) {
    delay(50); // pequeño debounce
    if (digitalRead(BTN_BORRAR) == HIGH) {
      // Esperar a soltar el botón
      while (digitalRead(BTN_BORRAR) == HIGH)
        ;
      EEPROM.write(0, 0); // marcar "sin tarjeta"
      lcd.clear();
      lcd.print("Tarjeta eliminada");
      delay(2000);
      lcd.clear();
      intentos = 0;
    }
  }

  // Manejo del botón ACTUALIZAR: registrar nueva tarjeta
  if (digitalRead(BTN_ACTUAL) == HIGH) {
    delay(50);
    if (digitalRead(BTN_ACTUAL) == HIGH) {
      while (digitalRead(BTN_ACTUAL) == HIGH)
        ;
      lcd.clear();
      lcd.print("Presente tarjeta");
      // Esperar indefinidamente hasta leer tarjeta
      while (!(rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()))
        ;
      // Guardar nuevo UID en EEPROM
      byte len = rfid.uid.size;
      EEPROM.write(0, len);
      for (byte i = 0; i < len; i++) {
        EEPROM.write(i + 1, rfid.uid.uidByte[i]);
      }
      lcd.clear();
      lcd.print("Tarjeta guardada");
      delay(2000);
      lcd.clear();
      intentos = 0;
      rfid.PICC_HaltA();
    }
  }

  // Lectura de tarjeta RFID presente
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    byte storedSize = EEPROM.read(0);
    bool match = true;
    if (storedSize == rfid.uid.size && storedSize >= 1) {
      // Comparar byte a byte con EEPROM
      for (byte i = 0; i < storedSize; i++) {
        if (EEPROM.read(i + 1) != rfid.uid.uidByte[i]) {
          match = false;
          break;
        }
      }
    } else {
      match = false;
    }
    if (match) {
      // Acceso permitido
      intentos = 0;
      lcd.clear();
      lcd.print("Acceso permitido");
      digitalWrite(LED_VERDE, HIGH);
      delay(2000);
      digitalWrite(LED_VERDE, LOW);
      lcd.clear();
    } else {
      // Acceso denegado
      intentos++;
      lcd.clear();
      lcd.print("Acceso denegado");
      digitalWrite(LED_ROJO, HIGH);
      delay(2000);
      digitalWrite(LED_ROJO, LOW);
      // Si 3 intentos fallidos, bloqueamos 10 s
      if (intentos >= 3) {
        lcd.clear();
        lcd.print("Bloqueado");
        delay(10000);
        lcd.clear();
        intentos = 0;
      }
    }
    rfid.PICC_HaltA(); // Finalizar lectura
  }
}
