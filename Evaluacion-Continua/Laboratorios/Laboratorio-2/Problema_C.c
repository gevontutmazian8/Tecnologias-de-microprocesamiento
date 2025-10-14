// Piano 8 teclas + 2 canciones UART ('C1'=Twinkle, 'C2'=Take On Me, 'S'=Stop)
// Botones activos en HIGH: D2..D9 (reposo LOW, presionado HIGH)
// Buzzer: D13  |  LED: D12
// Notas disponibles: 262, 294, 330, 349, 392, 440, 494, 523 Hz (Do4..Do5
// aprox.)

#include <Arduino.h>

// ---------------- Pines ----------------
const byte BTN[8] = {2, 3, 4, 5, 6, 7, 8, 9};
const byte BUZZ = 13;
const byte LEDPIN = 12;

// ---------------- Frecuencias ----------------
#define DO4 262
#define RE4 294
#define MI4 330
#define FA4 349
#define SOL4 392
#define LA4 440
#define SI4 494
#define DO5 523
#define REST 0

const int FREQ[8] = {DO4, RE4, MI4, FA4, SOL4, LA4, SI4, DO5};

// ---------------- Estado ----------------
enum Mode { PIANO, SONG };
Mode mode = PIANO;
volatile bool stopSong = false;

// ================== Canción 1: Twinkle Twinkle ==================
const int twinkleNotes[] = {DO4, DO4, SOL4, SOL4, LA4, LA4, SOL4, REST,
                            FA4, FA4, MI4,  MI4,  RE4, RE4, DO4};
const int twinkleDur[] = {400, 400, 400, 400, 400, 400, 800, 150,
                          400, 400, 400, 400, 400, 400, 800};
const int twinkleLen = sizeof(twinkleNotes) / sizeof(twinkleNotes[0]);

// ================== Canción 2: Take On Me (A-ha) ==================
const int takeOnMeNotes[] = {
    LA4,  LA4,  FA4,  RE4, REST, RE4, REST, MI4, REST, MI4,  REST,
    MI4,  SOL4, SOL4, LA4, SI4,  LA4, LA4,  LA4, MI4,  REST, RE4,
    REST, FA4,  REST, FA4, REST, FA4, MI4,  MI4, FA4,  MI4,  FA4,
    FA4,  FA4,  RE4,  DO4, REST, DO4, REST, MI4, REST, MI4,  REST,
    MI4,  SOL4, SOL4, LA4, SI4,  LA4, LA4,  LA4, MI4,  REST, RE4,
    REST, FA4,  REST, FA4, REST, FA4, MI4,  MI4, FA4,  MI4};
const int takeOnMeDur[] = {
    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200,
    200, 200, 200, 200, 200, 300, 200, 200, 200, 200, 200, 200, 200,
    200, 200, 200, 200, 200, 200, 200, 200, 300, 200, 200, 200, 200,
    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 300, 200,
    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 250, 600};
const int takeOnMeLen = sizeof(takeOnMeNotes) / sizeof(takeOnMeNotes[0]);

// ---------------- Funciones auxiliares ----------------
void playToneLed(int freq, int ms) {
  if (freq == REST) {
    noTone(BUZZ);
    digitalWrite(LEDPIN, LOW);
    delay(ms);
  } else {
    tone(BUZZ, freq);
    digitalWrite(LEDPIN, HIGH);
    delay(ms);
  }
  noTone(BUZZ);
  digitalWrite(LEDPIN, LOW);
}

void drainSerial() {
  while (Serial.available())
    Serial.read();
}

void playSong(const int *notes, const int *dur, int len, const char *songName) {
  stopSong = false;
  drainSerial();

  Serial.print(F("Reproduciendo: "));
  Serial.println(songName);

  for (int i = 0; i < len && !stopSong; i++) {
    // Permitir detener con 'S'
    if (Serial.available()) {
      char c = toupper(Serial.read());
      if (c == 'S') {
        stopSong = true;
        break;
      }
    }
    playToneLed(notes[i], dur[i]);
    delay(60); // separación entre notas
  }

  noTone(BUZZ);
  digitalWrite(LEDPIN, LOW);

  if (!stopSong) {
    Serial.print(F("Canción finalizada: "));
    Serial.println(songName);
  } else {
    Serial.print(F("Canción detenida: "));
    Serial.println(songName);
  }

  mode = PIANO;
}

// ---------------- Setup / Loop ----------------
void setup() {
  Serial.begin(9600);
  for (byte i = 0; i < 8; i++)
    pinMode(BTN[i], INPUT); // activos en HIGH
  pinMode(BUZZ, OUTPUT);
  pinMode(LEDPIN, OUTPUT);
  noTone(BUZZ);
  digitalWrite(LEDPIN, LOW);

  Serial.println(F("Piano listo"));
  Serial.println(F("  'C1' → Twinkle Twinkle"));
  Serial.println(F("  'C2' → Take On Me"));
  Serial.println(F("  'S' → Detener canción"));
  Serial.println(F("--------------------------------------------"));
}

void loop() {
  // Comandos UART
  if (Serial.available() >= 2) { // esperamos dos caracteres (C y número)
    char c1 = Serial.read();
    char c2 = Serial.read();
    c1 = toupper(c1);
    c2 = toupper(c2);

    if (c1 == 'C' && c2 == '1') {
      mode = SONG;
      playSong(twinkleNotes, twinkleDur, twinkleLen, "Twinkle Twinkle");
    } else if (c1 == 'C' && c2 == '2') {
      mode = SONG;
      playSong(takeOnMeNotes, takeOnMeDur, takeOnMeLen, "Take On Me");
    }
  }

  if (Serial.available()) { // si llega una sola letra (para stop)
    char s = toupper(Serial.read());
    if (s == 'S') {
      stopSong = true;
      mode = PIANO;
      noTone(BUZZ);
      digitalWrite(LEDPIN, LOW);
      Serial.println(F("Canción detenida manualmente"));
    }
  }

  // Modo piano
  if (mode == PIANO) {
    bool anyPressed = false;
    for (byte i = 0; i < 8; i++) {
      if (digitalRead(BTN[i]) == HIGH) { // HIGH = presionado
        tone(BUZZ, FREQ[i]);
        digitalWrite(LEDPIN, HIGH);
        anyPressed = true;
        break;
      }
    }
    if (!anyPressed) {
      noTone(BUZZ);
      digitalWrite(LEDPIN, LOW);
    }
    delay(10);
  }
}
