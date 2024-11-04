__all__: list[str] = [
    "connect_and_send",
    "read_commands_from_file",
    "send_from_file",
]

import argparse
import asyncio
import logging
import telnetlib3


read_limit: int = 1024
logger = logging.getLogger(__name__)


async def connect_and_send(
    host: str,
    console_port: int,
    commands: list[str],
) -> None:
    async def send(command: str, excess_response: str) -> str:
        writer.write(f"{command}\r\n")
        await writer.drain()

        response: str = excess_response
        for ch in command:
            index = response.find(ch)
            while index == -1:
                response = response + await reader.read(read_limit)
                index = response.find(ch)
            assert index != -1
            response = response[index + 1 :]

        logger.info(f"write: {command}")

        return response

    reader, writer = await telnetlib3.open_connection(host=host, port=console_port)

    excess_response: str = ""
    for command in commands:
        excess_response = await send(command, excess_response)

    reader.close()
    writer.close()


def read_commands_from_file(filename: str) -> list[str]:
    result: list[str] = []
    try:
        with open(filename, "r") as file:
            result = [line.strip() for line in file]
    except FileNotFoundError:
        print(f"File {filename} not found.")
    except Exception as e:
        print(e)
    return result


def send_from_file(filename: str, host: str, console_port: int) -> None:
    commands = read_commands_from_file(filename)
    asyncio.run(connect_and_send(host, console_port, commands))
    return


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Telnet client to send commands.")
    parser.add_argument(
        "console_port",
        type=int,
        help="Console port to connect to.",
    )
    parser.add_argument(
        "filename",
        type=str,
        help="Filename containing commands to send.",
    )
    parser.add_argument(
        "log_file",
        type=str,
        help="Filename to write log to.",
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        filename=args.log_file,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )

    commands = read_commands_from_file(args.filename)

    asyncio.run(connect_and_send("localhost", args.console_port, commands))
