#!/bin/bash

ip="10.13.27.14"
attempts=20
response="64 bytes from $ip"

for (( attempt=1; attempt<=$attempts; attempt++ )); do
  pingResponse=$(ping -c 4 "$ip")  # Capture the entire ping response
  echo "Checking VPN connection attempt $attempt..."
  echo "$pingResponse"  # Print the captured response

  if [[ $pingResponse == *"$response"* ]]; then  # Check for presence of IP
    echo "OpenVPN ping responded as expected."
    break
  fi

  echo "VPN not responding. Restarting OpenVPN with attempt $attempt..."
  killall -w openvpn
  openvpn --config /etc/openvpn/client.ovpn &
  sleep 10
done