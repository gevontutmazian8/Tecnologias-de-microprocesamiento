#include <EEPROM.h>
#include <Keypad.h>
#include <LiquidCrystal_I2C.h>
#include <Wire.h>

// LCD I2C en 0x27
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Keypad 4x4: filas D2..D5, columnas D6..D9
const byte NF = 4, NC = 4;
char mapaTeclas[NF][NC] = {{'1', '2', '3', 'A'},
                           {'4', '5', '6', 'B'},
                           {'7', '8', '9', 'C'},
                           {'#', '0', '*', 'D'}};
byte pinFilas[NF] = {2, 3, 4, 5};    // salidas
byte pinColumnas[NC] = {6, 7, 8, 9}; // entradas pull-up
Keypad teclado = Keypad(makeKeymap(mapaTeclas), pinFilas, pinColumnas, NF, NC);

// Buzzer / LEDs
const byte PIN_BUZZER = 11;
const byte PIN_LED_OK = 12;
const byte PIN_LED_ERR = 13;

// Cerradura
const byte PWD_MIN = 4;
const byte PWD_MAX = 6; // máximo 6
const byte INTENTOS_MAX = 3;
const unsigned long T_ALARMA_MS = 5000;
const unsigned long T_DESBLOQ_MS = 2000;

// EEPROM: [0]='C' [1]=ver [2]=len [3..8]=digitos [9]=checksum
const int EE_BASE = 0;
const char EE_MAGIC = 'C';
const byte EE_VER = 1;

struct Clave {
  byte len;
  char d[PWD_MAX];
};

/* ==================== PROTOTIPOS ==================== */
void beep(uint16_t f = 2200, uint16_t ms = 80);
void lcd_centrar(const char *s, byte fila);
bool iguales(const char *a, byte la, const char *b, byte lb);
char leer_tecla_bloq(); // también loguea a Serial
bool ingresar_enmascarado(const char *prompt, char *out, byte &len, byte minL,
                          byte maxL);

void ui_ok();
void ui_error(byte restan);
void ui_alarma();
void mostrar_bienvenida();

uint8_t checksum(const Clave &c);
bool eeprom_leer(Clave &c);
void eeprom_guardar(const Clave &c);
void eeprom_init_si_falta();

void cambiar_contrasena();

/* ==================== FUNCIONES ==================== */
void beep(uint16_t f, uint16_t ms) {
  tone(PIN_BUZZER, f, ms);
  delay(ms + 5);
}

void lcd_centrar(const char *s, byte fila) {
  char buf[17];
  for (byte i = 0; i < 16; i++)
    buf[i] = ' ';
  buf[16] = 0;
  byte n = 0;
  while (s[n] && n < 16)
    n++;
  byte st = (16 - n) / 2;
  for (byte i = 0; i < n; i++)
    buf[st + i] = s[i];
  lcd.setCursor(0, fila);
  lcd.print(buf);
}

bool iguales(const char *a, byte la, const char *b, byte lb) {
  if (la != lb)
    return false;
  for (byte i = 0; i < la; i++)
    if (a[i] != b[i])
      return false;
  return true;
}

char leer_tecla_bloq() {
  char k;
  do {
    k = teclado.getKey();
    if (k && k != NO_KEY) {
      Serial.print("Tecla: ");
      Serial.println(k);
    }
  } while (k == NO_KEY);
  delay(20);
  while (teclado.getKey() != NO_KEY)
    delay(5);
  return k;
}

bool ingresar_enmascarado(const char *prompt, char *out, byte &len, byte minL,
                          byte maxL) {
  len = 0;
  for (byte i = 0; i < PWD_MAX; i++)
    out[i] = 0;
  lcd.clear();
  lcd_centrar(prompt, 0);
  lcd.setCursor(0, 1);
  while (true) {
    char k = teclado.getKey();
    if (k == NO_KEY) {
      delay(5);
      continue;
    }

    Serial.print("Tecla: ");
    Serial.println(k); // logging

    if (k >= '0' && k <= '9') {
      if (len < maxL) {
        out[len++] = k;
        lcd.print('*');
        beep(3000, 45);
      } else
        beep(800, 60);
    } else if (k == '#') { // borrar
      if (len) {
        len--;
        lcd.setCursor(len, 1);
        lcd.print(' ');
        lcd.setCursor(len, 1);
        beep(1800, 40);
      }
    } else if (k == '*') { // confirmar
      if (len >= minL) {
        beep(2400, 110);
        return true;
      }
      lcd.clear();
      lcd_centrar("Longitud 4..6", 0);
      delay(600);
      lcd.clear();
      lcd_centrar(prompt, 0);
      lcd.setCursor(0, 1);
      for (byte i = 0; i < len; i++)
        lcd.print('*');
    } else if (k == 'B') { // cancelar
      beep(500, 90);
      return false;
    }
  }
}

// --- UI ---
void ui_ok() {
  digitalWrite(PIN_LED_OK, HIGH);
  digitalWrite(PIN_LED_ERR, LOW);
  lcd.clear();
  lcd_centrar("ACCESO CONCEDIDO", 0);
  lcd_centrar("Bienvenido", 1);
  for (byte i = 0; i < 3; i++) {
    beep(1800 + 300 * i, 90);
    delay(120);
  }
  delay(T_DESBLOQ_MS);
  digitalWrite(PIN_LED_OK, LOW);
}

void ui_error(byte restan) {
  digitalWrite(PIN_LED_ERR, HIGH);
  digitalWrite(PIN_LED_OK, LOW);
  lcd.clear();
  lcd_centrar("CONTRASENA ERR.", 0);
  lcd.setCursor(0, 1);
  lcd.print("Intentos: ");
  lcd.print(restan);
  beep(400, 220);
  delay(600);
  digitalWrite(PIN_LED_ERR, LOW);
}

void ui_alarma() {
  lcd.clear();
  lcd_centrar("ALERTA!", 0);
  lcd_centrar("3 intentos", 1);
  unsigned long t0 = millis();
  while (millis() - t0 < T_ALARMA_MS) {
    digitalWrite(PIN_LED_ERR, HIGH);
    tone(PIN_BUZZER, 1000);
    delay(180);
    tone(PIN_BUZZER, 1500);
    delay(180);
    noTone(PIN_BUZZER);
    digitalWrite(PIN_LED_ERR, LOW);
  }
}

void mostrar_bienvenida() {
  lcd.clear();
  lcd_centrar("CERRADURA v1", 0);
  lcd_centrar("A=Menu  *=OK", 1);
}

// --- EEPROM ---
uint8_t checksum(const Clave &c) {
  uint16_t a = c.len;
  for (byte i = 0; i < PWD_MAX; i++)
    a += (uint8_t)c.d[i];
  return (uint8_t)a;
}

bool eeprom_leer(Clave &c) {
  if (EEPROM.read(EE_BASE) != EE_MAGIC || EEPROM.read(EE_BASE + 1) != EE_VER)
    return false;
  c.len = EEPROM.read(EE_BASE + 2);
  if (c.len < PWD_MIN || c.len > PWD_MAX)
    return false;
  for (byte i = 0; i < PWD_MAX; i++)
    c.d[i] = (char)EEPROM.read(EE_BASE + 3 + i);
  return EEPROM.read(EE_BASE + 9) == checksum(c);
}

void eeprom_guardar(const Clave &c) {
  EEPROM.update(EE_BASE, EE_MAGIC);
  EEPROM.update(EE_BASE + 1, EE_VER);
  EEPROM.update(EE_BASE + 2, c.len);
  for (byte i = 0; i < PWD_MAX; i++)
    EEPROM.update(EE_BASE + 3 + i, c.d[i]);
  EEPROM.update(EE_BASE + 9, checksum(c));
}

void eeprom_init_si_falta() {
  Clave c;
  if (!eeprom_leer(c)) {
    c.len = 4;
    c.d[0] = '1';
    c.d[1] = '2';
    c.d[2] = '3';
    c.d[3] = '4';
    for (byte i = 4; i < PWD_MAX; i++)
      c.d[i] = '0';
    eeprom_guardar(c);
  }
}

// --- Cambio de contraseña ---
void cambiar_contrasena() {
  Clave cur;
  if (!eeprom_leer(cur)) {
    eeprom_init_si_falta();
    eeprom_leer(cur);
  }

  char in[PWD_MAX];
  byte inL = 0;
  if (!ingresar_enmascarado("Ingresa actual", in, inL, cur.len, cur.len)) {
    lcd.clear();
    lcd_centrar("Cancelado", 0);
    delay(600);
    return;
  }
  if (!iguales(in, inL, cur.d, cur.len)) {
    lcd.clear();
    lcd_centrar("Actual incorrecta", 0);
    delay(900);
    return;
  }

  lcd.clear();
  lcd_centrar("Elige longitud", 0);
  lcd_centrar("4..6  (*)=OK  B", 1);
  byte nuevaL = 0;
  while (true) {
    char k = leer_tecla_bloq(); // imprime tecla a Serial
    if (k >= '4' && k <= '6') {
      nuevaL = k - '0';
      beep(2200, 70);
    } else if (k == '*' && nuevaL >= 4 && nuevaL <= 6) {
      beep(2500, 120);
      break;
    } else if (k == 'B') {
      beep(500, 100);
      lcd.clear();
      lcd_centrar("Cancelado", 0);
      delay(600);
      return;
    }
  }

  char n1[PWD_MAX], n2[PWD_MAX];
  byte l1 = 0, l2 = 0;
  if (!ingresar_enmascarado("Nueva clave", n1, l1, nuevaL, nuevaL)) {
    lcd.clear();
    lcd_centrar("Cancelado", 0);
    delay(600);
    return;
  }
  if (!ingresar_enmascarado("Repite clave", n2, l2, nuevaL, nuevaL)) {
    lcd.clear();
    lcd_centrar("Cancelado", 0);
    delay(600);
    return;
  }
  if (!iguales(n1, l1, n2, l2)) {
    lcd.clear();
    lcd_centrar("No coinciden", 0);
    delay(900);
    return;
  }

  Clave nw;
  nw.len = nuevaL;
  for (byte i = 0; i < PWD_MAX; i++)
    nw.d[i] = (i < nuevaL ? n1[i] : '0');
  eeprom_guardar(nw);
  lcd.clear();
  lcd_centrar("Clave actualizada", 0);
  digitalWrite(PIN_LED_OK, HIGH);
  beep(2200, 120);
  digitalWrite(PIN_LED_OK, LOW);
  delay(120);
}

/* ==================== SETUP / LOOP ==================== */
void setup() {
  Serial.begin(9600);
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_LED_OK, OUTPUT);
  pinMode(PIN_LED_ERR, OUTPUT);
  digitalWrite(PIN_LED_OK, LOW);
  digitalWrite(PIN_LED_ERR, LOW);

  lcd.init();
  lcd.backlight();
  eeprom_init_si_falta();
  mostrar_bienvenida();
  beep();
}

void loop() {
  Clave guardada;
  eeprom_leer(guardada);

  lcd.clear();
  lcd_centrar("Ingrese clave", 0);
  lcd.setCursor(0, 1);
  lcd.print("[A] Menu  [*]OK");

  byte intentos = INTENTOS_MAX;

  while (true) {
    // Loguear tecla siempre que se presione
    char k = teclado.getKey();
    if (k && k != NO_KEY) {
      Serial.print("Tecla: ");
      Serial.println(k);
    }

    if (k == 'A') {
      beep(2000, 80);
      cambiar_contrasena();
      mostrar_bienvenida();
      delay(700);
      break;
    }
    if (k == NO_KEY) {
      delay(5);
      continue;
    }

    // Leer la clave enmascarada
    char in[PWD_MAX];
    byte inL = 0;
    if (!ingresar_enmascarado("Clave:", in, inL, guardada.len, guardada.len)) {
      mostrar_bienvenida();
      delay(700);
      break;
    }

    if (iguales(in, inL, guardada.d, guardada.len)) {
      ui_ok();
      break;
    } else {
      if (--intentos) {
        ui_error(intentos);
      } else {
        ui_alarma();
        break;
      }
    }
  }
}
