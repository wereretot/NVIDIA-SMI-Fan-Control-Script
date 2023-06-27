#!/bin/bash

# Define the temperature thresholds and corresponding fan speeds
thresholds=(40 43 45 47 50 55 60 63 65 67 70 73 75)  # Adjust the thresholds as desired
fan_speeds=(40 48 55 62 70 90 113 126 147 170 200 223 255)  # Adjust the fan speeds corresponding to each threshold

# Define the fan headers
fan_header_3="/sys/class/hwmon/hwmon4/pwm3"
fan_header_4="/sys/class/hwmon/hwmon4/pwm4"

# Define the emergency temperature threshold and maximum fan speed
emergency_threshold=90
emergency_fan_speed=255

# Function to set the fan speed based on the temperature
set_fan_speed() {
  local temperature=$1
  local index=0

  # Find the appropriate fan speed based on the temperature
  while [ $index -lt ${#thresholds[@]} ] && [ $temperature -ge ${thresholds[$index]} ]; do
    index=$((index+1))
  done

  # Set the fan headers to the corresponding fan speed
  sudo bash -c "echo ${fan_speeds[$index]} > $fan_header_3"
  sudo bash -c "echo ${fan_speeds[$index]} > $fan_header_4"
}

# Function to handle emergency mode
emergency_mode() {
  echo "Emergency: Tesla P40 GPU is overheating!"
  echo "Setting fans to maximum speed."

  # Set the fan headers to maximum speed
  sudo bash -c "echo $emergency_fan_speed > $fan_header_3"
  sudo bash -c "echo $emergency_fan_speed > $fan_header_4"

  # Add any additional actions to take in the emergency mode

  # Sleep indefinitely to keep the emergency mode active
  while true; do
    sleep 1
  done
}

# Function to display ASCII elements
display_ascii() {
  echo "+-----------------------------------------------------------+"
  echo "|                  NVIDIA SMI Fan Control                   |"
  echo "+-----------------------------------------------------------+"
}

# Function to update the GPU information
update_gpu_info() {
  # Get the GPU temperature using nvidia-smi
  local temperature=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
  # Get the current fan speed from the fan header
  local fan_speed=$(cat $fan_header_3)
  # Calculate the PWM value based on the current fan speed
  local pwm_value=$((fan_speed * 100 / 255))

  if [ $temperature -ge $emergency_threshold ]; then
    emergency_mode
  else
    set_fan_speed $temperature

    # Print GPU information
    printf "|  GPU Temperature: %s°C\t\t\t\t\t|\n" "$temperature"
    printf "|  Fan Speed: %d%%\t\t\t\t\t\t|\n" "$pwm_value"
    printf "|  PWM Value: %d\t\t\t\t\t\t|\n" "$fan_speed"
  fi
}

# Clear the screen and display the initial ASCII elements
clear
display_ascii

# Continuously update the GPU information
while true; do
  # Move the cursor to the top-left corner
  tput cup 3 0

  # Update the GPU information
  update_gpu_info

  # Move the cursor to the bottom of the output
  tput cup 8 0

  # Wait for some time before updating the information again (in seconds)
  sleep 5
done
