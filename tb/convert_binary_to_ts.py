def convert_binary_to_ts(input_filename, output_filename):
    try:
        with open(input_filename, 'r', encoding='utf-8') as infile:
            binary_strings = [line.strip() for line in infile if line.strip()]

        byte_data = bytearray()
        for b_str in binary_strings:
            if len(b_str) == 8 and all(c in '01' for c in b_str):
                byte_data.append(int(b_str, 2))
            else:
                print(f"Invalid binary string '{b_str}'.")
                continue

        with open(output_filename, 'wb') as outfile:
            outfile.write(byte_data)

        print(f"Data from '{input_filename}' written to '{output_filename}'.")

    except FileNotFoundError:
        print(f"Error: The input file '{input_filename}' does not exist.")
    except Exception as e:
        print(f"An error occurred: {e}")

input_file = 'rdata_out1.txt'
output_file = 'output.ts'

if __name__ == "__main__":
    convert_binary_to_ts(input_file, output_file)