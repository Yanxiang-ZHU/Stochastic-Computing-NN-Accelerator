def compare_files(result_file, label_file):
    with open(result_file, 'r') as res_file, open(label_file, 'r') as lbl_file:
        result_lines = res_file.readlines()
        label_lines = lbl_file.readlines()

        if len(result_lines) != len(label_lines):
            print("failure")
            return

        total_lines = len(result_lines)
        match_count = 0

        for res_line, lbl_line in zip(result_lines, label_lines):
            if res_line.strip() == lbl_line.strip():
                match_count += 1

        match_percentage = (match_count / total_lines) * 100
        print(f"accuracy: {match_percentage:.2f}%")

compare_files('result.txt', 'label.txt')