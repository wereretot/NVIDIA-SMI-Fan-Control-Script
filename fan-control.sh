#!/bin/bash

# Define the temperature thresholds and corresponding fan speeds
thresholds=(42 43 44 45 46 47 48 49 50 55 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76)  # Adjust the thresholds as desired
fan_speeds=(40 100 110 120 130 149 150 160 170 200 223 255 255)  # Adjust the fan speeds corresponding to each threshold

# Define the temperature threshold when the GPU will pause all programs running on it until it goes below this temperature
# if you don't like this then set the temp to like 99 or something to disable it
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
  sleep 5
done
