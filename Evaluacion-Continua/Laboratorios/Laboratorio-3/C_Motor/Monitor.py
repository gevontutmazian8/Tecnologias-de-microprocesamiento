import tkinter as tk
from tkinter import ttk
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import threading
import serial
import time
from queue import Queue

class Dashboard():
    def __init__(self):
        self.start = False
        self.serial_connection = None
        self.data_queue = Queue()
        self.running = False
        self.update_thread = None
        
        self.win = tk.Tk()
        self.winSetting()
        self.mainFrames()
        self.Widgets()
        self.printFrames()
        
        # Iniciar el hilo de actualización de la interfaz
        self.start_update_thread()
        self.display()

    def winSetting(self):
        self.win.title("Motor Dashboard")
        self.win.geometry("1200x700")  # Aumentado para nueva gráfica
        # Manejar el cierre de la ventana correctamente
        self.win.protocol("WM_DELETE_WINDOW", self.on_closing)
    
    def mainFrames(self):
        self.header = tk.Frame(self.win, bg="lightblue", height=80)
        self.body = tk.Frame(self.win, bg="lightgrey", height=250)  # Aumentado
        self.footer = tk.Frame(self.win, bg="#2C3E50", height=180)
    
    def serial_connect(self):
        """Conectar al puerto serial y iniciar hilo de lectura"""
        try:
            port = self.Port.get()
            baudrate = int(self.Badu.get())
            
            self.serial_connection = serial.Serial(
                port=port, 
                baudrate=baudrate, 
                timeout=1
            )
            
            if not self.serial_connection.is_open:
                self.serial_connection.open()
            
            time.sleep(2)
            
            # Enviar comando de inicio
            start_command = 'start'
            self.serial_connection.write(start_command.encode('utf-8'))
            
            # Iniciar hilo de lectura serial
            self.running = True
            self.serial_thread = threading.Thread(target=self.serial_read_thread)
            self.serial_thread.daemon = True
            self.serial_thread.start()
            
            self.status_label.config(text=f"Conectado a {port}", foreground="green")
            
        except Exception as e:
            self.status_label.config(text=f"Error: {str(e)}", foreground="red")
    
    def serial_disconnect(self):
        """Desconectar del puerto serial"""
        self.running = False
        if self.serial_connection and self.serial_connection.is_open:
            self.serial_connection.close()
        self.status_label.config(text="Desconectado", foreground="red")
    
    def serial_read_thread(self):
        """Hilo para leer datos del puerto serial"""
        while self.running and self.serial_connection and self.serial_connection.is_open:
            try:
                # Leer datos del serial 
                if self.serial_connection.in_waiting > 0:
                    data = self.serial_connection.readline().decode('utf-8').strip()
                    
                    if data:
                        self.process_serial_data(data)
                        
            except Exception as e:
                print(f"Error en lectura serial: {e}")
                time.sleep(0.1)
    
    def process_serial_data(self, data):
        """Procesar los datos recibidos del puerto serial"""
        try:
            parts = data.split(',')
            if len(parts) == 3:
                voltaje_ref = float(parts[0])
                voltaje_ref = voltaje_ref * 5 / 1024
                voltaje_prod = float(parts[1])
                voltaje_prod = voltaje_prod * 5 / 1024
                pwm = float(parts[2])

                # Validar y limitar valores
                voltaje_ref = max(0.0, min(5.0, voltaje_ref))
                voltaje_prod = max(0.0, min(5.0, voltaje_prod))
                pwm = max(0.0, min(100.0, pwm))
                
                # Agregar datos a la cola
                self.data_queue.put(('values', (voltaje_ref, voltaje_prod, pwm)))
                
                # También para la gráfica
                current_time = time.time()
                if not hasattr(self, 'start_time'):
                    self.start_time = current_time
                
                time_elapsed = current_time - self.start_time
                self.data_queue.put(('plot', (time_elapsed, voltaje_ref, voltaje_prod, pwm)))
                
        except Exception as e:
            print(f"Error procesando datos: {e}")
    
    def start_update_thread(self):
        """Iniciar hilo de actualización de la interfaz"""
        self.update_thread = threading.Thread(target=self.update_interface)
        self.update_thread.daemon = True
        self.update_thread.start()
    
    def update_interface(self):
        """Hilo principal de actualización de la interfaz"""
        update_count = 0
        while True:
            try:
                # Procesar máximo 5 elementos por ciclo para no saturar
                processed = 0
                while not self.data_queue.empty() and processed < 5:
                    data_type, data = self.data_queue.get()
                    
                    if data_type == 'values':
                        # Usar lambda con parámetro explícito para evitar problemas de closure
                        self.win.after(0, lambda d=data: self.actualizar_valores(*d))
                    elif data_type == 'plot':
                        self.win.after(0, lambda d=data: self.update_plot_data(*d))
                    
                    processed += 1
                    update_count += 1
                
                time.sleep(0.001)  # Actualizar cada 50ms (más suave)
                
            except Exception as e:
                print(f"Error en hilo de actualización: {e}")
                time.sleep(0.1)
    
    def Widgets(self): 
        frame_conexion = tk.Frame(self.header, bg="lightblue")
        frame_conexion.pack(pady=10)
        
        tk.Label(frame_conexion, text="Configuración Serial:", 
                bg="lightblue", font=("Arial", 10, "bold")).grid(row=0, column=0, columnspan=2, pady=5)
        
        tk.Label(frame_conexion, text="Puerto:", bg="lightblue").grid(row=1, column=0, sticky="e", padx=5)
        tk.Label(frame_conexion, text="Baudrate:", bg="lightblue").grid(row=1, column=2, sticky="e", padx=5)
        
        self.Port = ttk.Combobox(frame_conexion, values=["COM2", "COM3", "COM4", "COM5"], width=10)
        self.Port.set("COM3")
        self.Port.grid(row=1, column=1, padx=5, pady=2)
        
        self.Badu = ttk.Combobox(frame_conexion, values=["9600", "115200", "152100", "384000"], width=10)
        self.Badu.set("9600")
        self.Badu.grid(row=1, column=3, padx=5, pady=2)
        
        btn_conectar = ttk.Button(frame_conexion, text="Conectar", command=self.serial_connect)
        btn_conectar.grid(row=1, column=4, padx=10, pady=2)
        
        btn_desconectar = ttk.Button(frame_conexion, text="Desconectar", command=self.serial_disconnect)
        btn_desconectar.grid(row=1, column=5, padx=5, pady=2)
        
        # Etiqueta de estado
        self.status_label = ttk.Label(frame_conexion, text="Desconectado", foreground="red")
        self.status_label.grid(row=1, column=6, padx=10, pady=2)

        # Crear frame para gráficas
        graph_frame = tk.Frame(self.body, bg="lightgrey")
        graph_frame.pack(fill="both", expand=True, padx=10, pady=5)

        # Configurar las gráficas (2 subplots)
        self.fig, (self.ax1, self.ax2) = plt.subplots(2, 1, figsize=(7, 8), dpi=80)
        self.fig.patch.set_facecolor('#F0F0F0') 

        # Datos iniciales para ambas gráficas
        self.x_data = []
        self.y1_data = []  # Voltaje referencia
        self.y2_data = []  # Voltaje producido
        self.y3_data = []  # PWM

        # Gráfica 1: Voltajes
        self.line1, = self.ax1.plot(self.x_data, self.y1_data, 'b-', linewidth=2, label='V(ref)')
        self.line2, = self.ax1.plot(self.x_data, self.y2_data, 'r-', linewidth=2, label='V(prod)')
        self.ax1.set_title('Gráfica V(ref) vs V(producto)', fontsize=12, fontweight='bold')
        self.ax1.set_ylabel('Voltaje (V)')
        self.ax1.grid(True, alpha=0.3)
        self.ax1.legend()
        self.ax1.set_ylim(0, 5)

        # Gráfica 2: PWM
        self.line3, = self.ax2.plot(self.x_data, self.y3_data, 'g-', linewidth=2, label='PWM')
        self.ax2.set_title('Gráfica PWM', fontsize=12, fontweight='bold')
        self.ax2.set_xlabel('Tiempo (s)')
        self.ax2.set_ylabel('PWM (%)')
        self.ax2.grid(True, alpha=0.3)
        self.ax2.legend()
        self.ax2.set_ylim(0, 100)

        # Ajustar espaciado entre subplots
        self.fig.tight_layout(pad=3.0)
        
        self.canvas = FigureCanvasTkAgg(self.fig, master=graph_frame)
        self.canvas.draw()
        self.canvas.get_tk_widget().pack(fill="both", expand=True)

        # Configurar grid del footer
        self.footer.grid_columnconfigure(0, minsize=180)
        self.footer.grid_columnconfigure(1, weight=1)
        self.footer.grid_columnconfigure(2, minsize=70)
        self.footer.grid_columnconfigure(3, minsize=30)
        
        # Título de la sección
        title_label = ttk.Label(
            self.footer, 
            text="Parámetros del Motor", 
            font=("Arial", 12, "bold"),
            background="#2C3E50",
            foreground="white"
        )
        title_label.grid(row=0, column=0, columnspan=4, pady=(10, 15))
        
        # Fila 1 - Voltaje de referencia
        ttk.Label(self.footer, text="Voltaje de referencia:", 
                 background="#2C3E50", foreground="white").grid(
            row=1, column=0, padx=(20, 10), pady=8, sticky="e")
        
        self.progress_bar_1 = ttk.Progressbar(
            self.footer, 
            orient="horizontal", 
            mode="determinate", 
            maximum=5.0,
            length=300,
            style="Custom.Horizontal.TProgressbar"
        )
        self.progress_bar_1.grid(row=1, column=1, padx=10, pady=8, sticky="ew")
        
        self.label_voltaje_1 = ttk.Label(self.footer, text="0.00", 
                                        background="#2C3E50", foreground="white",
                                        width=6, font=("Arial", 10, "bold"))
        self.label_voltaje_1.grid(row=1, column=2, padx=5, pady=8)
        
        ttk.Label(self.footer, text="V", 
                 background="#2C3E50", foreground="white",
                 font=("Arial", 10, "bold")).grid(
            row=1, column=3, padx=(5, 20), pady=8, sticky="w")
        
        # Fila 2 - Voltaje Producido
        ttk.Label(self.footer, text="Voltaje Producido:", 
                 background="#2C3E50", foreground="white").grid(
            row=2, column=0, padx=(20, 10), pady=8, sticky="e")
        
        self.progress_bar_2 = ttk.Progressbar(
            self.footer, 
            orient="horizontal", 
            mode="determinate", 
            maximum=5.0,
            length=300,
            style="Custom.Horizontal.TProgressbar"
        )
        self.progress_bar_2.grid(row=2, column=1, padx=10, pady=8, sticky="ew")
        
        self.label_voltaje_2 = ttk.Label(self.footer, text="0.00", 
                                        background="#2C3E50", foreground="white",
                                        width=6, font=("Arial", 10, "bold"))
        self.label_voltaje_2.grid(row=2, column=2, padx=5, pady=8)
        
        ttk.Label(self.footer, text="V", 
                 background="#2C3E50", foreground="white",
                 font=("Arial", 10, "bold")).grid(
            row=2, column=3, padx=(5, 20), pady=8, sticky="w")
        
        # Fila 3 - PWM
        ttk.Label(self.footer, text="PWM:", 
                 background="#2C3E50", foreground="white").grid(
            row=3, column=0, padx=(20, 10), pady=8, sticky="e")
        
        self.progress_bar_3 = ttk.Progressbar(
            self.footer, 
            orient="horizontal", 
            mode="determinate", 
            maximum=100.0,
            length=300,
            style="Custom.Horizontal.TProgressbar"
        )
        self.progress_bar_3.grid(row=3, column=1, padx=10, pady=8, sticky="ew")
        
        self.label_pwm = ttk.Label(self.footer, text="0.0", 
                                  background="#2C3E50", foreground="white",
                                  width=6, font=("Arial", 10, "bold"))
        self.label_pwm.grid(row=3, column=2, padx=5, pady=8)
        
        ttk.Label(self.footer, text="%", 
                 background="#2C3E50", foreground="white",
                 font=("Arial", 10, "bold")).grid(
            row=3, column=3, padx=(5, 20), pady=8, sticky="w")
    
    def actualizar_valores(self, voltaje_ref, voltaje_prod, pwm):
        """Actualizar las barras de progreso y etiquetas """
        try:
            # Validar valores una vez más
            voltaje_ref = max(0.0, min(5.0, float(voltaje_ref)))
            voltaje_prod = max(0.0, min(5.0, float(voltaje_prod)))
            pwm = max(0.0, min(100.0, float(pwm)))
            
            # Actualizar progressbars
            self.progress_bar_1['value'] = voltaje_ref
            self.progress_bar_2['value'] = voltaje_prod
            self.progress_bar_3['value'] = pwm
            
            # Actualizar labels
            self.label_voltaje_1.config(text=f"{voltaje_ref:.2f}")
            self.label_voltaje_2.config(text=f"{voltaje_prod:.2f}")
            self.label_pwm.config(text=f"{pwm:.1f}")
            
            # Forzar actualización visual inmediata
            self.win.update_idletasks()
            
        except Exception as e:
            print(f"Error actualizando valores: {e}")
    
    def update_plot_data(self, x, y1, y2, y3):
        """Actualizar la gráfica con nuevos datos"""
        try:
            # Agregar nuevos datos
            self.x_data.append(x)
            self.y1_data.append(y1)
            self.y2_data.append(y2)
            self.y3_data.append(y3)
            
            # Mantener solo los últimos 100 puntos
            if len(self.x_data) > 100:
                self.x_data = self.x_data[-100:]
                self.y1_data = self.y1_data[-100:]
                self.y2_data = self.y2_data[-100:]
                self.y3_data = self.y3_data[-100:]
            
            # Actualizar las líneas de la gráfica 1 (voltajes)
            self.line1.set_data(self.x_data, self.y1_data)
            self.line2.set_data(self.x_data, self.y2_data)
            
            # Actualizar las líneas de la gráfica 2 (PWM)
            self.line3.set_data(self.x_data, self.y3_data)
            
            # Ajustar los límites del gráfico para ambas subplots
            if self.x_data:
                x_min = max(0, self.x_data[-1] - 30)  # Mostrar últimos 30 segundos
                x_max = max(10, self.x_data[-1] + 2)  
                
                self.ax1.set_xlim(x_min, x_max)
                self.ax2.set_xlim(x_min, x_max)
            
            # Redibujar de manera segura
            self.canvas.draw_idle()
            
        except Exception as e:
            print(f"Error actualizando gráfica: {e}")
    
    def printFrames(self):
        self.header.pack(fill="x")
        self.body.pack(fill="both", expand=True, pady=5)
        self.footer.pack(fill="both", expand=True)

    def on_closing(self):
        """Manejar el cierre de la aplicación"""
        self.running = False
        if self.serial_connection and self.serial_connection.is_open:
            self.serial_connection.close()
        self.win.destroy()

    def display(self):
        self.win.mainloop()

# Ejecutar la aplicación
if __name__ == "__main__":
    Ventana = Dashboard()