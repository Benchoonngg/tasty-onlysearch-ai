# Use an official Python base image with build tools
FROM python:3.10-slim

# Install system dependencies for face_recognition (requires dlib + cmake + libboost)
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        cmake \
        libboost-all-dev \
        libopenblas-dev \
        liblapack-dev \
        libx11-dev \
        libgtk-3-dev \
        libglib2.0-0 \
        wget \
        git \
        curl \
        libssl-dev \
        libffi-dev \
        && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /app

# Copy the requirements file first
COPY requirements.txt .

# Install Python dependencies
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Install dlib explicitly (required by face_recognition)
RUN pip install dlib
RUN mkdir -p /app/models/gpt2

# Install transformers and download/save gpt-2 model
RUN pip install transformers && \
    python -c "from transformers import AutoModelForCausalLM, AutoTokenizer; \
model_name = 'gpt2'; \
model = AutoModelForCausalLM.from_pretrained(model_name); \
tokenizer = AutoTokenizer.from_pretrained(model_name); \
model.save_pretrained('/app/models/gpt2'); \
tokenizer.save_pretrained('/app/models/gpt2')"

# Copy the rest of the app
COPY . .

# Expose the app port (Cloud Run expects the app to gitlisten on port 8080)
EXPOSE 8080

# Run the app (Flask's default behavior is to bind to 0.0.0.0, which is needed for Cloud Run)
CMD ["python", "app.py"]
