#!/bin/bash

echo "Setting API token..."
export REPLICATE_API_TOKEN=[REPLICATE_API_TOKEN]

echo "Running Python script..."
python codeformer.py

if [ $? -eq 0 ]; then
  echo "Script completed!"
else
  echo "Error occurred! Please check the Python script."
  read -p "Press any key to exit."
fi
