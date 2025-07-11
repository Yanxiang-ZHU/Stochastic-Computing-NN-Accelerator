def compare_files(result_file, label_file, num_lines=1000):
    with open(result_file, 'r', encoding='utf-8') as res_file, open(label_file, 'r', encoding='utf-8') as lbl_file:
        result_lines = [next(res_file).strip() for _ in range(num_lines)]
        label_lines = [next(lbl_file).strip() for _ in range(num_lines)]

    match_count = sum(1 for res, lbl in zip(result_lines, label_lines) if res == lbl)
    match_percentage = (match_count / num_lines) * 100

    print(f"accuracy: {match_percentage:.2f}%")

compare_files('result.txt', 'label.txt', 50)
