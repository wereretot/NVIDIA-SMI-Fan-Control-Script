#!/bin/bash

# Define the minimum and maximum temperatures and corresponding fan speeds
min_temp=44
max_temp=54
min_speed=50
max_speed=255

# Define the temperature threshold when the GPU will pause all programs running on it until it goes below this temperature
pause_threshold=73

# Define the emergency temperature threshold and maximum fan speed
emergency_threshold=85
emergency_fan_speed=255

# Define the fan headers
fan_header_3="/sys/class/hwmon/hwmon4/pwm3"
fan_header_4="/sys/class/hwmon/hwmon4/pwm4"

# Function to set the fan speed based on the temperature
set_fan_speed() {
  local temperature=$1

  # Calculate the fan speed using a linear relationship
  local fan_speed=$((min_speed + (max_speed - min_speed) * (temperature - min_temp) / (max_temp - min_temp)))

  # Set the fan headers to the calculated fan speed
  sudo bash -c "echo $fan_speed > $fan_header_3"
  sudo bash -c "echo $fan_speed > $fan_header_4"
}

# Function to handle emergency mode
emergency_mode() {
  echo "Emergency: GPU is overheating!"
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
  echo "|               NVIDIA SMI BASED Fan Control                |"
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

  if [ "$temperature" -gt $pause_threshold ]
  then
      echo "Tasks are paused until the GPU cools down enough."
      nvidia-smi --query-compute-apps=pid --format=csv,noheader | xargs -I{} kill -STOP {}
  else
      nvidia-smi --query-compute-apps=pid --format=csv,noheader | xargs -I{} kill -CONT {}
  fi


  if [ $temperature -ge $emergency_threshold ]; then
    emergency_mode
  else
    set_fan_speed $temperature

    # Print GPU information
    printf " |  GPU Temperature:\t%s°C\t\t\t\t   |\n" "$temperature"
    printf " |  Fan Speed:\t\t%d%%  \t\t\t\t   |\n" "$pwm_value"
    printf " |  PWM Value Output:\t%d / 255  \t\t\t   |\n" "$fan_speed"
    echo "+-----------------------------------------------------------+"
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
  sleep 1
done
