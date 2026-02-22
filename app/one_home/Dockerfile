# Use a Python base image
FROM python:3.9-slim-buster

# Set the working directory in the container
WORKDIR /app

# Copy the requirements directory from the repo root
COPY requirements/ ./requirements/

# Copy the specific requirements.txt from its subfolder
COPY app/one_home/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy your FastAPI application code from its subfolder
COPY app/one_home/ .

# Expose the port
EXPOSE 8000

# Command to run your application
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]