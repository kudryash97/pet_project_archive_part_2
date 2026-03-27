  #!/bin/bash
  CONFIG_FILE="/data/master/gpsne-1/postgresql.conf"

  # Check if production logging settings already exist
  if ! grep -q "# Production logging configuration" "$CONFIG_FILE" 2>/dev/null; then
      echo "Configuring production logging settings..."
      echo "" >> "$CONFIG_FILE"
      echo "# Production logging configuration" >> "$CONFIG_FILE"
      echo "log_destination = 'csvlog'" >> "$CONFIG_FILE"
      echo "logging_collector = on" >> "$CONFIG_FILE"
      echo "log_filename = 'postgresql-%H.csv'" >> "$CONFIG_FILE"
      echo "log_rotation_age = 1h" >> "$CONFIG_FILE"
      echo "log_truncate_on_rotation = on" >> "$CONFIG_FILE"
      echo "" >> "$CONFIG_FILE"
      echo "# Log verbosity (production-optimized)" >> "$CONFIG_FILE"
      echo "log_min_messages = warning" >> "$CONFIG_FILE"
      echo "log_statement = 'none'" >> "$CONFIG_FILE"
      echo "client_min_messages = notice" >> "$CONFIG_FILE"
      echo "" >> "$CONFIG_FILE"
      echo "# Connection auditing" >> "$CONFIG_FILE"
      echo "log_connections = on" >> "$CONFIG_FILE"
      echo "log_disconnections = on" >> "$CONFIG_FILE"
      echo "log_duration = off" >> "$CONFIG_FILE"
      echo "" >> "$CONFIG_FILE"
      echo "# Performance monitoring" >> "$CONFIG_FILE"
      echo "log_min_duration_statement = 5000" >> "$CONFIG_FILE"
      echo "Production logging configured."
  else
      echo "Production logging already configured."
  fi