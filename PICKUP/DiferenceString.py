# ==========================================
# UTILIDADES PARA COMPARAR ARCHIVOS DE STRINGS
# ==========================================

def read_clean_lines(path):
    """
    Lee un archivo y devuelve una lista de líneas limpias:
    - sin espacios al inicio/fin
    - sin líneas vacías
    """
    with open(path, 'r', encoding='utf-8') as f:
        return [line.strip() for line in f if line.strip()]


# ==========================================
# OPERACIONES TIPO SQL
# ==========================================

def left_anti_join(left_path, right_path, unique=False, case_insensitive=False):
    """
    Devuelve elementos que están en left pero NO en right
    (equivalente a LEFT ANTI JOIN)
    """
    left_list = read_clean_lines(left_path)
    right_list = read_clean_lines(right_path)

    if case_insensitive:
        left_list = [x.lower() for x in left_list]
        right_set = set(x.lower() for x in right_list)
    else:
        right_set = set(right_list)

    result = [x for x in left_list if x not in right_set]

    if unique:
        result = list(set(result))

    return result


def right_anti_join(left_path, right_path):
    """
    Devuelve elementos que están en right pero NO en left
    """
    left = set(read_clean_lines(left_path))
    right = set(read_clean_lines(right_path))
    return list(right - left)


def intersect(left_path, right_path):
    """
    Devuelve elementos que están en ambos archivos
    (INTERSECT)
    """
    left = set(read_clean_lines(left_path))
    right = set(read_clean_lines(right_path))
    return list(left & right)


# ==========================================
# FORMATOS DE SALIDA
# ==========================================

def format_as_sql_in(values):
    """
    Formatea como:
    ('A','B','C')
    """
    return "(" + ",".join(f"'{v}'" for v in values) + ")"


def save_to_file(filename, content):
    """
    Guarda contenido en archivo
    """
    with open(filename, "w", encoding="utf-8") as f:
        f.write(content)


# ==========================================
# MAIN (EJECUCIÓN)
# ==========================================

if __name__ == "__main__":

    # Archivos de entrada
    file_old = "previus.txt"
    file_new = "now.txt"

    # -------------------------------
    # LEFT ANTI JOIN (faltantes)
    # -------------------------------
    faltantes = left_anti_join(
        file_old,
        file_new,
        unique=True,              # quitar duplicados
        case_insensitive=True     # ignorar mayúsculas/minúsculas
    )

    print("=== SOLO EN ARCHIVO ANTIGUO ===")
    print(format_as_sql_in(faltantes))

    save_to_file("faltantes.txt", format_as_sql_in(faltantes))

    # -------------------------------
    # RIGHT ANTI JOIN (nuevos)
    # -------------------------------
    nuevos = right_anti_join(file_old, file_new)

    print("\n=== SOLO EN ARCHIVO NUEVO ===")
    print(format_as_sql_in(nuevos))

    save_to_file("nuevos.txt", format_as_sql_in(nuevos))

    # -------------------------------
    # INTERSECT (coincidencias)
    # -------------------------------
    comunes = intersect(file_old, file_new)

    print("\n=== EN AMBOS ARCHIVOS ===")
    print(format_as_sql_in(comunes))

    save_to_file("comunes.txt", format_as_sql_in(comunes))