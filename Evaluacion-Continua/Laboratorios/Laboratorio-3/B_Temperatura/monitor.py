# monitor.py

import re
import csv
import time
import argparse
from datetime import datetime

import serial 
import matplotlib.pyplot as plt 
from matplotlib.animation import FuncAnimation 

# ---------- Regex que matchean EXACTO lo que imprime tu sketch ----------
RX_TEMP  = re.compile(r"Temp:\s*([0-9]+(?:\.[0-9])?)\s*°C", re.IGNORECASE)
RX_HEAT  = re.compile(r"Calefactor\s*ON", re.IGNORECASE)
RX_FAN   = re.compile(r"Ventilador\s*PWM\s*=\s*([0-9]+)", re.IGNORECASE)
RX_RANGE = re.compile(r"Rango\s+ideal:\s*([0-9]+(?:\.[0-9])?)\s*[–-]\s*([0-9]+(?:\.[0-9])?)\s*°C", re.IGNORECASE)

def parse_args():
    ap = argparse.ArgumentParser(description="Monitor en vivo de temperatura desde Arduino")
    ap.add_argument("--port", default="COM5", help="Puerto serial (default COM5)")
    ap.add_argument("--baud", type=int, default=9600, help="Baudios (default 9600)")
    ap.add_argument("--csv",  default="log_temp.csv", help="Archivo CSV de salida")
    ap.add_argument("--png",  default="grafica.png",  help="Imagen final de la gráfica")
    ap.add_argument("--max-sec", type=float, default=None, help="Tiempo máx en segundos (si se omite, manual con Ctrl+C)")
    return ap.parse_args()

def main():
    args = parse_args()

    # --- Serial ---
    print(f"[INFO] Abriendo {args.port} @ {args.baud} …")
    ser = serial.Serial(args.port, args.baud, timeout=0.2)

    # --- CSV ---
    csv_file = open(args.csv, "w", newline="")
    writer = csv.writer(csv_file)
    writer.writerow(["timestamp_iso", "t_sec", "temp_c", "heater_on", "fan_pwm", "ideal_low", "ideal_high"])

    # --- Buffers de datos en memoria (para graficar) ---
    tsec, temp, heater, fan = [], [], [], []
    ideal_low_series, ideal_high_series = [], []

    ideal_low = None
    ideal_high = None
    heater_on = 0
    fan_pwm = 0
    last_temp = None

    start = time.time()

    # --- Matplotlib: figura y ejes ---
    fig = plt.figure(figsize=(10, 5))
    ax1 = plt.gca()
    ax1.set_xlabel("Tiempo [s]")
    ax1.set_ylabel("Temperatura [°C]")

    (line_temp,) = ax1.plot([], [], label="Temperatura")
    band_ideal = None  # se crea cuando tengamos ideal_low/high
    # Heater (escalón visual)
    (line_heat,) = ax1.step([], [], where="post", label="Calefactor ON (escala)", alpha=0.6)

    # Eje derecho para PWM
    ax2 = ax1.twinx()
    ax2.set_ylabel("Ventilador PWM (0–255)")
    (line_fan,) = ax2.plot([], [], linestyle="--", label="Fan PWM")

    # Leyenda combinada
    def update_legend():
        l1, lb1 = ax1.get_legend_handles_labels()
        l2, lb2 = ax2.get_legend_handles_labels()
        ax1.legend(l1 + l2, lb1 + lb2, loc="best")

    update_legend()
    ax1.grid(True, alpha=0.3)
    plt.tight_layout()

    # --- Función que lee y procesa una línea serial ---
    def read_one_line():
        nonlocal ideal_low, ideal_high, heater_on, fan_pwm, last_temp
        try:
            line = ser.readline().decode("utf-8", errors="ignore").strip()
        except Exception:
            line = ""
        if not line:
            return

        # Rango ideal (se actualiza cuando Arduino lo anuncia)
        mR = RX_RANGE.search(line)
        if mR:
            ideal_low  = float(mR.group(1))
            ideal_high = float(mR.group(2))

        # Temp
        mT = RX_TEMP.search(line)
        if mT:
            last_temp = float(mT.group(1))

        # Acciones
        if RX_HEAT.search(line):
            heater_on = 1
            fan_pwm = 0
        mF = RX_FAN.search(line)
        if mF:
            heater_on = 0
            fan_pwm = int(mF.group(1))

        # Si hay temperatura válida, persistimos
        if last_temp is not None:
            now = time.time()
            ts = datetime.now().isoformat(timespec="seconds")
            dt = now - start

            tsec.append(dt)
            temp.append(last_temp)
            heater.append(heater_on)
            fan.append(fan_pwm)
            ideal_low_series.append(ideal_low)
            ideal_high_series.append(ideal_high)

            writer.writerow([
                ts,
                f"{dt:.1f}",
                f"{last_temp:.2f}",
                heater_on,
                fan_pwm,
                "" if ideal_low is None else f"{ideal_low:.2f}",
                "" if ideal_high is None else f"{ideal_high:.2f}",
            ])
            csv_file.flush()

            # Log mínimo por consola
            if len(tsec) % 5 == 0:
                print(f"[{ts}] Temp={last_temp:.1f}°C | Heater={heater_on} | FanPWM={fan_pwm} "
                      f"| Ideal={ideal_low}-{ideal_high}")

    # --- Animación (update periódico) ---
    def animate(_frame):
        # Leer varias líneas por frame para que no quede “tardo”
        for _ in range(10):
            read_one_line()

        if not tsec:
            return line_temp,

        # Actualizar curvas
        line_temp.set_data(tsec, temp)
        line_fan.set_data(tsec, fan)

        # Heater como escalón pegado por debajo de la curva (solo para visualizar ON/OFF)
        base = (min(temp) if temp else 0) - max(0.5, (max(temp) - min(temp)) * 0.2)
        heat_vis = [base + (0.5 if h == 1 else 0) for h in heater]
        line_heat.set_data(tsec, heat_vis)

        # Banda ideal si hay límites
        nonlocal band_ideal
        if ideal_low is not None and ideal_high is not None:
            # Borrar banda anterior y dibujar la nueva (todo el tramo)
            if band_ideal is not None:
                try: band_ideal.remove()
                except Exception: pass
                band_ideal = None
            band_ideal = ax1.fill_between(
                tsec,
                [ideal_low if x is None else x for x in ideal_low_series],
                [ideal_high if x is None else x for x in ideal_high_series],
                alpha=0.15,
                label="Rango ideal"
            )

        # Autoscale
        ax1.relim(); ax1.autoscale_view()
        ax2.relim(); ax2.autoscale_view()

        # Ejes limpios
        ax1.set_xlim(left=max(0, tsec[-1] - 120), right=tsec[-1] + 2)  # ventana ~120 s
        update_legend()
        return line_temp, line_fan, line_heat

    ani = FuncAnimation(fig, animate, interval=100, blit=False)

    # Corte por tiempo máx opcional
    def done():
        if args.max_sec is None:
            return False
        return (time.time() - start) >= args.max_sec

    try:
        while True:
            plt.pause(0.1)
            if done():
                break
    except KeyboardInterrupt:
        print("\n[INFO] Detenido por el usuario.")
    finally:
        # Guardar imagen final y cerrar todo
        try:
            plt.savefig(args.png, dpi=150)
            print(f"[OK] Gráfica guardada en {args.png}")
        except Exception as e:
            print(f"[WARN] No se pudo guardar la imagen: {e}")
        ser.close()
        csv_file.close()
        print(f"[OK] CSV guardado en {args.csv}")

if __name__ == "__main__":
    main()
