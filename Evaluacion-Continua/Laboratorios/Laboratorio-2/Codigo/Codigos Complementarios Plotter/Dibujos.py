import re
import matplotlib.pyplot as plt

def extract_coordinates_from_gcode(file_path):

    x_coords = []
    y_coords = []

    # Patrones regex para encontrar coordenadas X e Y
    x_pattern = r'X([-]?\d+\.\d+)'
    y_pattern = r'Y([-]?\d+\.\d+)'

    try:
        with open(file_path, 'r') as file:
            for line in file:
                line = line.strip()

                # Buscar coordenadas X
                x_matches = re.findall(x_pattern, line)
                for x_match in x_matches:
                    x_coords.append(float(x_match))

                # Buscar coordenadas Y
                y_matches = re.findall(y_pattern, line)
                for y_match in y_matches:
                    y_coords.append(float(y_match))

    except FileNotFoundError:
        print(f"Error: No se pudo encontrar el archivo {file_path}")
        return [], []
    except Exception as e:
        print(f"Error al procesar el archivo: {e}")
        return [], []

    return x_coords, y_coords

def calculate_deltas(coordinates):
    deltas = []
    for i in range(1, len(coordinates)):
        delta = coordinates[i] - coordinates[i-1]
        deltas.append(round(delta, 6))  # Redondear a 6 decimales
    return deltas

# Uso del código
if __name__ == "__main__":
    # Si el archivo está en el mismo directorio
    file_path = "gcode.txt"  

    # Extraer coordenadas
    x_coords, y_coords = extract_coordinates_from_gcode(file_path)

    print(f"Coordenadas X encontradas: {len(x_coords)}")
    print(f"Coordenadas Y encontradas: {len(y_coords)}")

    # Calcular deltas
    if x_coords and y_coords:
        x_deltas = calculate_deltas(x_coords)
        y_deltas = calculate_deltas(y_coords)

        print("\n--- LISTA DE DELTAS X ---")
        print(len(x_deltas))
        print(x_deltas)
        for a in range(len(x_deltas)):
            x_deltas[a] = round(x_deltas[a] * 20)
        print(x_deltas)


        print("\n--- LISTA DE DELTAS Y ---")
        print(len(y_deltas))
        print(y_deltas)
        for a in range(len(y_deltas)):
            y_deltas[a] = round(y_deltas[a] * 20)
        print(y_deltas)


def comprobar_plotter_relativo(deltas_x, deltas_y:

    # --- 1. Verificación de Datos de Entrada ---
    if len(deltas_x) != len(deltas_y):
        print("🚨 Error: Las listas de deltas X e Y deben tener la misma longitud.")
        return

    # --- 2. Inicialización de Coordenadas ---
    posicion_actual_x = 0
    posicion_actual_y = 0

    # Listas para almacenar las coordenadas absolutas
    puntos_x_absolutos = [posicion_actual_x]
    puntos_y_absolutos = [posicion_actual_y]

    # --- 3. Cálculo de Coordenadas Absolutas (Simulación del Movimiento) ---
    print(f"Punto Inicial: ({posicion_actual_x:.2f}, {posicion_actual_y:.2f})")

    for i in range(len(deltas_x)):
        dx = deltas_x[i]
        dy = deltas_y[i]

        # El nuevo punto es la posición actual más el movimiento relativo
        posicion_actual_x += dx
        posicion_actual_y += dy

        # Almacenar el nuevo punto
        puntos_x_absolutos.append(posicion_actual_x)
        puntos_y_absolutos.append(posicion_actual_y)

    # --- 4. Visualización con Matplotlib ---
    plt.figure(figsize=(8, 8)) # Crea una figura cuadrada para mejor visualización

    # Dibuja las líneas que componen la figura
    plt.plot(puntos_x_absolutos, puntos_y_absolutos,
             marker='o',          # Marca cada punto con un círculo
             linestyle='-',       # Usa una línea sólida
             color='black',    # Color del trazo
             linewidth=2,         # Grosor de la línea
             label="Trazado de la figura")

    # Personalización del gráfico
    plt.title("Figura", fontsize=14)
    plt.xlabel("Eje X")
    plt.ylabel("Eje Y")
    plt.axhline(0, color='gray', linewidth=0.5) # Eje X
    plt.axvline(0, color='gray', linewidth=0.5) # Eje Y
    plt.grid(True, linestyle='--', alpha=0.6)
    plt.axis('equal')
    plt.legend()
    plt.show()


for i in range(225): #Permite la modificacion de la cantidad de digitos de manera facil para truncar la figura
    Dx.append(x_deltas[i])
    Dy.append(y_deltas[i])

print(Dx)
print(Dy)

print(len(Dx))
print("\n--- Comprobación Simple ---")
comprobar_plotter_relativo(Dx, Dy, "AAA Simple ")