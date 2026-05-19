import sys
import time
import serial

from Adafruit_IO import MQTTClient

# ── Configuracion — edita estos valores ─────────────────────────
ADAFRUIT_IO_USERNAME = "Mao13071"
ADAFRUIT_IO_KEY      = "aio_vskL97uh1FX0u6eGcUBdgezqDsyS"
PUERTO_SERIAL        = "COM5"
BAUDRATE             = 9600
# ────────────────────────────────────────────────────────────────

# ── Feeds de ENTRADA ─────────────────────────────────────────────
FEED_PARP_SUP   = "parpados-superiores"
FEED_PARP_INF   = "parpados-inferiores"
FEED_VERTICAL   = "ojos-vertical"
FEED_HORIZONTAL = "ojos-horizontal"
FEED_GRABAR     = "grabar"
FEED_BORRAR     = "borrar"

# ── Feeds de SALIDA (Gauges) ─────────────────────────────────────
FEED_GAUGE_SUP  = "lectura-parpado-superior"
FEED_GAUGE_INF  = "lectura-parpado-inferior"
FEED_GAUGE_VERT = "lectura-vertical"
FEED_GAUGE_HORI = "lectura-horizontal"
# ────────────────────────────────────────────────────────────────

# ── Conexion Serial al Arduino ───────────────────────────────────
try:
    arduino = serial.Serial(PUERTO_SERIAL, BAUDRATE, timeout=1)
    time.sleep(2)
    print("Serial conectado en {0}".format(PUERTO_SERIAL))
except serial.SerialException as e:
    print("Error Serial: {0}".format(e))
    print("Verifica que el Arduino este conectado y el puerto sea correcto")
    sys.exit(1)

def enviar_arduino(comando):
    """Envia un comando al Arduino por Serial"""
    cmd = comando.strip() + "\n"
    arduino.write(cmd.encode("utf-8"))
    print(">> Arduino: {0}".format(cmd.strip()))
    time.sleep(0.1)

def publicar_gauge(client, feed, valor):
    """Publica el angulo en el Gauge correspondiente"""
    client.publish(feed, valor)
    print("Gauge {0} = {1}".format(feed, valor))

# ── Callbacks de Adafruit IO ─────────────────────────────────────
def connected(client):
    """Se ejecuta al conectar con Adafruit IO"""
    print("Conectado a Adafruit IO!")
    print("Suscribiendo a feeds...")

    client.subscribe(FEED_PARP_SUP)
    client.subscribe(FEED_PARP_INF)
    client.subscribe(FEED_VERTICAL)
    client.subscribe(FEED_HORIZONTAL)
    client.subscribe(FEED_GRABAR)
    client.subscribe(FEED_BORRAR)

    print("Esperando comandos desde Adafruit IO...")

def disconnected(client):
    """Se ejecuta al desconectarse"""
    print("Desconectado de Adafruit IO")
    sys.exit(1)

def message(client, feed_id, payload):
    """Se ejecuta cuando llega un mensaje de cualquier feed suscrito"""
    print("Feed '{0}' recibio: {1}".format(feed_id, payload))

    # ── Párpados superiores ───────────────────────────────────────
    if feed_id == FEED_PARP_SUP:
        angulo = int(float(payload))
        espejo = 180 - angulo
        enviar_arduino("MOVER 0 {0}".format(angulo))
        enviar_arduino("MOVER 1 {0}".format(espejo))
        publicar_gauge(client, FEED_GAUGE_SUP, angulo)

    # ── Párpados inferiores ───────────────────────────────────────
    elif feed_id == FEED_PARP_INF:
        angulo = int(float(payload))
        espejo = 180 - angulo
        enviar_arduino("MOVER 2 {0}".format(espejo))
        enviar_arduino("MOVER 3 {0}".format(angulo))
        publicar_gauge(client, FEED_GAUGE_INF, angulo)

    # ── Vertical ──────────────────────────────────────────────────
    elif feed_id == FEED_VERTICAL:
        angulo = int(float(payload))
        enviar_arduino("MOVER 4 {0}".format(angulo))
        publicar_gauge(client, FEED_GAUGE_VERT, angulo)

    # ── Horizontal ────────────────────────────────────────────────
    elif feed_id == FEED_HORIZONTAL:
        angulo = int(float(payload))
        enviar_arduino("MOVER 5 {0}".format(angulo))
        publicar_gauge(client, FEED_GAUGE_HORI, angulo)

    # ── Grabar posicion en slot ───────────────────────────────────
    elif feed_id == FEED_GRABAR:
        slot = int(float(payload))
        if 0 <= slot <= 9:
            enviar_arduino("GRABAR {0}".format(slot))
            print("Posicion grabada en slot {0}".format(slot))
        else:
            print("Error: slot debe ser entre 0 y 9")

    # ── Borrar toda la EEPROM ─────────────────────────────────────
    elif feed_id == FEED_BORRAR:
        if payload.strip() == "1":
            enviar_arduino("BORRAR")
            print("EEPROM borrada")

# ── Crear cliente MQTT igual que en el ejemplo de clase ──────────
client = MQTTClient(ADAFRUIT_IO_USERNAME, ADAFRUIT_IO_KEY)

client.on_connect    = connected
client.on_disconnect = disconnected
client.on_message    = message

# ── Conectar a Adafruit IO ───────────────────────────────────────
client.connect()
client.loop_background()

# ── Loop principal ───────────────────────────────────────────────
print("=== Puente activo. Ctrl+C para salir ===")

while True:
    time.sleep(0.01)