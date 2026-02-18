import os

def leerGuid(nombre_archivo):
    base_dir = os.path.dirname(os.path.abspath(__file__))
    ruta = os.path.join(base_dir, nombre_archivo)

    with open(ruta, 'r', encoding='utf-8') as f:
        return f.read()


def dividir_en_bloques(lista, tamaño_bloque=500, limite_total=5500):
    lista = lista[:limite_total]  # limitar a 5500 máximo
    for i in range(0, len(lista), tamaño_bloque):
        yield lista[i:i + tamaño_bloque]


# ===== Leer GUIDs =====
texto = leerGuid('guids.txt')
guids = [g.strip() for g in texto.splitlines() if g.strip()]

print("Total GUIDs:", len(guids))

# ===== Dividir =====
bloques = list(dividir_en_bloques(guids, 500, 5500))

# ===== Guardar en archivo =====
base_dir = os.path.dirname(os.path.abspath(__file__))
output_path = os.path.join(base_dir, "resultado_dividido.txt")

with open(output_path, "w", encoding='utf-8') as f:
    for i, bloque in enumerate(bloques, 1):
        tupla_sql = "(" + ",".join(f"'{g}'" for g in bloque) + ")"
        f.write(f"-- BLOQUE {i}\n")
        f.write(tupla_sql + "\n\n")

print("Archivo generado:", output_path)
print("Cantidad de bloques:", len(bloques))
