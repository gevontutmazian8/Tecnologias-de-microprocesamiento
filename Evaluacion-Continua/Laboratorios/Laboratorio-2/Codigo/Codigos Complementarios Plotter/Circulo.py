import math

def generar_deltas_circulo_simple(radio=25, num_puntos=35):

    deltas_x = []
    deltas_y = []

    for i in range(num_puntos):
        # Ángulo actual y siguiente
        angulo_actual = 2 * math.pi * i / num_puntos
        angulo_siguiente = 2 * math.pi * (i + 1) / num_puntos

        # Calcular puntos
        x_actual = radio * math.cos(angulo_actual)
        y_actual = radio * math.sin(angulo_actual)
        x_siguiente = radio * math.cos(angulo_siguiente)
        y_siguiente = radio * math.sin(angulo_siguiente)

        # Calcular deltas
        dx = x_siguiente - x_actual
        dy = y_siguiente - y_actual

        deltas_x.append(int(round(dx)))
        deltas_y.append(int(round(dy)))

    return deltas_x, deltas_y

# Generar datos
radio = 200
dx, dy = generar_deltas_circulo_simple(radio, 40)


print("Dx =")
for i in range(0, len(dx), 10):
    valores = dx[i:i+10]
    linea = ", ".join(f"{val:3d}" for val in valores)
    print("   " + linea + ",")

print("")

print("Dy =")
for i in range(0, len(dy), 10):
    valores = dy[i:i+10]
    linea = ", ".join(f"{val:3d}" for val in valores)
    print("   " + linea + ",")


print("")
print(f"// Total puntos: {len(dx)}")
print(f"// Suma Dx: {sum(dx)}, Suma Dy: {sum(dy)}")