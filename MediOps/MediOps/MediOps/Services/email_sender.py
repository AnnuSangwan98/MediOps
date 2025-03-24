import sys

if __name__ == '__main__':
    try:
        print("Starting email server on port 8085...")
        app.run(host='0.0.0.0', port=8085, debug=True)
    except Exception as e:
        print(f"Failed to start server: {str(e)}", file=sys.stderr)
        sys.exit(1) 