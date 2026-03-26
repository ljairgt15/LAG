def left_anti_join_files(left_path, right_path):
    # Leer archivos
    with open(left_path, 'r', encoding='utf-8') as f:
        left_text = f.read()

    with open(right_path, 'r', encoding='utf-8') as f:
        right_text = f.read()

    # Separar GUIDs
    left_list = left_text.split()
    right_set = set(right_text.split())

    # LEFT ANTI JOIN
    result = [guid for guid in left_list if guid not in right_set]

    return result


def format_as_sql_tuple(guids):
    return "(" + ",".join(f"'{g}'" for g in guids) + ")"
faltantes = left_anti_join_files("previus.txt", "now.txt")

print("Solo en Data antigua:")
print(format_as_sql_tuple(faltantes))
with open("faltantes.txt", "w", encoding='utf-8') as f:
    f.write(format_as_sql_tuple(faltantes))