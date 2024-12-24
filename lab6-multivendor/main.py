"""
Generate router configuration
"""

import json
import os

TEMPLATE_PATH = "template"
OUTPUT_PATH = "output"

if __name__ == "__main__":
    with open(
        file="config.json",
        mode="r",
        encoding="utf-8",
    ) as f:
        config = json.load(fp=f)

    for index, info in config.items():
        router_id = int(index)
        print(f"router_id: {router_id}, info: {info}")
        template_name = info["template"]
        with open(
            file=f"{TEMPLATE_PATH}/{template_name}.txt",
            mode="r",
            encoding="utf-8",
        ) as f:
            template: list[str] = f.read().splitlines()

        commands: list[str] = template

        commands = [line.strip() for line in commands]
        commands = [line for line in commands if not line.startswith("#") and len(line)]
        commands = [line.replace("<router_id>", str(router_id)) for line in commands]
        commands = [
            line.replace("<interface_0>", info["interface_0"]) for line in commands
        ]
        commands = [
            line.replace("<interface_1>", info["interface_1"]) for line in commands
        ]

        os.makedirs(f"{OUTPUT_PATH}", exist_ok=True)
        with open(
            file=f"{OUTPUT_PATH}/configuration_{router_id}.txt",
            mode="w",
            encoding="utf-8",
        ) as f:
            for command in commands:
                f.write(f"{command}\n")
