#!/usr/bin/env python3
"""
TCP Receiver for Covert Channel.

Listens on a specified port using Scapy, extracts hidden bytes from
TCP sequence numbers, and reassembles messages using the framing protocol.

Framing: 0xFF 0x00 [data bytes] 0xFF 0xFF
Embed location: lower 8 bits of TCP sequence number.

Usage:
    sudo python3 tcp_receiver.py --port 9999
    sudo python3 tcp_receiver.py --port 9999 --verbose
"""

import argparse
import sys

from scapy.all import sniff, TCP, IP

# Framing markers
MARKER_START = bytes([0xFF, 0x00])
MARKER_END = bytes([0xFF, 0xFF])


class TcpCovertReceiver:
    """Receives covert data embedded in TCP sequence numbers."""

    def __init__(self, port: int, verbose: bool = False):
        self.port = port
        self.verbose = verbose
        self.receiving = False
        self.buffer = bytearray()

    def extract_byte(self, pkt) -> int | None:
        """Extract the hidden byte from TCP sequence number."""
        if not pkt.haslayer(TCP) or not pkt.haslayer(IP):
            return None

        # Only process packets to our target port
        if pkt[TCP].dport != self.port:
            return None

        # Extract lower 8 bits of sequence number
        seq = pkt[TCP].seq
        hidden_byte = seq & 0xFF
        return hidden_byte

    def process_packet(self, pkt):
        """Process a captured packet and extract covert data."""
        hidden_byte = self.extract_byte(pkt)
        if hidden_byte is None:
            return

        byte_val = hidden_byte

        if self.verbose:
            src_ip = pkt[IP].src
            src_port = pkt[TCP].sport
            print(f"  [PKT] {src_ip}:{src_port} -> seq={pkt[TCP].seq} "
                  f"-> byte=0x{byte_val:02x} ('{chr(byte_val) if 32 <= byte_val < 127 else '?'}')")

        # Check for start marker (0xFF, 0x00)
        if not self.receiving:
            if byte_val == 0xFF:
                # Potential start marker — next byte should be 0x00
                self.buffer = bytearray()
                # Peek at next packet will be handled by state machine
                self._awaiting_start_second = True
                return
            if hasattr(self, '_awaiting_start_second') and self._awaiting_start_second:
                if byte_val == 0x00:
                    self.receiving = True
                    self.buffer = bytearray()
                    self._awaiting_start_second = False
                    if self.verbose:
                        print("  [START] Begin receiving covert message")
                    return
                else:
                    self._awaiting_start_second = False
                    return
            return

        # Currently receiving — check for end marker
        if byte_val == 0xFF:
            self._awaiting_end_second = True
            return

        if hasattr(self, '_awaiting_end_second') and self._awaiting_end_second:
            if byte_val == 0xFF:
                # End marker received
                self.receiving = False
                self._awaiting_end_second = False
                self._deliver_message()
                return
            else:
                # False alarm — append the buffered 0xFF and this byte
                self.buffer.append(0xFF)
                self.buffer.append(byte_val)
                self._awaiting_end_second = False
                return

        # Regular data byte
        self.buffer.append(byte_val)

    def _deliver_message(self):
        """Deliver the reassembled message."""
        try:
            message = bytes(self.buffer).decode('utf-8', errors='replace')
            print(f"\n{'='*60}")
            print(f"[RECEIVED] {message}")
            print(f"{'='*60}\n")
        except Exception as e:
            print(f"\n[RECEIVED] (binary, {len(self.buffer)} bytes): "
                  f"{' '.join(f'{b:02x}' for b in self.buffer)}\n")

    def run(self):
        """Start sniffing packets."""
        print(f"[*] TCP Covert Receiver listening on port {self.port}")
        print(f"[*] Extracting hidden bytes from TCP sequence numbers")
        print(f"[*] Framing: 0xFF00 (start) ... 0xFFFF (end)")
        print(f"[*] Verbose: {self.verbose}")
        print(f"[*] Waiting for packets... (Ctrl+C to stop)\n")

        bpf_filter = f"tcp port {self.port}"

        try:
            sniff(
                filter=bpf_filter,
                prn=self.process_packet,
                store=0,  # Don't store packets in memory
            )
        except KeyboardInterrupt:
            print("\n[*] Stopped.")
        except PermissionError:
            print("[!] Need root privileges. Run with sudo.")
            sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="TCP Covert Channel Receiver"
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

    receiver = TcpCovertReceiver(port=args.port, verbose=args.verbose)
    receiver.run()


if __name__ == "__main__":
    main()
