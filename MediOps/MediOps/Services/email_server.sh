#!/bin/bash

# Go to the project directory
cd /Users/aryanshukla/Documents/GitHub/MediOps

# Activate the virtual environment
source email_env/bin/activate

echo "Starting email server..."

# Kill any existing email server processes
pkill -f "python3 MediOps/MediOps/Services/email_sender.py" || true
sleep 1

# Try several ports until one works
for PORT in 8085 8086 8087 8088 8089; do
    echo "Attempting to start server on port $PORT..."
    
    # Update the port in email_sender.py
    sed -i '' "s/port=[0-9]\{4\}/port=$PORT/g" MediOps/MediOps/Services/email_sender.py
    sed -i '' "s/port [0-9]\{4\}/port $PORT/g" MediOps/MediOps/Services/email_sender.py
    
    # Update the port in EmailService.swift
    sed -i '' "s/127.0.0.1:[0-9]\{4\}/127.0.0.1:$PORT/g" MediOps/MediOps/Services/EmailService.swift
    
    # Try starting the server and check if it succeeds
    python3 MediOps/MediOps/Services/email_sender.py > /tmp/email_server_log.txt 2>&1 &
    SERVER_PID=$!
    
    # Wait for the server to start
    sleep 3
    
    # Check if the process is still running
    if kill -0 $SERVER_PID 2>/dev/null; then
        # Check if the port is actually in use by our process
        if lsof -i:$PORT | grep -q python; then
            echo "Email server successfully started on port $PORT (PID: $SERVER_PID)"
            echo "Using port $PORT in EmailService.swift"
            
            # Store the port for the app to use
            echo $PORT > /tmp/email_server_port.txt
            
            # Keep a log of the running server
            echo "$SERVER_PID:$PORT" > /tmp/email_server_status.txt
            
            # Stay in the foreground if called directly
            if [[ $- == *i* ]]; then
                echo "Server running. Press Ctrl+C to stop."
                wait $SERVER_PID
            else
                # Return normally if called in background
                exit 0
            fi
        else
            echo "Server started but not using port $PORT as expected. Stopping."
            kill $SERVER_PID
        fi
    else
        echo "Failed to start on port $PORT, trying next port..."
        cat /tmp/email_server_log.txt
    fi
done

echo "All ports are in use. Could not start email server."
exit 1 