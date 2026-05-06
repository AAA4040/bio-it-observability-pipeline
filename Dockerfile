# Alpine Linux is only ~5MB, which is perfect for student projects
FROM alpine:3.19

LABEL maintainer="Azhar Afef"
LABEL description="Medical Log Monitor for Bio-IT Pipeline"

# Combine commands and clean cache to keep the image small
RUN apk add --no-cache bash

# Set the working directory inside the container
WORKDIR /app

# Copy the script and set execution permissions in separate steps
COPY monitor.sh .
RUN chmod +x monitor.sh

# CMD allows the container to receive stop signals (SIGTERM) properly
CMD ["/bin/bash", "./monitor.sh"]