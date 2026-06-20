#!/usr/bin/env bash
# lib/network-mgmt.sh — Socket, network interface, routing, DNS, FD, and firewall management

network_menu() {
    while true; do
        header "Network Management"
        local options=(
            "List listening ports & sockets"
            "Show network interfaces"
            "Show routing table"
            "Test connectivity"
            "DNS lookup"
            "Open file descriptors"
            "Firewall status"
            "Back"
        )
        select opt in "${options[@]}"; do
            case "$REPLY" in
                1) network_list_sockets    ;;
                2) network_show_interfaces ;;
                3) network_show_routes     ;;
                4) network_test_connectivity ;;
                5) network_dns_lookup      ;;
                6) network_list_fds        ;;
                7) network_firewall_status ;;
                8) return                  ;;
                *) warn "Invalid choice"   ;;
            esac
            break
        done
    done
}

network_list_sockets() {
    header "Listening Ports & Sockets"
    if command_exists ss; then
        ss -tulpn | awk 'NR==1{printf "%-6s %-25s %-12s %s\n","Proto","Local Address","State","Process"} NR>1{printf "%-6s %-25s %-12s %s\n",$1,$5,$2,$7}'
    elif command_exists netstat; then
        netstat -tulpn 2>/dev/null | awk 'NR<=2{print} NR>2{printf "%-6s %-25s %-12s %s\n",$1,$4,$6,$7}'
    elif [[ -r /proc/net/tcp ]]; then
        warn "ss/netstat unavailable — parsing /proc/net/tcp (IPv4 only)"
        printf "%-6s %-25s %-12s\n" "Proto" "Local Address" "State"
        local states=([1]=ESTABLISHED [2]=SYN_SENT [3]=SYN_RECV [4]=FIN_WAIT1 [5]=FIN_WAIT2 [6]=TIME_WAIT [7]=CLOSE [8]=CLOSE_WAIT [9]=LAST_ACK [10]=LISTEN [11]=CLOSING)
        while read -r _ local _ _ st _ _ _ _ _ _; do
            [[ "$local" == "local_address" ]] && continue
            local ip hex_port
            ip=$(printf '%d.%d.%d.%d' "0x${local:6:2}" "0x${local:4:2}" "0x${local:2:2}" "0x${local:0:2}" 2>/dev/null)
            hex_port="${local##*:}"
            local port=$((16#${hex_port}))
            local state_num=$((16#${st}))
            printf "%-6s %-25s %-12s\n" "tcp" "${ip}:${port}" "${states[$state_num]:-UNKNOWN}"
        done < /proc/net/tcp
        [[ -r /proc/net/tcp6 ]] && while read -r _ local _ _ st _ _ _ _ _ _; do
            [[ "$local" == "local_address" ]] && continue
            local hex_port="${local##*:}"
            local port=$((16#${hex_port}))
            local state_num=$((16#${st}))
            printf "%-6s %-25s %-12s\n" "tcp6" ":::${port}" "${states[$state_num]:-UNKNOWN}"
        done < /proc/net/tcp6
    else
        warn "No socket listing tool available"
    fi
    press_enter
}

network_show_interfaces() {
    header "Network Interfaces"
    if command_exists ip; then
        ip addr show
    elif command_exists ifconfig; then
        ifconfig 2>/dev/null
    else
        warn "ip/ifconfig unavailable — reading /proc/net"
        [[ -r /proc/net/fib_trie ]] && { info "IPv4 (/proc/net/fib_trie):"; awk '/32 host/{print last} {last=$0}' /proc/net/fib_trie | grep -v "127\." | sort -u; }
        [[ -r /proc/net/if_inet6 ]] && { info "IPv6 (/proc/net/if_inet6):"; awk '{printf "%s:%s:%s:%s:%s:%s:%s:%s dev %s\n",substr($1,1,4),substr($1,5,4),substr($1,9,4),substr($1,13,4),substr($1,17,4),substr($1,21,4),substr($1,25,4),substr($1,29,4),$6}' /proc/net/if_inet6; }
    fi
    press_enter
}

network_show_routes() {
    header "Routing Table"
    if command_exists ip; then
        ip route show | awk '/^default/{printf "\033[1;33m%s\033[0m\n",$0; next} {print}'
    elif command_exists route; then
        route -n 2>/dev/null | awk 'NR<=2{print} NR>2 && /^0\.0\.0\.0/{printf "\033[1;33m%s\033[0m\n",$0; next} NR>2{print}'
    else
        warn "ip/route unavailable"
    fi
    press_enter
}

network_test_connectivity() {
    header "Connectivity Test"
    local host port
    read -r -p "Host or IP to test: " host
    [[ -z "$host" ]] && warn "No host provided" && press_enter && return

    info "Step 1: ICMP ping (3 packets)..."
    if ping -c 3 -W 2 "$host" &>/dev/null; then
        success "Ping to $host succeeded"
    else
        warn "Ping to $host failed — ICMP may be blocked by firewall; host may still be reachable via TCP"
    fi

    read -r -p "TCP port to probe [80]: " port
    port="${port:-80}"
    info "Step 2: TCP probe to $host:$port..."
    local tcp_ok=false
    if command_exists nc; then
        nc -zw3 "$host" "$port" 2>/dev/null && tcp_ok=true
    else
        # Use subshell redirect — avoids bash -c string injection
        ( exec 3>/dev/tcp/"$host"/"$port" ) 2>/dev/null && tcp_ok=true
    fi

    if $tcp_ok; then
        success "TCP connection to $host:$port succeeded"
    else
        warn "TCP connection to $host:$port failed"
    fi
    press_enter
}

network_dns_lookup() {
    header "DNS Lookup"
    local target result
    read -r -p "Hostname or IP for lookup: " target
    [[ -z "$target" ]] && warn "No input provided" && press_enter && return

    # Detect IP for reverse lookup
    local is_ip=false
    [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || "$target" =~ ^[0-9a-fA-F:]+$ ]] && is_ip=true

    if command_exists dig; then
        $is_ip && result=$(dig +short -x "$target" 2>/dev/null) || result=$(dig +short "$target" 2>/dev/null)
    elif command_exists host; then
        result=$(host "$target" 2>/dev/null)
    elif command_exists nslookup; then
        result=$(nslookup "$target" 2>/dev/null)
    else
        result=$(getent hosts "$target" 2>/dev/null)
    fi

    if [[ -n "$result" ]]; then
        info "Result for $target:"
        echo "$result"
    else
        warn "No DNS result found for $target"
    fi
    press_enter
}

network_list_fds() {
    header "Open File Descriptors"
    local input pid
    read -r -p "PID or process name: " input
    [[ -z "$input" ]] && warn "No input provided" && press_enter && return

    if [[ "$input" =~ ^[0-9]+$ ]]; then
        pid="$input"
    elif command_exists pgrep; then
        pid=$(pgrep -n "$input" 2>/dev/null)
        [[ -z "$pid" ]] && warn "No process found matching: $input" && press_enter && return
        info "Resolved '$input' to PID $pid"
    else
        warn "pgrep unavailable — please enter a numeric PID"
        press_enter; return
    fi

    if [[ ! -d "/proc/$pid" ]]; then
        warn "PID $pid not found in /proc"
        press_enter; return
    fi

    if command_exists lsof; then
        lsof -p "$pid" 2>/dev/null
    else
        info "lsof unavailable — listing /proc/$pid/fd/:"
        ls -la "/proc/$pid/fd/" 2>/dev/null || warn "Cannot read /proc/$pid/fd/ — may need elevated privileges"
    fi
    press_enter
}

network_firewall_status() {
    header "Firewall Status"
    info "Native iptables/ufw/firewalld status has moved to the Kernel Firewall module."
    info "Select 'Kernel Firewall' (option 7) from the main menu to manage the ubuntu_firewall module."
    press_enter
}
