import os
import random
import time

INPUT_FILE = "tsdata.ts"

OUTPUT_FILE1 = "tsdata1_loss.ts"
OUTPUT_FILE2 = "tsdata2_loss.ts"
OUTPUT_FILE3 = "tsdata3_loss.ts"
OUTPUT_FILE4 = "tsdata4_loss.ts"

PACKET_SIZE = 188

def read_ts_packets(filepath : str):
    with open(filepath, "rb") as fh:
        data = fh.read()
    packets = [data[i:i+PACKET_SIZE] for i in range(0, len(data), PACKET_SIZE)]
    return packets

def write_ts_packets(filepath : str, packets):
    with open(filepath, "wb") as fh:
        for packet in packets:
            fh.write(packet)

# simulate uniformly random loss
def simulate_loss(packets, num_to_remove):
    random.seed(time.time())

    packets_length = len(packets)
    print("packets_length: ", packets_length)

    if num_to_remove > packets_length:
        raise ValueError("Error: trying to delete more packets than the total available.")

    indexes_to_remove = sorted(random.sample(range(packets_length), num_to_remove), reverse=True)

    print("Indexes to be removed: ", indexes_to_remove)

    for index in indexes_to_remove:
        del packets[index]

    return packets

def main():
    base_dir = os.path.dirname(os.path.realpath(__file__))
    file_path = os.path.join(base_dir, INPUT_FILE)
    file_path_out = os.path.join(base_dir, OUTPUT_FILE1)

    print("file_path: ", file_path)
    if not os.path.exists(file_path):
        print(f"File not found {file_path}")
        return
    
    packets = read_ts_packets(filepath=file_path)
    modified_packets = simulate_loss(packets, 920)

    write_ts_packets(file_path_out, modified_packets)

if __name__ == "__main__":
    main()
