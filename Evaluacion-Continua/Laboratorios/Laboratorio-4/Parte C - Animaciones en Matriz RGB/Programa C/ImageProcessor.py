from PIL import Image
import sys

try:
    img1 = Image.open("Pathetic (1).png")
except:
    print("No se encontro imagen")
    sys.exit(1)

img = img1.convert('RGB')
Ancho, Alto = img.size
print("Alto:", Alto)
print("Ancho:", Ancho)

pixeles = img.load()

ListaDeColores = [(168, 191, 225), (96, 125, 102), (219, 164, 126), (0, 0, 0), (255, 255, 255), (125, 109, 87), (106, 88, 78), (181, 135, 104), (176, 131, 101), (133, 99, 76)]

# Convertir a entero
NumeroFrames = Alto // 16  # División entera
print("La cantidad de Frames son:", NumeroFrames)

ListaDeFrames = []

# Recorrer por frames primero
for frame in range(NumeroFrames):
    frame_actual = []
    y_inicio = frame * 16
    
    for y in range(y_inicio, y_inicio + 16):
        fila_actual = []
        for x in range(Ancho):
            color_actual = pixeles[x, y]
            
            # Buscar si el color está en la lista
            indice_color = -1
            for i, color_lista in enumerate(ListaDeColores):
                if color_actual == color_lista:
                    indice_color = i
                    break
            
            # Si no está en la lista, guardar el color RGB completo
            if indice_color != -1:
                fila_actual.append(indice_color)
            else:
                fila_actual.append(color_actual)
        
        frame_actual.append(fila_actual)
    
    ListaDeFrames.append(frame_actual)

for frame in ListaDeFrames:
    for row in frame:
        print(row)
    print()
    print("=" * 50)
    print()


