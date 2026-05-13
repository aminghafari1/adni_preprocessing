import json
import sys

def get_phase_encoding(json_path):
    with open(json_path, "r") as f:
        metadata = json.load(f)

    mapping = {
        "i":  "x",
        "i-": "x-",
        "j":  "y",
        "j-": "y-",
        "k":  "z",
        "k-": "z-"
    }

    raw = metadata.get("PhaseEncodingDirection", None)

    if raw is None:
        print("ERROR: PhaseEncodingDirection not found in JSON")
        sys.exit(1)

    direction = mapping.get(raw, None)

    if direction is None:
        print(f"ERROR: Unrecognized PhaseEncodingDirection: {raw}")
        sys.exit(1)

    print(direction)
    return direction

if __name__ == "__main__":
    json_path = sys.argv[1]
    get_phase_encoding(json_path)