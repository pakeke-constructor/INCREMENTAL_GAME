import argparse


def extract_version(verstr: str):
    version = verstr.split(".")
    return int(version[0]), int(version[1]), int(version[2])


def main():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("version", type=extract_version)
    parser.add_argument("input")
    parser.add_argument("output")
    args = parser.parse_args()

    version: tuple[int, int, int] = args.version
    major, minor, patch = version

    with open(args.input, "r", encoding="utf-8", newline="") as f:
        with open(args.output, "w", encoding="utf-8", newline="\r\n") as f2:
            f2.write(f.read() % {"major": major, "minor": minor, "patch": patch})


if __name__ == "__main__":
    main()
