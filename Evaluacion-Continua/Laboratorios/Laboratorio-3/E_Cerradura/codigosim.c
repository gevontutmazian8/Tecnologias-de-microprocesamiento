/// --- Pines ---
const int LM35_PIN = A0;  // Sensor de temperatura LM35
const int HEATER_PIN = 6; // Calefactor o LED indicador

// Control del ventilador (L298N)
const int ENA = 3; // PWM de velocidad
const int IN1 = 4; // Dirección
const int IN2 = 5; // Dirección

/// --- Configuración de rangos ---
float puntoMedio = 26.0; // Temperatura media por defecto
float offInf = 3.0;      // Margen inferior  (26 - 3 = 23)
float offSup = 4.0;      // Margen superior  (26 + 4 = 30)
float T_MIN, T_MAX;
const float H = 0.5; // Histeresis para evitar parpadeos

/// --- Velocidades del ventilador ---
const int FAN_LOW = 85;   // Baja velocidad (31–40)
const int FAN_MED = 170;  // Media velocidad (41–50)
const int FAN_HIGH = 255; // Alta velocidad (≥51)m

int prevFanPWM = 0; // Guarda el valor anterior del ventilador

// Prototipos
void aplicarActuadores(bool heaterOn, int fanPWM);
float leerTemperatura();
void leerComandoSerial();
void recalcularRangos();
void mostrarRangos();

// ===========================================================
//                     SETUP
// ===========================================================
void setup() {
  Serial.begin(9600);

  pinMode(HEATER_PIN, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);

  // Sentido de giro fijo para el ventilador
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);

  // Estado inicial
  digitalWrite(HEATER_PIN, LOW);
  analogWrite(ENA, 0);

  recalcularRangos();

  // Descartar primeras lecturas del LM35
  for (int i = 0; i < 8; i++) {
    analogRead(LM35_PIN);
    delay(5);
  }

  Serial.println("=== Sistema de Control de Temperatura ===");
  mostrarRangos();
  Serial.println("Usá 'mXX' para cambiar el punto medio (por ejemplo: m28)");
}

// ===========================================================
//                     LOOP
// ===========================================================
void loop() {
  float temperatura = leerTemperatura();

  // Si la lectura es inválida, avisar y saltar ciclo
  if (temperatura < -50) {
    aplicarActuadores(false, 0);
    Serial.println(
        "Error: lectura LM35 inválida. Revisar conexión o alimentación.");
    delay(1000);
    return;
  }

  leerComandoSerial(); // Permite cambiar el punto medio

  bool heaterOn = false;
  int fanPWM = 0;

  // --- Lógica principal ---
  if (temperatura <= (T_MIN - H)) { // 0–22 °C
    heaterOn = true;
    fanPWM = 0;
  } else if (temperatura > (T_MIN + H) &&
             temperatura <= (T_MAX - H)) { // 23–30 °C
    heaterOn = false;
    fanPWM = 0;
  } else if (temperatura > (T_MAX + H) &&
             temperatura <= (T_MAX + 10.0)) { // 31–40 °C
    fanPWM = FAN_LOW;
  } else if (temperatura > (T_MAX + 10.0) &&
             temperatura <= (T_MAX + 20.0)) { // 41–50 °C
    fanPWM = FAN_MED;
  } else if (temperatura >= (T_MAX + 21.0 - H)) { // >51 °C
    fanPWM = FAN_HIGH;
  }

  aplicarActuadores(heaterOn, fanPWM);

  // Mostrar estado actual
  Serial.print("Temp: ");
  Serial.print(temperatura, 1);
  Serial.print(" °C, ");

  if (heaterOn)
    Serial.println("Calefactor ON");
  else if (fanPWM > 0) {
    Serial.print("Ventilador PWM = ");
    Serial.println(fanPWM);
  } else
    Serial.println("Sistema en reposo");

  delay(1000);
}

// ===========================================================
//               FUNCIONES AUXILIARES
// ===========================================================

// Controla calefactor y ventilador
void aplicarActuadores(bool heaterOn, int fanPWM) {
  digitalWrite(HEATER_PIN, heaterOn ? HIGH : LOW);

  // “Kickstart” para ayudar al arranque del ventilador
  if (fanPWM > 0 && prevFanPWM == 0) {
    analogWrite(ENA, 255);
    delay(300);
  }

  analogWrite(ENA, fanPWM);
  prevFanPWM = fanPWM;
}

// Promedia varias lecturas del LM35 y calcula temperatura
float leerTemperatura() {
  const int N = 20;
  long suma = 0;
  int validas = 0;

  for (int i = 0; i < N; i++) {
    int lectura = analogRead(LM35_PIN);
    if (lectura > 3 && lectura < 1020) {
      suma += lectura;
      validas++;
    }
    delay(2);
  }

  if (validas == 0)
    return -100.0;

  float promedio = suma / float(validas);
  float voltaje_mV = promedio * (5000.0 / 1023.0);
  float tempC = voltaje_mV / 10.0; // 10 mV = 1 °C (LM35)

  if (tempC < -10 || tempC > 150)
    return -100.0;
  return tempC;
}

// Permite cambiar el punto medio desde el monitor serie
void leerComandoSerial() {
  if (!Serial.available())
    return;

  char c = Serial.read();
  if (c == 'm' || c == 'M') {
    int nuevo = Serial.parseInt();
    if (nuevo >= 10 && nuevo <= 50) {
      puntoMedio = nuevo;
      recalcularRangos();
      Serial.print("Nuevo punto medio: ");
      Serial.println(puntoMedio);
      mostrarRangos();
    } else {
      Serial.println("Valor fuera de rango (10–50 °C).");
    }
  }
}

// Actualiza límites de control según el punto medio
void recalcularRangos() {
  T_MIN = puntoMedio - offInf;
  T_MAX = puntoMedio + offSup;
}

// Muestra los rangos actuales en el monitor serie
void mostrarRangos() {
  Serial.print("Rango ideal: ");
  Serial.print(T_MIN, 1);
  Serial.print(" – ");
  Serial.print(T_MAX, 1);
  Serial.println(" °C");
  Serial.println("31–40 → Ventilador BAJO | 41–50 → MEDIO | ≥51 → ALTO");
}
