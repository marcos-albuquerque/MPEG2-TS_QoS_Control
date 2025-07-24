import os
import random
import time

INPUT_FILE = "tsdata.ts"

OUTPUT_FILE1 = R"C:\Users\marco\Documents\tsdata1_loss.ts"
OUTPUT_FILE2 = R"C:\Users\marco\Documents\tsdata2_loss.ts"
OUTPUT_FILE3 = R"C:\Users\marco\Documents\tsdata3_loss.ts"
OUTPUT_FILE4 = R"C:\Users\marco\Documents\tsdata4_loss.ts"

PACKET_SIZE = 188
CHUNK_SIZE = 190

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
def simulate_loss(packets, num_to_remove, ch):
    random.seed(time.time())

    chunks = [packets[i:i+CHUNK_SIZE] for i in range(0, len(packets), CHUNK_SIZE)]
    chunk_length = len(chunks[0])
    print("chunk_length: ", chunk_length)
    
    if num_to_remove > chunk_length:
        raise ValueError("Error: trying to delete more packets than the total available.")

    match ch:
        case 1:
            pl_ch_idx = [i for i in range(len(chunks)) if i % 5 != 0]
        case 2:
            pl_ch_idx = [i for i in range(len(chunks)) if (i-1) % 5 != 0]
        case 3:
            pl_ch_idx = [i for i in range(len(chunks)) if (i-2) % 5 != 0]
        case 4:
            pl_ch_idx = [i for i in range(len(chunks)) if (i-3) % 5 != 0]

    print("pl_ch1_idx: ", pl_ch_idx)

    print("chunks lenght", len(chunks))
    # print(chunks[94][829])
    
    indexes_to_remove = sorted(random.sample(range(len(chunks[0])), num_to_remove), reverse=True)

    for i in pl_ch_idx:
        for index in indexes_to_remove:
            del chunks[i][index]

    print("Indexes to be removed: ", indexes_to_remove)
    rebuilt_packets = [packet for chunk in chunks for packet in chunk]

    return rebuilt_packets

def main():
    base_dir = os.path.dirname(os.path.realpath(__file__))
    file_path = os.path.join(base_dir, INPUT_FILE)
    file_path_out = os.path.join(base_dir, OUTPUT_FILE4)

    print("file_path: ", file_path)
    if not os.path.exists(file_path):
        print(f"File not found {file_path}")
        return
    
    packets = read_ts_packets(filepath=file_path)
    modified_packets = simulate_loss(packets, 100, ch=4)

    write_ts_packets(file_path_out, modified_packets)

if __name__ == "__main__":
    main()
