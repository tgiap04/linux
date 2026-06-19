#!/usr/bin/env python3
"""
UDP Receiver for Covert Channel.

Listens on a specified port using Scapy, extracts hidden bytes from
IP Identification field, and reassembles messages using the framing protocol.

Framing: 0xFF 0x00 [data bytes] 0xFF 0xFF
Embed location: lower 8 bits of IP Identification field.

Usage:
    sudo python3 udp_receiver.py --port 9999
    sudo python3 udp_receiver.py --port 9999 --verbose
"""

import argparse
import sys

from scapy.all import sniff, UDP, IP

# Framing markers
MARKER_START = bytes([0xFF, 0x00])
MARKER_END = bytes([0xFF, 0xFF])


class UdpCovertReceiver:
    """Receives covert data embedded in IP Identification field."""

    def __init__(self, port: int, verbose: bool = False):
        self.port = port
        self.verbose = verbose
        self.receiving = False
        self.buffer = bytearray()
        self._awaiting_start_second = False
        self._awaiting_end_second = False

    def extract_byte(self, pkt) -> int | None:
        """Extract the hidden byte from IP Identification field."""
        if not pkt.haslayer(UDP) or not pkt.haslayer(IP):
            return None

        # Only process packets to our target port
        if pkt[UDP].dport != self.port:
            return None

        # Extract lower 8 bits of IP ID
        ip_id = pkt[IP].id
        hidden_byte = ip_id & 0xFF
        return hidden_byte

    def process_packet(self, pkt):
        """Process a captured packet and extract covert data."""
        hidden_byte = self.extract_byte(pkt)
        if hidden_byte is None:
            return

        byte_val = hidden_byte

        if self.verbose:
            src_ip = pkt[IP].src
            src_port = pkt[UDP].sport
            print(f"  [PKT] {src_ip}:{src_port} -> id={pkt[IP].id} "
                  f"-> byte=0x{byte_val:02x} ('{chr(byte_val) if 32 <= byte_val < 127 else '?'}')")

        # State machine for framing
        if not self.receiving:
            if byte_val == 0xFF:
                self._awaiting_start_second = True
                return
            if self._awaiting_start_second:
                if byte_val == 0x00:
                    self.receiving = True
                    self.buffer = bytearray()
                    self._awaiting_start_second = False
                    if self.verbose:
                        print("  [START] Begin receiving covert message")
                    return
                self._awaiting_start_second = False
                return
            return

        # Currently receiving
        if byte_val == 0xFF:
            self._awaiting_end_second = True
            return

        if self._awaiting_end_second:
            if byte_val == 0xFF:
                self.receiving = False
                self._awaiting_end_second = False
                self._deliver_message()
                return
            # False alarm
            self.buffer.append(0xFF)
            self.buffer.append(byte_val)
            self._awaiting_end_second = False
            return

        self.buffer.append(byte_val)

    def _deliver_message(self):
        """Deliver the reassembled message."""
        try:
            message = bytes(self.buffer).decode('utf-8', errors='replace')
            print(f"\n{'='*60}")
            print(f"[RECEIVED] {message}")
            print(f"{'='*60}\n")
        except Exception:
            print(f"\n[RECEIVED] (binary, {len(self.buffer)} bytes): "
                  f"{' '.join(f'{b:02x}' for b in self.buffer)}\n")

    def run(self):
        """Start sniffing packets."""
        print(f"[*] UDP Covert Receiver listening on port {self.port}")
        print(f"[*] Extracting hidden bytes from IP Identification field")
        print(f"[*] Framing: 0xFF00 (start) ... 0xFFFF (end)")
        print(f"[*] Verbose: {self.verbose}")
        print(f"[*] Waiting for packets... (Ctrl+C to stop)\n")

        bpf_filter = f"udp port {self.port}"

        try:
            sniff(
                filter=bpf_filter,
                prn=self.process_packet,
                store=0,
            )
        except KeyboardInterrupt:
            print("\n[*] Stopped.")
        except PermissionError:
            print("[!] Need root privileges. Run with sudo.")
            sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="UDP Covert Channel Receiver"
    )
    parser.add_argument(
        "--port", type=int, default=9999,
        help="Port to listen on (default: 9999)"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true",
        help="Show all intercepted packets"
    )
    args = parser.parse_args()

    receiver = UdpCovertReceiver(port=args.port, verbose=args.verbose)
    receiver.run()


if __name__ == "__main__":
    main()
